// Obrazovky aplikace v Apple Watch – obdoba wear/lib/ui (Wear OS).
import SwiftUI

@main
struct GymBarWatchApp: App {
  @StateObject private var controller = WatchController()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(controller)
        .onAppear { controller.start() }
    }
  }
}

private let accent = Color(red: 0x84 / 255, green: 0xD6 / 255, blue: 0xBF / 255)

struct ContentView: View {
  @EnvironmentObject var c: WatchController

  var body: some View {
    NavigationStack {
      Group {
        switch c.phase {
        case .connecting:
          MessageView(text: c.strings.connecting, progress: true)
        case .unreachable:
          MessageView(text: c.strings.unreachable, action: c.strings.retry) { c.retry() }
        case .idle:
          MessageView(text: c.strings.idle)
        case .openOnPhone:
          MessageView(text: c.strings.openOnPhone, action: c.strings.open) { c.openWorkout() }
        case .premiumRequired:
          MessageView(text: c.strings.premiumRequired)
        case .active:
          ActiveView()
        }
      }
      .navigationTitle(c.state?.title ?? c.strings.appTitle)
      .overlay(alignment: .bottom) {
        if let notice = c.notice {
          Text(notice)
            .font(.footnote)
            .padding(6)
            .background(Color.black.opacity(0.75), in: Capsule())
            .padding(.bottom, 4)
        }
      }
    }
  }
}

struct MessageView: View {
  let text: String
  var progress = false
  var action: String?
  var onAction: (() -> Void)?

  var body: some View {
    ScrollView {
      VStack(spacing: 10) {
        if progress { ProgressView() }
        Text(text).multilineTextAlignment(.center)
        if let action, let onAction {
          Button(action, action: onAction).tint(accent)
        }
      }
      .padding(.top, 8)
    }
  }
}

struct ActiveView: View {
  @EnvironmentObject var c: WatchController

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        if let bpm = c.heartRate {
          Label("\(bpm)", systemImage: "heart.fill")
            .font(.caption)
            .foregroundStyle(.red)
        }
        if c.restEnd != nil { RestPanel() }
        if let set = c.current {
          SetPanel(set: set)
        } else {
          Text(c.strings.allDone).font(.headline).multilineTextAlignment(.center)
        }
        if c.current != nil, (c.state?.exercises.count ?? 0) > 1 {
          Button(c.strings.nextExercise) { c.nextExercise() }
            .disabled(c.isPending("nextExercise"))
        }
        if let exercises = c.state?.exercises, !exercises.isEmpty {
          NavigationLink(c.strings.exercises) { ExerciseListView() }
        }
        Button(c.strings.finish, role: .destructive) { c.finishWorkout() }
          .disabled(c.isPending("finishWorkout"))
      }
    }
  }
}

struct RestPanel: View {
  @EnvironmentObject var c: WatchController

  var body: some View {
    VStack(spacing: 4) {
      Text(c.strings.rest).font(.caption2).foregroundStyle(.secondary)
      if let end = c.restEnd {
        Text(timerInterval: Date()...max(Date(), end), countsDown: true)
          .font(.system(size: 34, weight: .semibold, design: .rounded))
          .monospacedDigit()
      }
      ProgressView(value: c.restProgress).tint(accent)
      Button(c.strings.skip) { c.skipRest() }
        .disabled(c.isPending("skipRest"))
    }
  }
}

struct SetPanel: View {
  @EnvironmentObject var c: WatchController
  let set: WearCurrentSet

  var body: some View {
    VStack(spacing: 6) {
      Text(set.name)
        .font(.headline)
        .multilineTextAlignment(.center)
        .lineLimit(2)
      Text(subtitle).font(.caption2).foregroundStyle(.secondary)
      if !set.isDuration {
        ValueStepper(
          label: c.strings.weightLabel,
          value: weightText,
          onMinus: { c.adjustWeight(set, up: false) },
          onPlus: { c.adjustWeight(set, up: true) }
        )
      }
      ValueStepper(
        label: set.isDuration ? c.strings.seconds : c.strings.reps,
        value: c.value(of: set).map { String($0) } ?? "–",
        onMinus: { c.adjustValue(set, up: false) },
        onPlus: { c.adjustValue(set, up: true) }
      )
      Button {
        c.completeSet(set)
      } label: {
        Text(c.strings.done).frame(maxWidth: .infinity)
      }
      .tint(accent)
      .disabled(c.isPending("completeSet"))
      if let prev = set.previousValue {
        Text(c.strings.lastTime(c.describe(weightKg: set.previousWeightKg, value: prev,
                                           isDuration: set.isDuration)))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }

  private var subtitle: String {
    var parts = [c.strings.setOf(set.setIndex + 1, set.setCount)]
    switch set.kind {
    case .warmup: parts.append(c.strings.warmup)
    case .drop: parts.append(c.strings.drop)
    case .working: break
    }
    return parts.joined(separator: " · ")
  }

  private var weightText: String {
    guard let w = c.displayWeight(c.weightKg(of: set)) else {
      return set.weightRequired ? "–" : c.strings.bodyweight
    }
    return "\(c.format(w)) \(c.state?.unit ?? "kg")"
  }
}

struct ValueStepper: View {
  let label: String
  let value: String
  let onMinus: () -> Void
  let onPlus: () -> Void

  var body: some View {
    HStack {
      Button(action: onMinus) { Image(systemName: "minus") }
        .frame(width: 40)
      VStack(spacing: 0) {
        Text(value).font(.title3.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
        Text(label).font(.caption2).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      Button(action: onPlus) { Image(systemName: "plus") }
        .frame(width: 40)
    }
    .buttonStyle(.bordered)
  }
}

struct ExerciseListView: View {
  @EnvironmentObject var c: WatchController
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List(c.state?.exercises ?? []) { e in
      Button {
        c.select(e)
        dismiss()
      } label: {
        HStack {
          Text(e.name).lineLimit(2)
          Spacer()
          Text("\(e.doneSets)/\(e.totalSets)")
            .font(.caption)
            .foregroundStyle(e.isDone ? accent : .secondary)
        }
      }
    }
    .navigationTitle(c.strings.exercises)
  }
}
