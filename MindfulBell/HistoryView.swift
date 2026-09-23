import Charts
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var history: HistoryStore
    @State private var selection = Set<Sit.ID>()
    @State private var hoveredDay: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            stats
            chart
            sitList
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 540)
    }

    // MARK: Headline numbers

    private var stats: some View {
        HStack(spacing: 12) {
            StatTile(title: "Current streak", value: days(history.currentStreak))
            StatTile(title: "Longest streak", value: days(history.longestStreak))
            StatTile(title: "Last 7 days", value: HistoryStore.durationText(history.weekSeconds))
            StatTile(title: "All time", value: HistoryStore.durationText(history.totalSeconds))
        }
    }

    private func days(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }

    // MARK: Last 30 days

    private var chart: some View {
        let totals = history.dailyTotals(days: 30)
        let hovered = totals.first { $0.date == hoveredDay }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Minutes per day, last 30 days").font(.headline)
                Spacer()
                if let hovered {
                    // Hover readout sits in the header so it never covers the bars.
                    (Text(hovered.date, format: .dateTime.weekday(.abbreviated).month().day())
                        + Text("  \(Int(hovered.minutes.rounded())) min").bold())
                        .font(.callout)
                        .monospacedDigit()
                }
            }
            Chart(totals) { day in
                BarMark(x: .value("Day", day.date, unit: .day),
                        y: .value("Minutes", day.minutes))
                    .foregroundStyle(Color.accentColor.opacity(hoveredDay == nil || hoveredDay == day.date ? 1 : 0.45))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                    .accessibilityLabel(Text(day.date, format: .dateTime.month().day()))
                    .accessibilityValue(Text("\(Int(day.minutes.rounded())) minutes"))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(.quaternary)
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                guard let plot = proxy.plotFrame else { return }
                                let x = location.x - geometry[plot].origin.x
                                if let date: Date = proxy.value(atX: x) {
                                    hoveredDay = Calendar.current.startOfDay(for: date)
                                }
                            case .ended:
                                hoveredDay = nil
                            }
                        }
                }
            }
            .frame(height: 150)
        }
    }

    // MARK: Individual sits

    @ViewBuilder
    private var sitList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sits").font(.headline)
            if history.sits.isEmpty {
                ContentUnavailableView("No sits yet", systemImage: "bell",
                                       description: Text("Sits of a minute or more appear here."))
                    .frame(maxHeight: .infinity)
            } else {
                List(selection: $selection) {
                    ForEach(history.sits) { sit in
                        SitRow(sit: sit)
                    }
                }
                .contextMenu(forSelectionType: Sit.ID.self) { ids in
                    Button("Delete", role: .destructive) { history.delete(ids) }
                        .disabled(ids.isEmpty)
                }
                .onDeleteCommand {
                    history.delete(selection)
                    selection.removeAll()
                }
            }
        }
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SitRow: View {
    let sit: Sit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sit.start, format: .dateTime.weekday(.wide).month(.wide).day())
                Text(sit.start, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !sit.completed {
                Text("ended early")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(HistoryStore.durationText(sit.seconds))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
