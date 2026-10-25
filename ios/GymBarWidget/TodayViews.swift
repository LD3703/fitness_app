// Vzhled widgetu „Dnes“ (malý a střední na ploše). Jen SwiftUI, bez
// WidgetKitu – stejné pohledy vykreslí náhledy na macOS
// (tool/ios_widget_preview). Malá a zamykací varianta otevře aplikaci,
// střední má i tlačítko „+ sklenice“.
import SwiftUI

struct TodaySmallView: View {
  let content: TodayContent
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = WidgetPalette.of(scheme)
    VStack(alignment: .leading, spacing: 4) {
      TodayTitle(text: content.title, palette: p)
      Text(content.workout)
        .font(.subheadline.weight(.semibold))
        .foregroundColor(p.text)
        .lineLimit(3)
        .minimumScaleFactor(0.85)
      Spacer(minLength: 0)
      if let water = content.water {
        WaterProgress(text: water, percent: content.percent, palette: p)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct TodayMediumView: View {
  let content: TodayContent
  /// Odkaz tlačítka „+ sklenice“ (WidgetLinks.addWater).
  let addURL: URL
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = WidgetPalette.of(scheme)
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        TodayTitle(text: content.title, palette: p)
        Text(content.workout)
          .font(.headline)
          .foregroundColor(p.text)
          .lineLimit(2)
          .minimumScaleFactor(0.85)
        Spacer(minLength: 0)
        if let water = content.water {
          WaterProgress(text: water, percent: content.percent, palette: p)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      if content.water != nil {
        Link(destination: addURL) {
          Text(content.addLabel)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(p.buttonText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(p.button))
        }
        .accessibilityLabel(Text(content.addDescription))
      }
    }
  }
}

struct TodayTitle: View {
  let text: String
  let palette: WidgetPalette

  var body: some View {
    Text(text.uppercased())
      .font(.caption2.weight(.bold))
      .foregroundColor(palette.accent)
      .lineLimit(1)
  }
}

struct WaterProgress: View {
  let text: String
  let percent: Int
  let palette: WidgetPalette

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(text)
        .font(.caption)
        .foregroundColor(palette.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(palette.track)
          Capsule()
            .fill(palette.accent)
            .frame(width: geo.size.width * CGFloat(percent) / 100)
        }
      }
      .frame(height: 6)
    }
    .accessibilityElement(children: .combine)
  }
}
