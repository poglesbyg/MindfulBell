import AppKit
import ServiceManagement

/// Runs meditation sessions and the "mindful day" reminder bells, and persists settings.
@MainActor
final class BellController: ObservableObject {
    /// Shared so App Intents and the Focus filter drive the same session as the menu.
    static let shared = BellController()

    enum Phase: Equatable {
        case idle, preparing, sitting
    }

    private enum Key: String {
        case durationMinutes, intervalMinutes, preparationSeconds, tone, volume
        case remindersEnabled, reminderMinutes, reminderRandomized, activeFromHour, activeUntilHour
        case startShortcutName, endShortcutName
    }

    // MARK: Settings

    @Published var durationMinutes: Int { didSet { store(durationMinutes, .durationMinutes) } }
    /// Minutes between bells during a sit; 0 means no interval bells.
    @Published var intervalMinutes: Int { didSet { store(intervalMinutes, .intervalMinutes) } }
    /// Quiet time before the opening bell.
    @Published var preparationSeconds: Int { didSet { store(preparationSeconds, .preparationSeconds) } }
    @Published var tone: BellTone {
        didSet {
            store(tone.rawValue, .tone)
            synth.prepare(tone)
        }
    }
    @Published var volume: Double { didSet { store(volume, .volume) } }

    @Published var remindersEnabled: Bool {
        didSet {
            store(remindersEnabled, .remindersEnabled)
            rescheduleReminder()
            updateTimer()
        }
    }
    @Published var reminderMinutes: Int { didSet { store(reminderMinutes, .reminderMinutes); rescheduleReminder() } }
    @Published var reminderRandomized: Bool { didSet { store(reminderRandomized, .reminderRandomized); rescheduleReminder() } }
    /// Reminders ring only between these hours. Equal values mean all day; from > until spans midnight.
    @Published var activeFromHour: Int { didSet { store(activeFromHour, .activeFromHour); rescheduleReminder() } }
    @Published var activeUntilHour: Int { didSet { store(activeUntilHour, .activeUntilHour); rescheduleReminder() } }

