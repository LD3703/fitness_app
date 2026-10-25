// Live Activity odpočtu pauzy – spouštění z aplikace. Flutter
// (lib/modules/widgets/rest_live_activity.dart) volá kanál
// gymbar/rest_live_activity: „show“ (začátek nebo změna pauzy) a „end“.
// Vzhled je v rozšíření GymBarWidget (RestActivityWidget.swift).
// Registraci v AppDelegate.swift doplňuje tool/platform/ios_widget.dart.
import ActivityKit
import Flutter
import Foundation

final class RestLiveActivityPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "gymbar/rest_live_activity", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(RestLiveActivityPlugin(), channel: channel)
    // Aktivita z minulého běhu (aplikaci systém ukončil během pauzy).
    if #available(iOS 16.2, *) {
      Task { await RestLiveActivityPlugin.endAll() }
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(false)
      return
    }
    switch call.method {
    case "show":
      guard let args = call.arguments as? [String: Any],
        let title = args["title"] as? String,
        let doneTitle = args["doneTitle"] as? String,
        let doneBody = args["doneBody"] as? String,
        let detail = args["detail"] as? String,
        let startMs = (args["startMs"] as? NSNumber)?.doubleValue,
        let endMs = (args["endMs"] as? NSNumber)?.doubleValue
      else {
        result(FlutterError(code: "args", message: "Invalid arguments", details: nil))
        return
      }
      let attributes = RestTimerAttributes(
        title: title, doneTitle: doneTitle, doneBody: doneBody)
      let state = RestTimerAttributes.ContentState(
        startAt: Date(timeIntervalSince1970: startMs / 1000),
        endAt: Date(timeIntervalSince1970: endMs / 1000),
        detail: detail)
      // Odpověď Flutteru musí jít z hlavního vlákna.
      Task { @MainActor in
        result(await RestLiveActivityPlugin.show(attributes, state))
      }
    case "end":
      Task { @MainActor in
        await RestLiveActivityPlugin.endAll()
        result(true)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Ukáže pauzu: stávající aktivitu se stejnými texty jen aktualizuje,
  /// jinak ji nahradí novou. Vrací false, když jsou Live Activity
  /// v nastavení vypnuté nebo je iOS odmítne.
  @available(iOS 16.2, *)
  private static func show(
    _ attributes: RestTimerAttributes, _ state: RestTimerAttributes.ContentState
  ) async -> Bool {
    let content = ActivityContent(state: state, staleDate: state.endAt)
    let running = Activity<RestTimerAttributes>.activities
    if let current = running.first(where: { sameTexts($0.attributes, attributes) }) {
      await current.update(content)
      for other in running where other.id != current.id {
        await other.end(nil, dismissalPolicy: .immediate)
      }
      return true
    }
    await endAll()
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
    do {
      _ = try Activity.request(attributes: attributes, content: content)
      return true
    } catch {
      return false
    }
  }

  @available(iOS 16.2, *)
  private static func endAll() async {
    for activity in Activity<RestTimerAttributes>.activities {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  @available(iOS 16.2, *)
  private static func sameTexts(_ a: RestTimerAttributes, _ b: RestTimerAttributes) -> Bool {
    a.title == b.title && a.doneTitle == b.doneTitle && a.doneBody == b.doneBody
  }
}
