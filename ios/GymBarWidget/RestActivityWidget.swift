// Live Activity odpočtu pauzy: zamykací obrazovka a Dynamic Island.
// Spouští ji aplikace (Runner/RestLiveActivity.swift) na pokyn Flutteru
// (lib/modules/widgets/rest_live_activity.dart).
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct RestActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RestTimerAttributes.self) { context in
      RestLockScreenView(model: model(context))
        .activityBackgroundTint(nil)
    } dynamicIsland: { context in
      let m = model(context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(m.isOver ? m.doneTitle : m.title)
              .lineLimit(1)
          } icon: {
            Image(systemName: m.isOver ? "checkmark.circle.fill" : "timer")
          }
          .font(.headline)
          .foregroundColor(WidgetPalette.dark.accent)
        }
        DynamicIslandExpandedRegion(.trailing) {
          if !m.isOver {
            RestCountdownText(model: m)
              .font(.system(.title2, design: .rounded).weight(.semibold))
              .frame(maxWidth: 90, alignment: .trailing)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          RestIslandBottomView(model: m)
        }
      } compactLeading: {
        Image(systemName: "timer")
          .foregroundColor(WidgetPalette.dark.accent)
      } compactTrailing: {
        if m.isOver {
          Image(systemName: "checkmark")
            .foregroundColor(WidgetPalette.dark.accent)
        } else {
          RestCountdownText(model: m)
            .frame(maxWidth: 48)
        }
      } minimal: {
        Image(systemName: m.isOver ? "checkmark" : "timer")
          .foregroundColor(WidgetPalette.dark.accent)
      }
    }
  }

  private func model(_ context: ActivityViewContext<RestTimerAttributes>) -> RestActivityModel {
    RestActivityModel(
      title: context.attributes.title,
      detail: context.state.detail,
      doneTitle: context.attributes.doneTitle,
      doneBody: context.attributes.doneBody,
      startAt: context.state.startAt,
      endAt: context.state.endAt,
      isOver: context.isStale || context.state.endAt <= Date()
    )
  }
}