    /// Shortcuts to run when a sit begins and ends, e.g. to turn Do Not Disturb on and off. Empty means none.
    @Published var startShortcutName: String { didSet { store(startShortcutName, .startShortcutName) } }
    @Published var endShortcutName: String { didSet { store(endShortcutName, .endShortcutName) } }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Fails for unsigned builds; the toggle then simply stays off.
                NSLog("MindfulBell: could not change login item: \(error)")
            }
        }
    }

    // MARK: State

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isPaused = false
    /// Seconds elapsed in the current phase, excluding pauses.
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var nextReminder: Date?
    /// Set by the Focus filter while a Focus that silences reminders is on.
    @Published private(set) var remindersSilencedByFocus = false
    /// Length of the current sit; may differ from `durationMinutes` when started from Shortcuts.
    @Published private(set) var plannedLength: TimeInterval = 0

    private let synth = BellSynth()
    private var timer: Timer?
    private var lastTick = Date()
    private var nextIntervalBell: TimeInterval?
    private var sleepActivity: NSObjectProtocol?
    private var sitStart: Date?
    private var focusStartsSit = false

    private init() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            Key.durationMinutes.rawValue: 20,
            Key.intervalMinutes.rawValue: 0,
            Key.preparationSeconds.rawValue: 10,
            Key.tone.rawValue: BellTone.bowl.rawValue,
            Key.volume.rawValue: 0.7,
            Key.remindersEnabled.rawValue: false,
            Key.reminderMinutes.rawValue: 45,
            Key.reminderRandomized.rawValue: true,
            Key.activeFromHour.rawValue: 9,
            Key.activeUntilHour.rawValue: 18,
            Key.startShortcutName.rawValue: "",
            Key.endShortcutName.rawValue: "",
        ])
        durationMinutes = defaults.integer(forKey: Key.durationMinutes.rawValue)
        intervalMinutes = defaults.integer(forKey: Key.intervalMinutes.rawValue)
        preparationSeconds = defaults.integer(forKey: Key.preparationSeconds.rawValue)
        tone = BellTone(rawValue: defaults.string(forKey: Key.tone.rawValue) ?? "") ?? .bowl
        volume = defaults.double(forKey: Key.volume.rawValue)
        remindersEnabled = defaults.bool(forKey: Key.remindersEnabled.rawValue)
        reminderMinutes = defaults.integer(forKey: Key.reminderMinutes.rawValue)
        reminderRandomized = defaults.bool(forKey: Key.reminderRandomized.rawValue)
        activeFromHour = defaults.integer(forKey: Key.activeFromHour.rawValue)
        activeUntilHour = defaults.integer(forKey: Key.activeUntilHour.rawValue)
        startShortcutName = defaults.string(forKey: Key.startShortcutName.rawValue) ?? ""
        endShortcutName = defaults.string(forKey: Key.endShortcutName.rawValue) ?? ""

        synth.prepare(tone)
        rescheduleReminder()
        updateTimer()
    }

    // MARK: Meditation session

    /// Starts a sit. `minutes` overrides the configured length for this sit only.
    func begin(minutes: Int? = nil) {
        guard phase == .idle else { return }
        plannedLength = TimeInterval(max(1, minutes ?? durationMinutes) * 60)
        isPaused = false
        elapsed = 0
        lastTick = Date()
        // Keep the Mac awake (and out of App Nap) so bells ring on time.
        sleepActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Meditation session in progress")
        if preparationSeconds > 0 {
            phase = .preparing
        } else {
            startSitting()
        }
        runShortcut(named: startShortcutName)
        updateTimer()
    }

    func togglePause() {
        guard phase != .idle else { return }
        isPaused.toggle()
        lastTick = Date()
    }

    func end(ringBell: Bool) {
        guard phase != .idle else { return }
        if ringBell { ring(strikes: 3) }
        if phase == .sitting, let start = sitStart {
            let sat = Int(min(elapsed, plannedLength))
            let completed = elapsed >= plannedLength
            // Sits cut short in the first minute aren't worth recording.
            if completed || sat >= 60 {
                HistoryStore.shared.record(Sit(start: start, seconds: sat,
                                               plannedSeconds: Int(plannedLength), completed: completed))
            }
        }
        runShortcut(named: endShortcutName)
        sitStart = nil
        phase = .idle
        isPaused = false
        elapsed = 0
        nextIntervalBell = nil
        if let activity = sleepActivity {
            ProcessInfo.processInfo.endActivity(activity)
            sleepActivity = nil
        }
        updateTimer()
    }

    private func startSitting() {
        phase = .sitting
        elapsed = 0
        sitStart = Date()
        nextIntervalBell = intervalMinutes > 0 ? TimeInterval(intervalMinutes * 60) : nil
        ring(strikes: 1)
    }

    func ring(strikes: Int = 1) {
        // Squared so the slider feels even across its range.
        synth.strike(tone, times: strikes, volume: Float(volume * volume))
    }

    // MARK: Display

    var remainingText: String {
        switch phase {
        case .idle: return Self.clock(TimeInterval(durationMinutes * 60))
        case .preparing: return Self.clock(TimeInterval(preparationSeconds) - elapsed)
        case .sitting: return Self.clock(plannedLength - elapsed)
        }
    }

    /// When the closing bell will ring if the sit isn't paused, or nil when idle.
    var expectedEnd: Date? {
        switch phase {
        case .idle: return nil
        case .preparing: return Date().addingTimeInterval(TimeInterval(preparationSeconds) - elapsed + plannedLength)
        case .sitting: return Date().addingTimeInterval(plannedLength - elapsed)
        }
    }

    var menuBarText: String? { phase == .idle ? nil : remainingText }

    var progress: Double {
        phase == .sitting && plannedLength > 0 ? min(1, elapsed / plannedLength) : 0
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds.rounded(.up)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    // MARK: Clock

    private func updateTimer() {
        let needed = phase != .idle || remindersEnabled
        if needed, timer == nil {
            lastTick = Date()
            let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
            t.tolerance = 0.1
            // .common so the clock keeps running while the menu is open.
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } else if !needed {
            timer?.invalidate()
            timer = nil
        }
    }

    private func tick() {
        let now = Date()
        let delta = now.timeIntervalSince(lastTick)
        lastTick = now

        switch phase {
        case .idle:
            break
        case .preparing:
            if !isPaused { elapsed += delta }
            if elapsed >= TimeInterval(preparationSeconds) { startSitting() }
        case .sitting:
            if !isPaused { elapsed += delta }
            if elapsed >= plannedLength {
                end(ringBell: true)
            } else if let next = nextIntervalBell, elapsed >= next {
                ring(strikes: 1)
                let following = next + TimeInterval(intervalMinutes * 60)
                // Don't ring an interval bell on top of the closing bell.
                nextIntervalBell = following < plannedLength - 1 ? following : nil
            }
        }

        if remindersEnabled, let next = nextReminder, now >= next {
            // Stay quiet during a sit or a silencing Focus, and skip bells that fell due while the Mac slept.
            if phase == .idle && !remindersSilencedByFocus
                && now.timeIntervalSince(next) < 120 {
                ring(strikes: 1)
            }
            rescheduleReminder()
        }
    }

    // MARK: Focus and Shortcuts

    /// Called by the Focus filter whenever a Focus with a Stillpoint filter turns on or off.
    func applyFocus(silenceReminders: Bool, startSit: Bool) {
        remindersSilencedByFocus = silenceReminders
        // Start only when the setting switches on, so later filter updates don't restart a finished sit.
        if startSit && !focusStartsSit { begin() }
        focusStartsSit = startSit
    }

    private func runShortcut(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [URLQueryItem(name: "name", value: trimmed)]
        if let url = components.url { NSWorkspace.shared.open(url) }
    }

    // MARK: Mindful day reminders

    private func rescheduleReminder() {
        guard remindersEnabled else {
            nextReminder = nil
            return
        }
        let base = TimeInterval(max(1, reminderMinutes) * 60)
        let gap = reminderRandomized ? base * Double.random(in: 0.5...1.5) : base
        nextReminder = firstActiveDate(onOrAfter: Date().addingTimeInterval(gap))
    }

    private func firstActiveDate(onOrAfter date: Date) -> Date {
        let calendar = Calendar.current
        if isActiveHour(calendar.component(.hour, from: date)) { return date }
        return calendar.nextDate(after: date,
                                 matching: DateComponents(hour: activeFromHour, minute: 0),
                                 matchingPolicy: .nextTime) ?? date
    }

    private func isActiveHour(_ hour: Int) -> Bool {
        if activeFromHour == activeUntilHour { return true }
        if activeFromHour < activeUntilHour {
            return hour >= activeFromHour && hour < activeUntilHour
        }
        return hour >= activeFromHour || hour < activeUntilHour
    }

    private func store(_ value: Any, _ key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }
}
