import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bell: BellController
    @EnvironmentObject private var history: HistoryStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if bell.phase == .idle {
                sessionSetup
            } else {
                sessionInProgress
            }
            Divider()
            reminders
            Divider()
            sound
            Divider()
            HStack {
                Button("History") { show(WindowID.history) }
                Button("Settings") { show(WindowID.settings) }
                    .keyboardShortcut(",")
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func show(_ id: String) {
        openWindow(id: id)
        // A menu bar app isn't active by default, so bring the window forward.
        NSApp.activate()
    }

    // MARK: Meditation

    private var sessionSetup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meditation").font(.headline)
            if !history.sits.isEmpty {
                Text(streakSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Picker("Duration", selection: $bell.durationMinutes) {
                ForEach([5, 10, 15, 20, 25, 30, 40, 45, 60, 90], id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            Picker("Interval bell", selection: $bell.intervalMinutes) {
                Text("None").tag(0)
                ForEach([1, 2, 5, 10, 15, 20, 30], id: \.self) { m in
                    Text("Every \(m) min").tag(m)
                }
            }
            Picker("Settle in", selection: $bell.preparationSeconds) {
                Text("None").tag(0)
                Text("10 sec").tag(10)
                Text("30 sec").tag(30)
                Text("1 min").tag(60)
            }
            Button {
                bell.begin()
            } label: {
                Label("Begin", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .padding(.top, 4)
        }
    }

    private var sessionInProgress: some View {
        VStack(spacing: 8) {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(bell.remainingText)
                .font(.system(size: 44, weight: .light, design: .rounded))
                .monospacedDigit()
            ProgressView(value: bell.progress)
            HStack {
                Button(bell.isPaused ? "Resume" : "Pause") { bell.togglePause() }
                    .keyboardShortcut(.space, modifiers: [])
                Button("End") { bell.end(ringBell: false) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var streakSummary: String {
        let streak = history.currentStreak
        let week = HistoryStore.durationText(history.weekSeconds)
        let days = streak == 1 ? "1-day streak" : "\(streak)-day streak"
        return streak > 0 ? "\(days) · \(week) this week" : "\(week) this week"
    }

    private var statusText: String {
        if bell.isPaused { return "Paused" }
        return bell.phase == .preparing ? "Settling in…" : "Sitting"
    }

    // MARK: Reminders

    private var reminders: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $bell.remindersEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mindful day").font(.headline)
                    Text("A bell now and then to stop and breathe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            if bell.remindersEnabled {
                Picker("Every", selection: $bell.reminderMinutes) {
                    ForEach([15, 20, 30, 45, 60, 90, 120], id: \.self) { m in
                        Text(m < 60 ? "\(m) min" : (m % 60 == 0 ? "\(m / 60) hr" : "\(m / 60) hr \(m % 60) min")).tag(m)
                    }
                }
                Toggle("Vary the timing", isOn: $bell.reminderRandomized)
                HStack {
                    Picker("From", selection: $bell.activeFromHour) { hourOptions }
                    Picker("to", selection: $bell.activeUntilHour) { hourOptions }
                }
                if bell.remindersSilencedByFocus {
                    Label("Silenced by your Focus", systemImage: "moon.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let next = bell.nextReminder {
                    (Text("Next bell at ") + Text(next, style: .time))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var hourOptions: some View {
        ForEach(0..<24, id: \.self) { hour in
            Text(Self.hourLabel(hour)).tag(hour)
        }
    }

    private static func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: Sound

    private var sound: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Bell", selection: $bell.tone) {
                ForEach(BellTone.allCases) { tone in
                    Text(tone.name).tag(tone)
                }
            }
            HStack {
                Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                Slider(value: $bell.volume, in: 0...1)
                Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                Button {
                    bell.ring()
                } label: {
                    Image(systemName: "bell")
                }
                .help("Ring the bell")
            }
        }
    }
}
