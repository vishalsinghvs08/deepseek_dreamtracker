import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case all = "All"
    }

    private var activeDreams: [Dream] {
        viewModel.dreams.filter { !$0.isDeleted }
    }

    private var filteredDreams: [Dream] {
        let now = Date()
        switch selectedPeriod {
        case .week:
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            return activeDreams.filter { $0.date >= cutoff }
        case .month:
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: now)!
            return activeDreams.filter { $0.date >= cutoff }
        case .all:
            return activeDreams
        }
    }

    private var lucidCount: Int { filteredDreams.filter { $0.isLucid }.count }
    private var avgLucidity: Double {
        guard !filteredDreams.isEmpty else { return 0 }
        return Double(filteredDreams.map { $0.lucidityScore }.reduce(0, +)) / Double(filteredDreams.count)
    }
    private var streakDays: Int {
        // Count consecutive days with at least one dream
        guard !activeDreams.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        let dreamDays = Set(activeDreams.map { Calendar.current.startOfDay(for: $0.date) })
        while dreamDays.contains(checkDate) {
            streak += 1
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return streak
    }

    // Group dreams by day for chart
    private var dreamsByDay: [(date: Date, count: Int, lucidCount: Int)] {
        let calendar = Calendar.current
        var grouped: [Date: (Int, Int)] = [:]
        for dream in filteredDreams {
            let day = calendar.startOfDay(for: dream.date)
            let existing = grouped[day] ?? (0, 0)
            grouped[day] = (existing.0 + 1, existing.1 + (dream.isLucid ? 1 : 0))
        }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, count: $0.value.0, lucidCount: $0.value.1) }
    }

    // Mood distribution
    private var moodDistribution: [(score: Int, count: Int)] {
        (1...5).map { score in
            (score: score, count: filteredDreams.filter { $0.lucidityScore == score }.count)
        }
    }

    // Top tags
    private var topTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        for dream in filteredDreams {
            for tag in dream.tags { tagCounts[tag, default: 0] += 1 }
        }
        return tagCounts.sorted { $0.value > $1.value }.prefix(6).map { (tag: $0.key, count: $0.value) }
    }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.10).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Analytics")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Insights from your dream journal")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Period picker
                    HStack(spacing: 4) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Button {
                                withAnimation(.spring(response: 0.3)) { selectedPeriod = period }
                            } label: {
                                Text(period.rawValue)
                                    .font(.system(size: 13, weight: selectedPeriod == period ? .semibold : .regular))
                                    .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .background(
                                        selectedPeriod == period
                                        ? Color(red: 0.5, green: 0.3, blue: 0.9)
                                        : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 20)

                    // Stat cards row
                    HStack(spacing: 12) {
                        StatCard(value: "\(filteredDreams.count)", label: "Dreams", icon: "moon.fill", color: Color(red: 0.5, green: 0.3, blue: 0.9))
                        StatCard(value: "\(lucidCount)", label: "Lucid", icon: "sparkles", color: Color(red: 0.3, green: 0.5, blue: 0.9))
                        StatCard(value: String(format: "%.1f", avgLucidity), label: "Avg Score", icon: "chart.bar.fill", color: Color(red: 0.2, green: 0.6, blue: 0.7))
                        StatCard(value: "\(streakDays)d", label: "Streak", icon: "flame.fill", color: Color(red: 0.9, green: 0.5, blue: 0.2))
                    }
                    .padding(.horizontal, 20)

                    // Dream frequency chart
                    if !dreamsByDay.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DREAM FREQUENCY")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(1.5)

                            Chart {
                                ForEach(dreamsByDay, id: \.date) { entry in
                                    BarMark(
                                        x: .value("Date", entry.date, unit: .day),
                                        y: .value("Dreams", entry.count)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 0.5, green: 0.3, blue: 0.9), Color(red: 0.3, green: 0.4, blue: 0.9)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .cornerRadius(4)

                                    if entry.lucidCount > 0 {
                                        BarMark(
                                            x: .value("Date", entry.date, unit: .day),
                                            y: .value("Lucid", entry.lucidCount)
                                        )
                                        .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 1.0).opacity(0.7))
                                        .cornerRadius(4)
                                    }
                                }
                            }
                            .frame(height: 140)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day, count: max(1, dreamsByDay.count / 5))) { _ in
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                                        .foregroundStyle(Color.white.opacity(0.4))
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                        .foregroundStyle(Color.white.opacity(0.4))
                                    AxisGridLine()
                                        .foregroundStyle(Color.white.opacity(0.06))
                                }
                            }

                            // Legend
                            HStack(spacing: 16) {
                                LegendItem(color: Color(red: 0.5, green: 0.3, blue: 0.9), label: "Total Dreams")
                                LegendItem(color: Color(red: 0.8, green: 0.6, blue: 1.0), label: "Lucid Dreams")
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 20)
                    }

                    // Lucidity distribution
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LUCIDITY DISTRIBUTION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                            .tracking(1.5)

                        VStack(spacing: 10) {
                            ForEach(moodDistribution.reversed(), id: \.score) { item in
                                let maxCount = moodDistribution.map { $0.count }.max() ?? 1
                                HStack(spacing: 10) {
                                    HStack(spacing: 3) {
                                        ForEach(0..<item.score, id: \.self) { _ in
                                            Circle()
                                                .fill(scoreColor(item.score))
                                                .frame(width: 7, height: 7)
                                        }
                                        ForEach(0..<(5 - item.score), id: \.self) { _ in
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(width: 7, height: 7)
                                        }
                                    }
                                    .frame(width: 55, alignment: .leading)

                                    GeometryReader { geo in
                                        let barWidth = maxCount > 0 ? (CGFloat(item.count) / CGFloat(maxCount)) * geo.size.width : 0
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.06))
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(scoreColor(item.score).opacity(0.8))
                                                .frame(width: max(barWidth, item.count > 0 ? 4 : 0))
                                        }
                                    }
                                    .frame(height: 18)

                                    Text("\(item.count)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 24, alignment: .trailing)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 20)

                    // Top tags
                    if !topTags.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("TOP THEMES")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(1.5)

                            let maxTagCount = topTags.map { $0.count }.max() ?? 1
                            VStack(spacing: 8) {
                                ForEach(topTags, id: \.tag) { item in
                                    HStack(spacing: 10) {
                                        Text("#\(item.tag)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 1.0))
                                            .frame(width: 90, alignment: .leading)
                                            .lineLimit(1)

                                        GeometryReader { geo in
                                            let barWidth = (CGFloat(item.count) / CGFloat(maxTagCount)) * geo.size.width
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white.opacity(0.06))
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color(red: 0.5, green: 0.3, blue: 0.9), Color(red: 0.3, green: 0.4, blue: 0.9)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: max(barWidth, 4))
                                            }
                                        }
                                        .frame(height: 18)

                                        Text("\(item.count)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.5))
                                            .frame(width: 24, alignment: .trailing)
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(.horizontal, 20)
                    }

                    // Empty state
                    if filteredDreams.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40, weight: .thin))
                                .foregroundColor(.white.opacity(0.2))
                            Text("No data for this period.\nStart recording dreams to see insights!")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 5: return Color(red: 0.5, green: 0.3, blue: 0.9)
        case 4: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case 3: return Color(red: 0.2, green: 0.6, blue: 0.7)
        case 2: return Color(red: 0.6, green: 0.5, blue: 0.3)
        default: return Color(red: 0.5, green: 0.3, blue: 0.4)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
