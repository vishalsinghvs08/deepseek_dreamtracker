import SwiftUI

// MARK: - Calendar View (Life Calendar Heatmap — Cosmic Glassmorphism)

struct CalendarView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var showCards = false

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicNebula()
                    .ignoresSafeArea()

                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        summarySection
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 20)

                        // Dream Coach insights
                        coachInsightsSection
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .opacity(showCards ? 1 : 0)

                        // Life Simulator projection
                        lifeSimulatorSection
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .opacity(showCards ? 1 : 0)

                        heatmapSection
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 16)
                        monthlyTimelineSection
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 12)
                    }
                }
            }
            .navigationTitle("Life Calendar")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.05)) {
                showCards = true
            }
        }
    }

    // MARK: - Star Field Background

    private var starField: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince1970
                let starCount = 80

                for i in 0..<starCount {
                    // Deterministic pseudo-random positions from seed + index
                    let seed = Double(42 + i * 31)
                    let x = (sin(seed * 12.9898 + now * 0.02) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 78.233 + now * 0.015) * 0.5 + 0.5) * size.height

                    // Twinkle based on time
                    let twinkle = abs(sin(now * 1.3 + Double(i) * 2.7)) * 0.5 + 0.3
                    let baseSize: CGFloat = CGFloat(i % 3 == 0 ? 2.5 : 1.2)
                    let starSize = baseSize * twinkle

                    let starRect = CGRect(
                        x: x - starSize / 2,
                        y: y - starSize / 2,
                        width: starSize,
                        height: starSize
                    )
                    let starPath = Path(ellipseIn: starRect)
                    context.fill(starPath, with: .color(.white.opacity(twinkle * 0.55)))
                }
            }
        }
    }

    // MARK: - Coach Insights

    private var coachInsightsSection: some View {
        let insights = DreamCoach.analyze(dreams: viewModel.dreams, entries: viewModel.journalEntries)
        return Group {
            if !insights.isEmpty {
                VStack(spacing: 8) {
                    ForEach(insights) { insight in
                        CoachInsightCard(insight: insight)
                    }
                }
            }
        }
    }

    private var lifeSimulatorSection: some View {
        LifeSimulatorCard(projection: LifeSimulator.project(dreams: viewModel.dreams))
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StaggeredSummaryCard(
                    title: "Most Productive Horizon",
                    value: mostProductiveHorizon.shortLabel,
                    icon: planetaryIcon(mostProductiveHorizon),
                    color: planetaryColor(mostProductiveHorizon),
                    delay: 0.0
                )
                StaggeredSummaryCard(
                    title: "Longest Streak",
                    value: "\(longestStreak) wk\(longestStreak == 1 ? "" : "s")",
                    icon: "flame.fill",
                    color: Color(red: 0.95, green: 0.55, blue: 0.25),
                    delay: 0.1
                )
            }
            HStack(spacing: 12) {
                StaggeredSummaryCard(
                    title: "Dreams This Year",
                    value: "\(dreamsCompletedThisYear)",
                    icon: "checkmark.circle.fill",
                    color: Color(red: 0.25, green: 0.75, blue: 0.55),
                    delay: 0.2
                )
                StaggeredSummaryCard(
                    title: "Journal Entries",
                    value: "\(viewModel.journalEntries.count)",
                    icon: "book.pages.fill",
                    color: Color(red: 0.35, green: 0.30, blue: 0.75),
                    delay: 0.3
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
                    .foregroundColor(.white)
                Spacer()
                legendView
            }
            .padding(.horizontal, 16)

            heatmapGrid
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 16)
        }
    }

    // MARK: Legend

    private var legendView: some View {
        HStack(spacing: 12) {
            LegendDot(color: planetaryColor(.oneYear).opacity(0.8), label: "Completed")
            LegendDot(color: planetaryColor(.sixMonths).opacity(0.8), label: "Active")
            LegendDot(color: planetaryColor(.tenYears).opacity(0.8), label: "Journal")
            LegendDot(color: .white.opacity(0.08), label: "Idle")
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
                    .foregroundColor(.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                RoundedRectangle(cornerRadius: 3)
                    .fill(weekActivityColor(for: week))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(.white.opacity(0.06), lineWidth: 0.5)
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
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            let months = buildMonthlyTimeline()
            if months.isEmpty {
                emptyTimelineView
            } else {
                ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                    MonthTimelineCard(
                        monthLabel: month.key,
                        dreams: month.value.dreams,
                        entries: month.value.entries
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .opacity(showCards ? 1 : 0)
                    .offset(y: showCards ? 0 : 8)
                    .animation(
                        .easeOut(duration: 0.4).delay(0.15 + Double(index) * 0.06),
                        value: showCards
                    )
                }
            }
        }
        .padding(.bottom, 32)
    }

    private var emptyTimelineView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(.white.opacity(0.3))
            Text("No activity yet")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
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

    /// Colors each heatmap cell based on the planetaryColor of dreams in that week
    private func weekActivityColor(for weekStart: Date) -> Color {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return .white.opacity(0.06)
        }
        let range = weekStart..<weekEnd

        // Completed dreams — use their horizon's planetaryColor at full glow
        let completedInWeek = viewModel.dreams.filter { dream in
            guard let completedAt = dream.completedAt, dream.isCompleted else { return false }
            return range.contains(completedAt)
        }
        if let firstCompleted = completedInWeek.first {
            return planetaryColor(firstCompleted.horizon).opacity(0.85)
        }

        // Active (created but not completed) dreams
        let createdInWeek = viewModel.dreams.filter { dream in
            range.contains(dream.createdAt) && !dream.isCompleted
        }
        if let firstCreated = createdInWeek.first {
            return planetaryColor(firstCreated.horizon).opacity(0.55)
        }

        // Journal entries — use Jupiter/tenYears indigo as the "reflection" color
        let entryInWeek = viewModel.journalEntries.contains { entry in
            range.contains(entry.createdAt)
        }
        if entryInWeek {
            return planetaryColor(.tenYears).opacity(0.6)
        }

        return .white.opacity(0.06)
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

// MARK: - Staggered Summary Card

struct StaggeredSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let delay: Double

    @State private var visible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 16)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                visible = true
            }
        }
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
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Month Timeline Card (Frosted Glass + Colored Left Accent)

