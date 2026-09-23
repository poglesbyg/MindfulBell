import Foundation

struct Sit: Codable, Identifiable, Hashable {
    var id = UUID()
    /// When the opening bell rang.
    var start: Date
    /// Time actually sat, excluding pauses.
    var seconds: Int
    var plannedSeconds: Int
    var completed: Bool
}

struct DayTotal: Identifiable {
    var date: Date
    var minutes: Double
    var id: Date { date }
}

/// Every recorded sit, kept as JSON in the app's Application Support folder.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    /// Newest first.
    @Published private(set) var sits: [Sit] = []

    private let url: URL
    private let calendar = Calendar.current

    private init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            // Named for the app's original title; kept so existing history isn't orphaned.
            .appendingPathComponent("Mindful Bell", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        url = folder.appendingPathComponent("history.json")
        if Demo.isEnabled {
            sits = Demo.sits()
            NSLog("Stillpoint: demo mode, showing sample history; history.json is not read or written")
        } else {
            load()
        }
    }

    func record(_ sit: Sit) {
        sits.insert(sit, at: 0)
        save()
    }

    func delete(_ ids: Set<Sit.ID>) {
        sits.removeAll { ids.contains($0.id) }
        save()
    }

    // MARK: Statistics

    func seconds(since date: Date) -> Int {
        sits.filter { $0.start >= date }.reduce(0) { $0 + $1.seconds }
    }

    var todaySeconds: Int { seconds(since: calendar.startOfDay(for: Date())) }

    /// Today and the six days before it.
    var weekSeconds: Int {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date()))!
        return seconds(since: start)
    }

    var totalSeconds: Int { sits.reduce(0) { $0 + $1.seconds } }

    /// Consecutive days with at least one sit, ending today, or yesterday if today has none yet.
    var currentStreak: Int {
        let days = sitDays
        var day = calendar.startOfDay(for: Date())
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while days.contains(day) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var longestStreak: Int {
        var longest = 0
        var run = 0
        var previous: Date?
        for day in sitDays.sorted() {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            previous = day
        }
        return longest
    }

    /// Minutes sat on each of the last `days` days, oldest first, including days with none.
    func dailyTotals(days: Int) -> [DayTotal] {
        let today = calendar.startOfDay(for: Date())
        var totals: [Date: Int] = [:]
        for sit in sits {
            totals[calendar.startOfDay(for: sit.start), default: 0] += sit.seconds
        }
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayTotal(date: day, minutes: Double(totals[day] ?? 0) / 60)
        }
    }

    private var sitDays: Set<Date> {
        Set(sits.map { calendar.startOfDay(for: $0.start) })
    }

    static func durationText(_ seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds / 60)m"
    }

    // MARK: Storage

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            sits = try decoder.decode([Sit].self, from: data).sorted { $0.start > $1.start }
        } catch {
            // Keep an unreadable file rather than overwriting it on the next save.
            let stamp = Int(Date().timeIntervalSince1970)
            let aside = url.deletingLastPathComponent().appendingPathComponent("history-unreadable-\(stamp).json")
            try? FileManager.default.moveItem(at: url, to: aside)
            NSLog("MindfulBell: history unreadable, moved to \(aside.path): \(error)")
        }
    }

    private func save() {
        // Demo sits (and any sat during a demo) stay in memory, away from the real history.
        guard !Demo.isEnabled else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            try encoder.encode(sits).write(to: url, options: .atomic)
        } catch {
            NSLog("MindfulBell: could not save history: \(error)")
        }
    }
}
