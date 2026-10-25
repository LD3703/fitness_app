// Live Activity odpočtu pauzy mezi sériemi. Soubor je v obou cílech:
// v aplikaci (Runner/RestLiveActivity.swift ji spouští) i ve widgetu
// (RestActivityWidget.swift ji zobrazuje) – ActivityKit je páruje podle
// typu, proto musí být stejný.
import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct RestTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// Začátek a konec pauzy (konec se mění přidáním / ubráním času).
    var startAt: Date
    var endAt: Date
    /// Další cvik („Další: Bench press“), nebo obecný text.
    var detail: String
  }

  /// Texty v jazyce aplikace (posílá Flutter, lib/l10n).
  var title: String
  var doneTitle: String
  var doneBody: String
}
