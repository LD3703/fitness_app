// Společné věci widgetu (iOS WidgetKit): App Group, barvy, záložní texty.
//
// Data posílá Flutter (lib/modules/widgets/home_widget_service.dart)
// přes balíček home_widget do UserDefaults sdílené App Group. Cíl
// GymBarWidget do Xcode projektu přidává tool/platform/ios_widget.dart
// (docs/ios_widget.md).
import Foundation
import SwiftUI

/// Musí odpovídat kIosAppGroup v lib/modules/widgets/widget_content.dart
/// a App Group v GymBarWidget.entitlements a Runner.entitlements.
let kAppGroup = "group.cz.dedina.fitnessApp"

/// Druh widgetu – musí odpovídat kIosWidgetKind (widget_content.dart).
let kTodayWidgetKind = "GymBarToday"

/// Barvy podle motivu aplikace (seed #2E7D6B), stejně jako widget
/// na Androidu (tool/platform/widgets.dart).
struct WidgetPalette {
  let background: Color
  let text: Color
  let secondary: Color
  let accent: Color
  let track: Color
  let button: Color
  let buttonText: Color

  static let light = WidgetPalette(
    background: Color(hex: 0xF4FBF8),
    text: Color(hex: 0x171D1B),
    secondary: Color(hex: 0x3F4945),
    accent: Color(hex: 0x2E7D6B),
    track: Color(hex: 0xD0E8E0),
    button: Color(hex: 0x2E7D6B),
    buttonText: Color(hex: 0xFFFFFF)
  )

  static let dark = WidgetPalette(
    background: Color(hex: 0x1A2320),
    text: Color(hex: 0xDEE4E1),
    secondary: Color(hex: 0xBFC9C4),
    accent: Color(hex: 0x84D6BF),
    track: Color(hex: 0x334B44),
    button: Color(hex: 0x84D6BF),
    buttonText: Color(hex: 0x00382D)
  )

  static func of(_ scheme: ColorScheme) -> WidgetPalette {
    scheme == .dark ? dark : light
  }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

/// Texty, které widget ukáže bez aplikace (výběr widgetů, před prvním
/// spuštěním). Ostatní texty posílá Flutter v jazyce telefonu.
struct WidgetFallbackTexts {
  let title: String
  let description: String
  let openApp: String

  static func current() -> WidgetFallbackTexts {
    let code = Locale.preferredLanguages.first.map { String($0.prefix(2)) } ?? "en"
    return all[code] ?? all["en"]!
  }

  static let all: [String: WidgetFallbackTexts] = [
    "en": .init(title: "Today", description: "Water intake and today’s workout",
                openApp: "Open the app to load today"),
    "cs": .init(title: "Dnes", description: "Pitný režim a dnešní trénink",
                openApp: "Otevři aplikaci a načti dnešek"),
    "sk": .init(title: "Dnes", description: "Pitný režim a dnešný tréning",
                openApp: "Otvor aplikáciu a načítaj dnešok"),
    "de": .init(title: "Heute", description: "Trinkmenge und heutiges Training",
                openApp: "Öffne die App, um heute zu laden"),
    "es": .init(title: "Hoy", description: "Hidratación y entrenamiento de hoy",
                openApp: "Abre la app para cargar el día de hoy"),
    "fr": .init(title: "Aujourd’hui", description: "Hydratation et séance du jour",
                openApp: "Ouvre l’app pour charger la journée"),
    "it": .init(title: "Oggi", description: "Idratazione e allenamento di oggi",
                openApp: "Apri l’app per caricare la giornata"),
    "nl": .init(title: "Vandaag", description: "Waterinname en training van vandaag",
                openApp: "Open de app om vandaag te laden"),
    "pl": .init(title: "Dziś", description: "Nawodnienie i dzisiejszy trening",
                openApp: "Otwórz aplikację, aby wczytać dzisiejszy dzień"),
    "pt": .init(title: "Hoje", description: "Hidratação e treino de hoje",
                openApp: "Abra o app para carregar o dia de hoje"),
  ]
}
