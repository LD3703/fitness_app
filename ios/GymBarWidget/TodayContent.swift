// Obsah widgetu „Dnes“ z dat, která uložil Flutter (klíče WidgetKeys
// v lib/modules/widgets/widget_content.dart). Bez WidgetKitu – kvůli
// náhledům vykresleným na macOS (tool/ios_widget_preview).
import Foundation

struct TodayContent {
  var title: String
  var workout: String
  /// Řádek pitného režimu, nebo nil (sledování vody vypnuté / chybí data).
  var water: String?
  var percent: Int
  var glassMl: Int
  var addLabel: String
  /// Pro VoiceOver (např. „Přidat sklenici 250 ml“).
  var addDescription: String

  /// Flutter ukládá dnešek i zítřek, aby widget po půlnoci nelhal
  /// (stejně jako FitnessWidgetProvider.kt na Androidu).
  static func load(from data: UserDefaults?, at date: Date) -> TodayContent {
    let fallback = WidgetFallbackTexts.current()
    func string(_ key: String) -> String? { data?.string(forKey: key) }

    let title = string("fw_title") ?? fallback.title
    let glass = string("fw_glass_ml").flatMap(Int.init) ?? 250
    let addLabel = string("fw_add_label") ?? "+\(glass) ml"
    let addDescription = string("fw_add_desc") ?? addLabel

    let day = dayKey(date)
    let suffix: String
    if day == string("fw_day") {
      suffix = ""
    } else if day == string("fw_day_next") {
      suffix = "_next"
    } else {
      return TodayContent(
        title: title, workout: fallback.openApp, water: nil, percent: 0,
        glassMl: glass, addLabel: addLabel, addDescription: addDescription)
    }

    let waterVisible = (string("fw_water_visible") ?? "1") == "1"
    return TodayContent(
      title: title,
      workout: string("fw_workout\(suffix)") ?? fallback.openApp,
      water: waterVisible ? string("fw_water\(suffix)") : nil,
      percent: min(100, max(0, string("fw_percent\(suffix)").flatMap(Int.init) ?? 0)),
      glassMl: glass,
      addLabel: addLabel,
      addDescription: addDescription
    )
  }

  /// Den ve tvaru, který ukládá Flutter (widgetDayKey: yyyy-MM-dd, místní čas).
  static func dayKey(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
  }

  /// Ukázka pro výběr widgetů a náhledy.
  static let preview = TodayContent(
    title: WidgetFallbackTexts.current().title,
    workout: "Push · 18:00",
    water: "💧 1 250 / 2 500 ml",
    percent: 50,
    glassMl: 250,
    addLabel: "+250 ml",
    addDescription: "+250 ml"
  )
}

/// Odkazy z widgetu zpracuje Flutter (_handleWidgetUri v
/// home_widget_service.dart). Parametr `homeWidget` je značka, podle
/// které balíček home_widget pozná odkaz z widgetu; `n` je čas
/// vykreslení (nonce), aby se jedno klepnutí nepřičetlo dvakrát.
enum WidgetLinks {
  static let open = URL(string: "homewidget://open?homeWidget")!

  static func addWater(ml: Int, renderedAt: Date) -> URL {
    let nonce = Int64(renderedAt.timeIntervalSince1970 * 1000)
    return URL(string: "homewidget://water?ml=\(ml)&n=\(nonce)&homeWidget")!
  }
}
