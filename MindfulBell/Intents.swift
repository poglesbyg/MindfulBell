import AppIntents

// Actions that appear in the Shortcuts app, Spotlight and Siri. They are part of Pro:
// they stay listed for everyone, and explain themselves if run without it.

struct ProRequiredError: Error, CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource {
        "This action is part of Stillpoint Pro. Open Stillpoint and choose Unlock Pro."
    }
}

@MainActor
private func requirePro() async throws {
    guard await Store.shared.checkPro() else { throw ProRequiredError() }
}

struct StartMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Meditation"
    static var description = IntentDescription(
        "Begins a sit with Stillpoint and outputs the time the closing bell will ring.")

    @Parameter(title: "Minutes", description: "Leave empty to use the length set in Stillpoint.")
    var minutes: Int?

    static var parameterSummary: some ParameterSummary {
        Summary("Meditate for \(\.$minutes) minutes")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Date> {
        try await requirePro()
        let bell = BellController.shared
        bell.begin(minutes: minutes.map { min(max($0, 1), 240) })
        return .result(value: bell.expectedEnd ?? Date())
    }
}

struct EndMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "End Meditation"
    static var description = IntentDescription("Ends the current sit. Sits of a minute or more are saved to history.")

    @Parameter(title: "Ring Closing Bell", default: false)
    var ringBell: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requirePro()
        BellController.shared.end(ringBell: ringBell)
        return .result()
    }
}

struct RingBellIntent: AppIntent {
    static var title: LocalizedStringResource = "Ring Bell"
    static var description = IntentDescription("Rings the Stillpoint bell once.")

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requirePro()
        BellController.shared.ring()
        return .result()
    }
}

struct SetMindfulDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Mindful Day"
    static var description = IntentDescription("Turns the bells that ring throughout the day on or off.")

    @Parameter(title: "Enabled", default: true)
    var enabled: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Turn Mindful Day bells \(\.$enabled)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        try await requirePro()
        BellController.shared.remindersEnabled = enabled
        return .result()
    }
}

struct GetMeditationStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Meditation Minutes"
    static var description = IntentDescription("Outputs the minutes meditated today and says your current streak.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
        try await requirePro()
        let history = HistoryStore.shared
        let minutes = history.todaySeconds / 60
        let streak = history.currentStreak
        let streakText = streak == 1 ? "1 day" : "\(streak) days"
        return .result(value: minutes,
                       dialog: "You've meditated \(minutes) minutes today. Your streak is \(streakText).")
    }
}

struct MindfulBellShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartMeditationIntent(),
                    phrases: ["Start meditating with \(.applicationName)",
                              "Begin a sit with \(.applicationName)"],
                    shortTitle: "Start Meditation",
                    systemImageName: "play.circle")
        AppShortcut(intent: EndMeditationIntent(),
                    phrases: ["End my sit with \(.applicationName)",
                              "Stop meditating with \(.applicationName)"],
                    shortTitle: "End Meditation",
                    systemImageName: "stop.circle")
        AppShortcut(intent: RingBellIntent(),
                    phrases: ["Ring \(.applicationName)"],
                    shortTitle: "Ring Bell",
                    systemImageName: "bell")
        AppShortcut(intent: GetMeditationStatsIntent(),
                    phrases: ["How long have I meditated with \(.applicationName)"],
                    shortTitle: "Meditation Minutes",
                    systemImageName: "chart.bar")
    }
}

// MARK: Focus filter

/// Appears under "Focus Filters" when you edit a Focus in System Settings.
struct MindfulBellFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Stillpoint"
    static var description = IntentDescription(
        "Silence Mindful Day bells, or start a sit, while this Focus is on.")

    // Both default to off: when the Focus ends, the filter reverts to its defaults,
    // which must mean "no effect".
    @Parameter(title: "Silence Mindful Day bells", default: false)
    var silenceReminders: Bool

    @Parameter(title: "Start a sit when this Focus turns on", default: false)
    var startSit: Bool

    var displayRepresentation: DisplayRepresentation {
        var effects: [String] = []
        if silenceReminders { effects.append("Mindful Day bells silenced") }
        if startSit { effects.append("Starts a sit") }
        let summary = effects.isEmpty ? "No changes" : effects.joined(separator: ", ")
        return DisplayRepresentation(title: "Stillpoint", subtitle: "\(summary)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        // Without Pro the filter has no effect, rather than failing each time a Focus changes.
        guard await Store.shared.checkPro() else { return .result() }
        BellController.shared.applyFocus(silenceReminders: silenceReminders, startSit: startSit)
        return .result()
    }
}
