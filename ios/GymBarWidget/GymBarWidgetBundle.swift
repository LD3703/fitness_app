// Rozšíření GymBarWidget: widget „Dnes“ a Live Activity odpočtu pauzy.
// Cíl do Xcode projektu přidává tool/platform/ios_widget.dart
// (docs/ios_widget.md).
import SwiftUI
import WidgetKit

@main
struct GymBarWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
    RestActivityWidget()
  }
}
