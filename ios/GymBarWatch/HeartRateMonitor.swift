// Tep během tréninku na Apple Watch: HKWorkoutSession (silový trénink)
// zapne měření tepu po sekundách. Trénink se do Apple Zdraví z hodinek
// neukládá – zapisuje ho aplikace v telefonu (modul health), aby nebyl
// dvakrát. Tep jde do telefonu (zpráva hr) a ten z něj spočítá průměr,
// maximum a zóny (lib/core/readiness.dart).
import Foundation
import HealthKit

final class HeartRateMonitor: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
  private let store = HKHealthStore()
  private var session: HKWorkoutSession?
  private var builder: HKLiveWorkoutBuilder?

  /// Nový tep (tepy/min), volá se na hlavním vlákně.
  var onHeartRate: ((Int) -> Void)?

  var isRunning: Bool { session != nil }

  func start() {
    guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }
    let heartRate = HKQuantityType(.heartRate)
    // Sezení tréninku potřebuje oprávnění zapisovat tréninky, i když se
    // nakonec nic neuloží.
    store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [heartRate]) {
      [weak self] granted, _ in
      guard granted else { return }
      DispatchQueue.main.async { self?.begin() }
    }
  }

  private func begin() {
    guard session == nil else { return }
    let config = HKWorkoutConfiguration()
    config.activityType = .traditionalStrengthTraining
    config.locationType = .indoor
    do {
      let session = try HKWorkoutSession(healthStore: store, configuration: config)
      let builder = session.associatedWorkoutBuilder()
      builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
      session.delegate = self
      builder.delegate = self
      self.session = session
      self.builder = builder
      let start = Date()
      session.startActivity(with: start)
      builder.beginCollection(withStart: start) { _, _ in }
    } catch {
      session = nil
      builder = nil
    }
  }

  func stop() {
    guard let session else { return }
    session.end()
    builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
      self?.builder?.discardWorkout()
      DispatchQueue.main.async {
        self?.builder = nil
      }
    }
    self.session = nil
  }

  // MARK: HKWorkoutSessionDelegate

  func workoutSession(
    _ workoutSession: HKWorkoutSession,
    didChangeTo toState: HKWorkoutSessionState,
    from fromState: HKWorkoutSessionState,
    date: Date
  ) {}

  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    DispatchQueue.main.async { [weak self] in
      self?.session = nil
      self?.builder = nil
    }
  }

  // MARK: HKLiveWorkoutBuilderDelegate

  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

  func workoutBuilder(
    _ workoutBuilder: HKLiveWorkoutBuilder,
    didCollectDataOf collectedTypes: Set<HKSampleType>
  ) {
    let type = HKQuantityType(.heartRate)
    guard collectedTypes.contains(type),
          let stats = workoutBuilder.statistics(for: type),
          let quantity = stats.mostRecentQuantity()
    else { return }
    let bpm = Int(quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())).rounded())
    DispatchQueue.main.async { [weak self] in
      self?.onHeartRate?(bpm)
    }
  }
}
