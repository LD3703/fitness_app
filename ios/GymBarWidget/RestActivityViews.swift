// Vzhled Live Activity odpočtu pauzy (zamykací obrazovka a rozbalený
// Dynamic Island). Jen SwiftUI – stejné pohledy vykreslí náhledy na macOS
// (tool/ios_widget_preview). Odpočet běží sám (Text(timerInterval:)),
// aplikace ho nemusí překreslovat.
import SwiftUI

struct RestActivityModel {
  var title: String
  var detail: String
  var doneTitle: String
  var doneBody: String
  var startAt: Date
  var endAt: Date
  /// Pauza už skončila (ActivityKit: context.isStale).
  var isOver: Bool

  /// Rozsah pro odpočet; konec nikdy před začátkem.
  var interval: ClosedRange<Date> { startAt...max(startAt, endAt) }
}

struct RestLockScreenView: View {
  let model: RestActivityModel
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let p = WidgetPalette.of(scheme)
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: model.isOver ? "checkmark.circle.fill" : "timer")
          .font(.title2)
          .foregroundColor(p.accent)
        VStack(alignment: .leading, spacing: 2) {
          Text(model.isOver ? model.doneTitle : model.title)
            .font(.headline)
            .foregroundColor(p.text)
            .lineLimit(1)
          Text(model.isOver ? model.doneBody : model.detail)
            .font(.subheadline)
            .foregroundColor(p.secondary)
            .lineLimit(1)
        }
        Spacer(minLength: 8)
        if !model.isOver {
          RestCountdownText(model: model)
            .font(.system(size: 36, weight: .semibold, design: .rounded))
            .foregroundColor(p.text)
            .frame(maxWidth: 120, alignment: .trailing)
        }
      }
      if !model.isOver {
        RestProgressBar(model: model, palette: p)
      }
    }
    .padding(16)
  }
}

/// Rozbalený Dynamic Island: spodní řádek s cvikem a průběhem.
struct RestIslandBottomView: View {
  let model: RestActivityModel

  var body: some View {
    let p = WidgetPalette.dark
    VStack(alignment: .leading, spacing: 6) {
      Text(model.isOver ? model.doneBody : model.detail)
        .font(.subheadline)
        .foregroundColor(p.secondary)
        .lineLimit(1)
      if !model.isOver {
        RestProgressBar(model: model, palette: p)
      }
    }
  }
}

struct RestCountdownText: View {
  let model: RestActivityModel

  var body: some View {
    Text(timerInterval: model.interval, countsDown: true)
      .monospacedDigit()
      .multilineTextAlignment(.trailing)
      .lineLimit(1)
  }
}

struct RestProgressBar: View {
  let model: RestActivityModel
  let palette: WidgetPalette

  var body: some View {
    ProgressView(timerInterval: model.interval, countsDown: true) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .progressViewStyle(.linear)
    .tint(palette.accent)
    .labelsHidden()
  }
}
