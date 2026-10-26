// Stav aplikace v Apple Watch a komunikace s telefonem – obdoba
// wear/lib/watch_controller.dart (Wear OS). Telefon je jediný zdroj
// pravdy: posílá stav tréninku a provádí příkazy, hodinky zobrazují
// a úpravy +/- ukážou hned (dočasně, dokud nepřijde stav z telefonu).
import Foundation
import WatchConnectivity
import WatchKit

enum WatchPhase {
  case connecting, unreachable, idle, openOnPhone, active, premiumRequired
}

final class WatchController: NSObject, ObservableObject, WCSessionDelegate {
  let strings = WatchStrings.current()

  @Published private(set) var state: WearState?
  @Published private(set) var unreachable = false
  @Published private(set) var notice: String?
  @Published private(set) var heartRate: Int?
  @Published private(set) var restEnd: Date?
  @Published private(set) var pendingCommands: Set<String> = []
  @Published var showList = false

  private var restTotal = 0
  private var restAlerted = false
  private var boot: Int?
  private var seq = 0
  private var lastStateAt: Date?
  private var nextId = 1
  private var pending: [Int: (name: String, timer: Timer)] = [:]
  private var edit: (key: String, weightKg: Double?, value: Int?, at: Date)?
  private var heartbeat: Timer?
  private var restTicker: Timer?
  private var noticeTimer: Timer?
  private var heartRateSentAt: Date?
  private let monitor = HeartRateMonitor()

  override init() {
    super.init()
    monitor.onHeartRate = { [weak self] bpm in self?.onHeartRate(bpm) }
  }

  // MARK: Stav pro UI

  var phase: WatchPhase {
    guard let s = state else { return unreachable ? .unreachable : .connecting }
    if unreachable { return .unreachable }
    switch s.phase {
    case .idle: return .idle
    case .openOnPhone: return .openOnPhone
    case .active: return .active
    case .premiumRequired: return .premiumRequired
    }
  }

  var current: WearCurrentSet? { state?.current }

  func isPending(_ name: String) -> Bool { pendingCommands.contains(name) }

  private func key(_ c: WearCurrentSet) -> String {
    "\(state?.sessionId ?? -1):\(c.blockIndex):\(c.exerciseId):\(c.setIndex)"
  }

  func weightKg(of c: WearCurrentSet) -> Double? {
    if let e = edit, e.key == key(c) { return e.weightKg }
    return c.weightKg
  }

  func value(of c: WearCurrentSet) -> Int? {
    if let e = edit, e.key == key(c) { return e.value }
    return c.value
  }

  var restRemaining: TimeInterval {
    guard let end = restEnd else { return 0 }
    return max(0, end.timeIntervalSinceNow)
  }

  var restProgress: Double {
    guard restEnd != nil, restTotal > 0 else { return 0 }
    return min(1, max(0, restRemaining / Double(restTotal)))
  }

  func displayWeight(_ kg: Double?) -> Double? {
    guard let kg, let s = state, s.kgPerUnit > 0 else { return nil }
    return (kg / s.kgPerUnit * 100).rounded() / 100
  }

  /// 82.5 → „82,5“ (desetinná čárka), 80.0 → „80“.
  func format(_ v: Double) -> String {
    let rounded = (v * 100).rounded() / 100
    let text = rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    return strings.decimalComma ? text.replacingOccurrences(of: ".", with: ",") : text
  }

  /// „60 × 10“, „10 ×“, „30 s“.
  func describe(weightKg: Double?, value: Int?, isDuration: Bool) -> String {
    guard let value else { return "–" }
    if isDuration { return "\(value) \(strings.seconds)" }
    guard let w = displayWeight(weightKg) else { return "\(value) ×" }
    return "\(format(w)) × \(value)"
  }

  // MARK: Start

