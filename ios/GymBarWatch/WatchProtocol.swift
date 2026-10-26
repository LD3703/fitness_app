// Protokol mezi telefonem a hodinkami – stejný jako u Wear OS
// (lib/modules/wear/wear_protocol.dart). Zprávy jdou přes WCSession
// (v telefonu balíček watch_connectivity): slovník s jediným klíčem
// „fitnessWear“ a hodnotou JSON textu.
//
// Telefon → hodinky: {t: state, boot, seq, sentAtMs, state}, {t: ack, id,
// ok, reason}, {t: ping}. Hodinky → telefon: {t: hello}, {t: cmd, id, cmd,
// …}, {t: hr, bpm}.
import Foundation

let kWearMessageKey = "fitnessWear"
let kWearProtocolVersion = 1

/// Zabalí zprávu pro WCSession.
func wearEnvelope(_ payload: [String: Any]) -> [String: Any] {
  var body = payload
  body["v"] = kWearProtocolVersion
  guard let data = try? JSONSerialization.data(withJSONObject: body),
        let text = String(data: data, encoding: .utf8)
  else { return [:] }
  return [kWearMessageKey: text]
}

/// Rozbalí přijatou zprávu; nil, pokud nepatří této aplikaci.
func openWearEnvelope(_ message: [String: Any]) -> [String: Any]? {
  guard let text = message[kWearMessageKey] as? String,
        let data = text.data(using: .utf8),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else { return nil }
  return json
}

private func int(_ v: Any?) -> Int? { (v as? NSNumber)?.intValue }
private func double(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }

enum WearPhase: String {
  case idle, openOnPhone, active, premiumRequired
}

enum WearSetKind: String {
  case working, warmup, drop
}

/// Série, která je na řadě (WearCurrentSet).
struct WearCurrentSet: Equatable {
  var blockIndex: Int
  var exerciseId: Int
  var name: String
  var isDuration: Bool
  var weightRequired: Bool
  var setIndex: Int
  var setCount: Int
  var kind: WearSetKind
  var weightKg: Double?
  var value: Int?
  var previousWeightKg: Double?
  var previousValue: Int?
  var note: String?
  var noteFrom: String?
  var myNote: String?

  init?(_ json: Any?) {
    guard let m = json as? [String: Any],
          let b = int(m["b"]), let ex = int(m["ex"]), let set = int(m["set"])
    else { return nil }
    blockIndex = b
    exerciseId = ex
    name = m["name"] as? String ?? ""
    isDuration = m["dur"] as? Bool ?? false
    weightRequired = m["wreq"] as? Bool ?? false
    setIndex = set
    setCount = int(m["sets"]) ?? set + 1
    kind = WearSetKind(rawValue: m["kind"] as? String ?? "") ?? .working
    weightKg = double(m["w"])
    value = int(m["val"])
    previousWeightKg = double(m["pw"])
    previousValue = int(m["pval"])
    note = m["note"] as? String
    noteFrom = m["nfrom"] as? String
    myNote = m["mnote"] as? String
  }
}

struct WearExerciseItem: Equatable, Identifiable {
  var blockIndex: Int
  var exerciseId: Int
  var name: String
  var doneSets: Int
  var totalSets: Int

  var id: Int { blockIndex }
  var isDone: Bool { totalSets > 0 && doneSets >= totalSets }

  init?(_ json: Any?) {
    guard let m = json as? [String: Any],
          let b = int(m["b"]), let ex = int(m["ex"])
    else { return nil }
    blockIndex = b
    exerciseId = ex
    name = m["name"] as? String ?? ""
    doneSets = int(m["done"]) ?? 0
    totalSets = int(m["total"]) ?? 0
  }
}

/// Stav tréninku z telefonu (WearState).
struct WearState: Equatable {
  var phase: WearPhase
  var sessionId: Int?
  var title: String?
  /// Začátek tréninku (ms od epochy, hodiny telefonu).
  var startedAtMs: Int?
  var unit: String
  var kgPerUnit: Double
  var weightStep: Double
  var current: WearCurrentSet?
  var restEndsAtMs: Int?
  var restTotalSeconds: Int
  var exercises: [WearExerciseItem]

  init?(_ json: Any?) {
    guard let m = json as? [String: Any] else { return nil }
    // Neznámá fáze (novější telefon) = idle, stejně jako na Wear OS.
    phase = WearPhase(rawValue: m["phase"] as? String ?? "") ?? .idle
    sessionId = int(m["session"])
    title = m["title"] as? String
    startedAtMs = int(m["started"])
    unit = m["unit"] as? String ?? "kg"
    kgPerUnit = double(m["kgPerUnit"]) ?? 1
    weightStep = double(m["step"]) ?? 2.5
    current = WearCurrentSet(m["current"])
    restEndsAtMs = int(m["restEnd"])
    restTotalSeconds = int(m["restTotal"]) ?? 0
    exercises = (m["exercises"] as? [Any] ?? []).compactMap { WearExerciseItem($0) }
  }
}

/// Příkaz z hodinek.
enum WearCommand {
  case completeSet(blockIndex: Int, exerciseId: Int, setIndex: Int, weightKg: Double?, value: Int)
  case adjustWeight(blockIndex: Int, exerciseId: Int, setIndex: Int, delta: Int)
  case adjustReps(blockIndex: Int, exerciseId: Int, setIndex: Int, delta: Int)
  case skipRest
  case nextExercise
  case selectExercise(blockIndex: Int, exerciseId: Int)
  case finishWorkout
  case openWorkout

  var name: String {
    switch self {
    case .completeSet: return "completeSet"
    case .adjustWeight: return "adjustWeight"
    case .adjustReps: return "adjustReps"
    case .skipRest: return "skipRest"
    case .nextExercise: return "nextExercise"
    case .selectExercise: return "selectExercise"
    case .finishWorkout: return "finishWorkout"
    case .openWorkout: return "openWorkout"
    }
  }

  func json(id: Int) -> [String: Any] {
    var m: [String: Any] = ["t": "cmd", "id": id, "cmd": name]
    switch self {
    case let .completeSet(b, ex, set, w, val):
      m["b"] = b
      m["ex"] = ex
      m["set"] = set
      if let w { m["w"] = w } else { m["w"] = NSNull() }
      m["val"] = val
    case let .adjustWeight(b, ex, set, delta), let .adjustReps(b, ex, set, delta):
      m["b"] = b
      m["ex"] = ex
      m["set"] = set
      m["delta"] = delta
    case let .selectExercise(b, ex):
      m["b"] = b
      m["ex"] = ex
    case .skipRest, .nextExercise, .finishWorkout, .openWorkout:
      break
    }
    return m
  }
}
