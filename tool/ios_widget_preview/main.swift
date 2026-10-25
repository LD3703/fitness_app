// Náhledy iOS widgetu a Live Activity jako PNG – vykreslí se na macOS ze
// stejných SwiftUI pohledů jako na iPhonu (ios/GymBarWidget/*Views.swift),
// bez simulátoru. Spouští CI (.github/workflows/ci.yml, job ios),
// obrázky jsou v artefaktu „ios-widget-previews“.
//
//   swiftc -target arm64-apple-macos13.0 \
//     ios/GymBarWidget/{WidgetShared,TodayContent,TodayViews,RestActivityViews}.swift \
//     tool/ios_widget_preview/main.swift -o build/widget_preview
//   build/widget_preview build/widget_previews
import AppKit
import SwiftUI

let outDir = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "widget_previews")

@MainActor
func save<V: View>(_ name: String, _ view: V, size: CGSize, scheme: ColorScheme,
                   background: Color? = nil, cornerRadius: CGFloat = 22) {
  let bg = background ?? WidgetPalette.of(scheme).background
  let content = view
    .padding(16)
    .frame(width: size.width, height: size.height)
    .background(bg)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    .padding(8)
    .background(scheme == .dark ? Color.black : Color(white: 0.85))
    .environment(\.colorScheme, scheme)
  let renderer = ImageRenderer(content: content)
  renderer.scale = 2
  guard let image = renderer.nsImage,
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
  else {
    fatalError("Náhled \(name) se nepodařilo vykreslit.")
  }
  try! png.write(to: outDir.appendingPathComponent("\(name).png"))
  print("✓ \(name).png")
}

@MainActor
func run() {
  try! FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
  let small = CGSize(width: 170, height: 170)
  let medium = CGSize(width: 364, height: 170)
  let addURL = WidgetLinks.addWater(ml: 250, renderedAt: Date())

  let today = TodayContent.preview
  let long = TodayContent(
    title: "Dziś",
    workout: "Trening siłowy – nogi i pośladki · 18:00 +1",
    water: "💧 1 250 / 2 500 ml",
    percent: 50, glassMl: 330,
    addLabel: "+330 ml", addDescription: "+330 ml")
  var noWater = today
  noWater.water = nil

  for scheme in [ColorScheme.light, .dark] {
    let s = scheme == .dark ? "dark" : "light"
    save("today_small_\(s)", TodaySmallView(content: today), size: small, scheme: scheme)
    save("today_medium_\(s)", TodayMediumView(content: today, addURL: addURL),
         size: medium, scheme: scheme)
  }
  save("today_small_long", TodaySmallView(content: long), size: small, scheme: .light)
  save("today_medium_long", TodayMediumView(content: long, addURL: addURL),
       size: medium, scheme: .light)
  save("today_small_no_water", TodaySmallView(content: noWater), size: small, scheme: .light)
  save("today_medium_no_water", TodayMediumView(content: noWater, addURL: addURL),
       size: medium, scheme: .light)

  let now = Date()
  let rest = RestActivityModel(
    title: "Pauza", detail: "Další: Bench press",
    doneTitle: "Pauza skončila", doneBody: "Čas na další sérii!",
    startAt: now.addingTimeInterval(-30), endAt: now.addingTimeInterval(60),
    isOver: false)
  var over = rest
  over.isOver = true
  let lock = CGSize(width: 370, height: 110)
  for scheme in [ColorScheme.light, .dark] {
    let s = scheme == .dark ? "dark" : "light"
    save("rest_lock_\(s)", RestLockScreenView(model: rest), size: lock, scheme: scheme)
  }
  save("rest_lock_over", RestLockScreenView(model: over), size: lock, scheme: .light)
  save("rest_island_bottom", RestIslandBottomView(model: rest),
       size: CGSize(width: 370, height: 70), scheme: .dark,
       background: .black, cornerRadius: 40)
}

Task { @MainActor in
  run()
  exit(0)
}
dispatchMain()