struct MonthTimelineCard: View {
    let monthLabel: String
    let dreams: [Dream]
    let entries: [JournalEntry]

    /// Pick a dominant planetaryColor from the dreams for the left accent
    private var accentColor: Color {
        if let first = dreams.first {
            return planetaryColor(first.horizon)
        }
        // Journal-only months get the Jupiter/reflection indigo
        return planetaryColor(.tenYears)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                // Month label
                Text(monthLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                    )

                // Dreams
                if !dreams.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Dreams", systemImage: "sparkles")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))

                        ForEach(dreams) { dream in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(dream.isCompleted
                                        ? planetaryColor(dream.horizon)
                                        : planetaryColor(dream.horizon).opacity(0.45))
                                    .frame(width: 8, height: 8)
                                Text(dream.title)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Spacer()
                                HorizonBadge(horizon: dream.horizon)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.05))
                            )
                        }
                    }
                }

                // Journal entries
                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Journal", systemImage: "book.pages")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))

                        ForEach(entries.prefix(3)) { entry in
                            HStack(spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(planetaryColor(.tenYears).opacity(0.7))
                                Text(entry.content)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.white.opacity(0.05))
                            )
                        }
                        if entries.count > 3 {
                            Text("+\(entries.count - 3) more entries")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.06), lineWidth: 0.5)
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
                    .fill(planetaryColor(horizon))
            )
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .environmentObject(AppViewModel())
}
