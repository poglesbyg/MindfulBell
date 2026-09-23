import Foundation

/// Screenshot mode: sample history and Pro unlocked, without touching the real history file
/// or StoreKit. Turn it on with the `-StillpointDemo YES` launch argument (a disabled entry
/// is already in the scheme). Debug builds only, so the App Store build can never enter it.
enum Demo {
    #if DEBUG
    static let isEnabled = UserDefaults.standard.bool(forKey: "StillpointDemo")
    #else
    static let isEnabled = false
    #endif

    /// About ten weeks of plausible practice, newest first. Seeded, so every launch shows
    /// the same history: a current streak of about three weeks, a two-week streak before
    /// a short break, and patchier practice before that.
    static func sits(now: Date = Date()) -> [Sit] {
        var rng = SplitMix64(seed: 2026)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        var sits: [Sit] = []

        for daysAgo in 0..<72 {
            let practised: Bool
            switch daysAgo {
            case 0..<23: practised = true
            case 23..<26: practised = false
            case 26..<40: practised = true
            default: practised = Double.random(in: 0..<1, using: &rng) < 0.55
            }
            guard practised, let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }

            let weekend = calendar.isDateInWeekend(day)
            let planned = weekend ? [30, 30, 45].randomElement(using: &rng)!
                                  : [15, 20, 20, 20, 25].randomElement(using: &rng)!
            let morning = (weekend ? 8 * 60 : 6 * 60 + 30) + Int.random(in: 0..<40, using: &rng)
            sits.append(sit(on: day, minuteOfDay: morning, plannedMinutes: planned, rng: &rng))

            // Some evenings, a short second sit.
            if Double.random(in: 0..<1, using: &rng) < 0.2 {
                let evening = 21 * 60 + Int.random(in: 0..<45, using: &rng)
                sits.append(sit(on: day, minuteOfDay: evening, plannedMinutes: 10, rng: &rng))
            }
        }

        // Leave out anything later today than the current time.
        return sits.filter { $0.start <= now }.sorted { $0.start > $1.start }
    }

    private static func sit(on day: Date, minuteOfDay: Int, plannedMinutes: Int,
                            rng: inout SplitMix64) -> Sit {
        let start = Calendar.current.date(byAdding: .minute, value: minuteOfDay, to: day)!
        let planned = plannedMinutes * 60
        // About one sit in twelve ends early.
        let endedEarly = Double.random(in: 0..<1, using: &rng) < 0.08
        let seconds = endedEarly ? Int(Double(planned) * Double.random(in: 0.4...0.8, using: &rng)) : planned
        return Sit(start: start, seconds: seconds, plannedSeconds: planned, completed: !endedEarly)
    }
}

/// Small deterministic generator (SplitMix64), so demo data is identical on every launch.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
