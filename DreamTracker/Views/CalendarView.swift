import SwiftUI

// MARK: - Calendar View (Life Calendar Heatmap)

struct CalendarView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    summarySection
                    heatmapSection
                    monthlyTimelineSection
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Life Calendar")
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Most Productive Horizon",
                    value: mostProductiveHorizon.shortLabel,
                    icon: "trophy.fill",
                    color: .orange
                )
                SummaryCard(
                    title: "Longest Streak",
                    value: "\(longestStreak) wk\(longestStreak == 1 ? "" : "s")",
                    icon: "flame.fill",
                    color: .red
                )
            }
            HStack(spacing: 12) {
                SummaryCard(
                    title: "Dreams This Year",
                    value: "\(dreamsCompletedThisYear)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                SummaryCard(
                    title: "Journal Entries",
                    value: "\(viewModel.journalEntries.count)",
                    icon: "book.pages.fill",
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity Heatmap")
                    .font(.headline)
                Spacer()
                legendView
            }
            .padding(.horizontal, 16)

            heatmapGrid
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal, 16)
        }
    }

    // MARK: Legend

    private var legendView: some View {
        HStack(spacing: 12) {
            LegendDot(color: .green.opacity(0.7), label: "Done")
            LegendDot(color: .blue.opacity(0.7), label: "Active")
            LegendDot(color: .purple.opacity(0.7), label: "Journal")
            LegendDot(color: Color(.systemGray5), label: "Idle")
        }
    }

    // MARK: Heatmap Grid

    private var heatmapGrid: some View {
        let weeks = buildWeeks()
        let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

        return LazyVGrid(columns: columns, spacing: 3) {
            // Day-of-week header
            ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                RoundedRectangle(cornerRadius: 3)
                    .fill(weekActivityColor(for: week))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
                    .help(weekTooltip(for: week))
            }
        }
        .padding(12)
    }

    // MARK: - Monthly Timeline Section

    private var monthlyTimelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Timeline")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            let months = buildMonthlyTimeline()
            if months.isEmpty {
                emptyTimelineView
            } else {
                ForEach(months, id: \.key) { month in
                    MonthTimelineCard(
                        monthLabel: month.key,
                        dreams: month.value.dreams,
                        entries: month.value.entries
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(.bottom, 32)
    }

    private var emptyTimelineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No activity yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Helpers

    /// Returns an array of (weekStartDate) sorted chronologically
    private func buildWeeks() -> [Date] {
        guard let earliest = earliestDate else { return [] }
        let calendar = Calendar.current
        let start = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: earliest)
        ) ?? earliest
        let end = Date()

        var weeks: [Date] = []
        var current = start
        while current <= end {
            weeks.append(current)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: current) else { break }
            current = next
        }
        return weeks
    }

    private var earliestDate: Date? {
        let dreamDates = viewModel.dreams.map { $0.createdAt }
        let entryDates = viewModel.journalEntries.map { $0.createdAt }
        let allDates = dreamDates + entryDates
        return allDates.min()
    }

    private func weekActivityColor(for weekStart: Date) -> Color {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return Color(.systemGray5)
        }
        let range = weekStart..<weekEnd

        let completedInWeek = viewModel.dreams.contains { dream in
            guard let completedAt = dream.completedAt, dream.isCompleted else { return false }
            return range.contains(completedAt)
        }
        if completedInWeek { return .green.opacity(0.7) }

        let createdInWeek = viewModel.dreams.contains { dream in
            range.contains(dream.createdAt)
        }
        if createdInWeek { return .blue.opacity(0.7) }

        let entryInWeek = viewModel.journalEntries.contains { entry in
            range.contains(entry.createdAt)
        }
        if entryInWeek { return .purple.opacity(0.7) }

        return Color(.systemGray5)
    }

    private func weekTooltip(for weekStart: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return "Week of \(df.string(from: weekStart))"
    }

    // MARK: - Summary Computations

    private var mostProductiveHorizon: TimeHorizon {
        let completed = viewModel.dreams.filter { $0.isCompleted }
        let grouped = Dictionary(grouping: completed, by: { $0.horizon })
        let best = grouped.max(by: { $0.value.count < $1.value.count })
        return best?.key ?? .sixMonths
    }

    private var longestStreak: Int {
        let calendar = Calendar.current
        let weeks = buildWeeks()
        guard !weeks.isEmpty else { return 0 }

        // Map each week to whether it had any activity
        let activityFlags: [Bool] = weeks.map { weekStart in
            guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return false
            }
            let range = weekStart..<weekEnd

            let hasCompleted = viewModel.dreams.contains { dream in
                guard let ca = dream.completedAt, dream.isCompleted else { return false }
                return range.contains(ca)
            }
            let hasCreated = viewModel.dreams.contains { range.contains($0.createdAt) }
            let hasEntry = viewModel.journalEntries.contains { range.contains($0.createdAt) }

            return hasCompleted || hasCreated || hasEntry
        }

        var maxStreak = 0
        var current = 0
        for active in activityFlags {
            if active {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
        }
        return maxStreak
    }

    private var dreamsCompletedThisYear: Int {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        return viewModel.dreams.filter { dream in
            guard let ca = dream.completedAt, dream.isCompleted else { return false }
            return calendar.component(.year, from: ca) == thisYear
        }.count
    }

    // MARK: - Monthly Timeline Data

    private func buildMonthlyTimeline() -> [(key: String, value: (dreams: [Dream], entries: [JournalEntry]))] {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"

        var months: [String: (dreams: [Dream], entries: [JournalEntry])] = [:]

        for dream in viewModel.dreams {
            let key = df.string(from: dream.createdAt)
            if months[key] == nil { months[key] = ([], []) }
            months[key]?.dreams.append(dream)
        }

        for entry in viewModel.journalEntries {
            let key = df.string(from: entry.createdAt)
            if months[key] == nil { months[key] = ([], []) }
            months[key]?.entries.append(entry)
        }

        // Sort by date descending (most recent first)
        return months.sorted { a, b in
            let dateA = df.date(from: a.key) ?? .distantPast
            let dateB = df.date(from: b.key) ?? .distantPast
            return dateA > dateB
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
}

// MARK: - Legend Dot

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Month Timeline Card

struct MonthTimelineCard: View {
    let monthLabel: String
    let dreams: [Dream]
    let entries: [JournalEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.08))
                )

            if !dreams.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Dreams", systemImage: "sparkles")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    ForEach(dreams) { dream in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(dream.isCompleted ? Color.green : Color.blue)
                                .frame(width: 8, height: 8)
                            Text(dream.title)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            HorizonBadge(horizon: dream.horizon)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }

            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Journal", systemImage: "book.pages")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    ForEach(entries.prefix(3)) { entry in
                        HStack(spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.purple)
                            Text(entry.content)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                    if entries.count > 3 {
                        Text("+\(entries.count - 3) more entries")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
        )
    }
}

// MARK: - Horizon Badge

struct HorizonBadge: View {
    let horizon: TimeHorizon

    var body: some View {
        Text(horizon.shortLabel)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(horizonColor)
            )
    }

    private var horizonColor: Color {
        switch horizon {
        case .sixMonths:  return .orange
        case .oneYear:    return .blue
        case .threeYears: return .green
        case .fiveYears:  return .purple
        case .tenYears:   return .red
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(AppViewModel())
}
