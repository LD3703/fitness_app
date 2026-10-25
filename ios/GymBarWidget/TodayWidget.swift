// Widget „Dnes“ (WidgetKit): pitný režim a dnešní trénink na ploše
// a na zamykací obrazovce. Obsah se překreslí, když Flutter zavolá
// HomeWidget.updateWidget, a sám o půlnoci (data na zítřek).
import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
  let date: Date
  let content: TodayContent
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(date: Date(), content: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    let now = Date()
    let content = context.isPreview ? TodayContent.preview : load(at: now)
    completion(TodayEntry(date: now, content: content))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    let now = Date()
    let calendar = Calendar.current
    let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
    let next = calendar.date(byAdding: .day, value: 1, to: midnight)!
    let entries = [
      TodayEntry(date: now, content: load(at: now)),
      TodayEntry(date: midnight, content: load(at: midnight)),
    ]
    completion(Timeline(entries: entries, policy: .after(next)))
  }

  private func load(at date: Date) -> TodayContent {
    TodayContent.load(from: UserDefaults(suiteName: kAppGroup), at: date)
  }
}

struct TodayWidgetView: View {
  let entry: TodayEntry
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let content = entry.content
    switch family {
    case .systemMedium:
      TodayMediumView(
        content: content,
        addURL: WidgetLinks.addWater(ml: content.glassMl, renderedAt: entry.date)
      )
      .widgetBackground(WidgetPalette.of(scheme).background)
      .widgetURL(WidgetLinks.open)
    case .accessoryCircular:
      TodayCircularView(content: content)
        .widgetBackground(nil)
        .widgetURL(WidgetLinks.open)
    case .accessoryRectangular:
      TodayRectangularView(content: content)
        .widgetBackground(nil)
        .widgetURL(WidgetLinks.open)
    case .accessoryInline:
      Text(content.workout)
        .widgetBackground(nil)
        .widgetURL(WidgetLinks.open)
    default:
      TodaySmallView(content: content)
        .widgetBackground(WidgetPalette.of(scheme).background)
        .widgetURL(WidgetLinks.open)
    }
  }
}

/// Zamykací obrazovka: kroužek s procenty vody (bez vody činka).
struct TodayCircularView: View {
  let content: TodayContent

  var body: some View {
    if content.water != nil {
      Gauge(value: Double(content.percent), in: 0...100) {
        Image(systemName: "drop.fill")
      } currentValueLabel: {
        Text("\(content.percent)")
      }
      .gaugeStyle(.accessoryCircular)
    } else {
      ZStack {
        AccessoryWidgetBackground()
        Image(systemName: "dumbbell.fill")
          .font(.title3)
      }
    }
  }
}

/// Zamykací obrazovka: trénink a voda pod sebou.
struct TodayRectangularView: View {
  let content: TodayContent

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(content.title)
        .font(.headline)
        .widgetAccentable()
        .lineLimit(1)
      Text(content.workout)
        .font(.caption)
        .lineLimit(content.water == nil ? 2 : 1)
      if let water = content.water {
        Text(water)
          .font(.caption)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    let texts = WidgetFallbackTexts.current()
    return StaticConfiguration(kind: kTodayWidgetKind, provider: TodayProvider()) { entry in
      TodayWidgetView(entry: entry)
    }
    .configurationDisplayName(texts.title)
    .description(texts.description)
    .supportedFamilies([
      .systemSmall, .systemMedium,
      .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ])
  }
}

extension View {
  /// Pozadí widgetu: od iOS 17 přes containerBackground (jinak iOS ukáže
  /// výzvu k úpravě widgetu), dřív obyčejné pozadí s okrajem. Zamykací
  /// obrazovka ([color] nil) pozadí ani okraj nemá.
  @ViewBuilder
  func widgetBackground(_ color: Color?) -> some View {
    if #available(iOS 17.0, *) {
      self.containerBackground(for: .widget) { color ?? Color.clear }
    } else if let color {
      self.padding().background(color)
    } else {
      self
    }
  }
}