  func start() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
    heartbeat?.invalidate()
    heartbeat = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
      self?.hello()
    }
  }

  /// „hello“ – telefon odpoví stavem; bez odpovědi do 5 s je nedostupný.
  func hello() {
    send(["t": "hello"])
    let stale = lastStateAt.map { Date().timeIntervalSince($0) > 50 } ?? true
    guard stale else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
      guard let self else { return }
      let stillStale = self.lastStateAt.map { Date().timeIntervalSince($0) > 50 } ?? true
      if stillStale { self.unreachable = true }
    }
  }

  func retry() {
    unreachable = false
    lastStateAt = nil
    hello()
  }

  private func send(_ payload: [String: Any]) {
    let session = WCSession.default
    guard session.activationState == .activated, session.isReachable else { return }
    session.sendMessage(wearEnvelope(payload), replyHandler: nil, errorHandler: nil)
  }

  // MARK: WCSessionDelegate

  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    DispatchQueue.main.async { [weak self] in self?.hello() }
  }

  func sessionReachabilityDidChange(_ session: WCSession) {
    DispatchQueue.main.async { [weak self] in
      if session.isReachable { self?.hello() }
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    DispatchQueue.main.async { [weak self] in self?.receive(message) }
  }

  private func receive(_ message: [String: Any]) {
    guard let msg = openWearEnvelope(message) else { return }
    switch msg["t"] as? String {
    case "state": onState(msg)
    case "ack": onAck(msg)
    case "ping": send(["t": "hello"])
    default: break
    }
  }

  private func onState(_ msg: [String: Any]) {
    guard let newState = WearState(msg["state"]) else { return }
    if let b = (msg["boot"] as? NSNumber)?.intValue, let s = (msg["seq"] as? NSNumber)?.intValue {
      if b == boot && s <= seq { return }
      boot = b
      seq = s
    }
    let now = Date()
    lastStateAt = now
    unreachable = false
    if newState.sessionId != state?.sessionId || newState.phase != .active { showList = false }
    state = newState
    if let e = edit, let c = newState.current {
      if e.key != key(c) || now.timeIntervalSince(e.at) > 2.5 { edit = nil }
    } else {
      edit = nil
    }
    updateRest(newState, sentAtMs: (msg["sentAtMs"] as? NSNumber)?.intValue, now: now)
    syncHeartRate()
  }

  private func updateRest(_ s: WearState, sentAtMs: Int?, now: Date) {
    if let endMs = s.restEndsAtMs, s.phase == .active {
      let sent = sentAtMs ?? Int(now.timeIntervalSince1970 * 1000)
      let end = now.addingTimeInterval(Double(endMs - sent) / 1000)
      if restEnd == nil || abs(restEnd!.timeIntervalSince(end)) > 1.5 {
        restEnd = end
        restAlerted = false
      }
      restTotal = s.restTotalSeconds
      if restTicker == nil {
        restTicker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
          self?.tickRest()
        }
      }
      return
    }
    if let old = restEnd {
      // Pauza skončila v čase konce a hodinky ještě nezavibrovaly.
      if !restAlerted && now >= old.addingTimeInterval(-2) {
        WKInterfaceDevice.current().play(.notification)
      }
      stopRest()
    }
  }

  private func tickRest() {
    guard let end = restEnd else { return }
    objectWillChange.send()
    if !restAlerted && Date() >= end {
      restAlerted = true
      WKInterfaceDevice.current().play(.notification)
    }
  }

  private func stopRest() {
    restEnd = nil
    restTicker?.invalidate()
    restTicker = nil
  }

  private func onAck(_ msg: [String: Any]) {
    guard let id = (msg["id"] as? NSNumber)?.intValue, let p = pending.removeValue(forKey: id)
    else { return }
    p.timer.invalidate()
    pendingCommands = Set(pending.values.map(\.name))
    if msg["ok"] as? Bool != true {
      showNotice(reasonText(msg["reason"] as? String))
      if p.name == "completeSet" { WKInterfaceDevice.current().play(.failure) }
    } else if p.name == "completeSet" {
      WKInterfaceDevice.current().play(.success)
    } else if p.name == "finishWorkout" {
      showNotice(strings.confirmOnPhone)
    }
  }

  private func reasonText(_ reason: String?) -> String {
    switch reason {
    case "noWorkout": return strings.noWorkout
    case "notOpen": return strings.openWorkoutOnPhone
    case "phoneLocked": return strings.unlockPhone
    case "notFound": return strings.notFound
    case "invalid": return strings.weightMissing
    case "allDone": return strings.allDone
    case "confirmOnPhone": return strings.confirmOnPhone
    case "unsupported": return strings.updateApps
    case "premiumRequired": return strings.premiumRequired
    default: return strings.somethingWrong
    }
  }

  private func showNotice(_ text: String) {
    notice = text
    noticeTimer?.invalidate()
    noticeTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { [weak self] _ in
      self?.notice = nil
    }
  }

  // MARK: Příkazy

  private func command(_ c: WearCommand) {
    let id = nextId
    nextId += 1
    let timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
      guard let self, self.pending.removeValue(forKey: id) != nil else { return }
      self.pendingCommands = Set(self.pending.values.map(\.name))
      self.showNotice(self.strings.notResponding)
    }
    pending[id] = (c.name, timer)
    pendingCommands = Set(pending.values.map(\.name))
    send(c.json(id: id))
  }

  func adjustWeight(_ c: WearCurrentSet, up: Bool) {
    guard let s = state else { return }
    let stepKg = s.weightStep * s.kgPerUnit
    let base = weightKg(of: c) ?? 0
    let next = max(0, base + (up ? stepKg : -stepKg))
    edit = (key(c), next, value(of: c), Date())
    objectWillChange.send()
    command(.adjustWeight(blockIndex: c.blockIndex, exerciseId: c.exerciseId,
                          setIndex: c.setIndex, delta: up ? 1 : -1))
  }

  func adjustValue(_ c: WearCurrentSet, up: Bool) {
    let step = c.isDuration ? 5 : 1
    let next = min(3600, max(1, (value(of: c) ?? 0) + (up ? step : -step)))
    edit = (key(c), weightKg(of: c), next, Date())
    objectWillChange.send()
    command(.adjustReps(blockIndex: c.blockIndex, exerciseId: c.exerciseId,
                        setIndex: c.setIndex, delta: up ? 1 : -1))
  }

  func completeSet(_ c: WearCurrentSet) {
    guard let v = value(of: c) else { return }
    command(.completeSet(blockIndex: c.blockIndex, exerciseId: c.exerciseId,
                         setIndex: c.setIndex, weightKg: weightKg(of: c), value: v))
  }

  func skipRest() { command(.skipRest) }
  func nextExercise() { command(.nextExercise) }
  func finishWorkout() { command(.finishWorkout) }
  func openWorkout() { command(.openWorkout) }

  func select(_ e: WearExerciseItem) {
    showList = false
    command(.selectExercise(blockIndex: e.blockIndex, exerciseId: e.exerciseId))
  }

  // MARK: Tep

  /// Měření tepu jen během tréninku (šetří baterii).
  private func syncHeartRate() {
    if phase == .active {
      if !monitor.isRunning { monitor.start() }
    } else if monitor.isRunning {
      monitor.stop()
      heartRate = nil
    }
  }

  private func onHeartRate(_ bpm: Int) {
    heartRate = bpm
    let now = Date()
    if heartRateSentAt.map({ now.timeIntervalSince($0) >= 5 }) ?? true {
      heartRateSentAt = now
      send(["t": "hr", "bpm": bpm])
    }
  }
}
