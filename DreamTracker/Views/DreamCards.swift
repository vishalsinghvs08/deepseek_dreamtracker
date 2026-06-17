import SwiftUI

// MARK: - Parallel Lives Card

struct ParallelLivesCard: View {
    let story: LegendStory
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Text(story.emoji)
                    .font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("In \(story.timeframe.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(planetaryColor(story.timeframe))
                }
                Spacer()
                Text(story.timeframe.shortLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(planetaryColor(story.timeframe))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(planetaryColor(story.timeframe).opacity(0.15))
                    .clipShape(Capsule())
            }

            // Achievement
            Text(story.achievement)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            // Quote
            HStack(spacing: 0) {
                Rectangle()
                    .fill(planetaryColor(story.timeframe).opacity(0.5))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(story.quote)
                    .font(.callout)
                    .italic()
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(4)
                    .padding(.leading, 12)
            }
            .padding(.top, 12)
        }
        .padding(18)
        .cosmicSurface(level: .base, radius: 18)
        .scaleEffect(appeared ? 1 : 0.92)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                appeared = true
            }
        }
    }
}

// MARK: - Dream Pulse Ring

struct DreamPulseRing: View {
    let dreams: [Dream]
    @State private var appeared = false

    private var totalDreams: Int { dreams.count }
    private var completedDreams: Int { dreams.filter(\.isCompleted).count }

    var body: some View {
        HStack(spacing: 20) {
            // Center ring
            ZStack {
                // Background track
                ForEach(TimeHorizon.allCases.reversed(), id: \.id) { horizon in
                    let segmentFraction = 1.0 / Double(TimeHorizon.allCases.count)
                    let start = Double(TimeHorizon.allCases.firstIndex(of: horizon)!) * segmentFraction
                    let hDreams = dreams.filter { $0.horizon == horizon }
                    let hCompleted = hDreams.filter(\.isCompleted).count
                    let fillFraction = hDreams.isEmpty ? 0 : segmentFraction * Double(hCompleted) / Double(hDreams.count)

                    Circle()
                        .trim(from: start, to: start + fillFraction)
                        .stroke(planetaryColor(horizon), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .opacity(hDreams.isEmpty ? 0.1 : 1)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completedDreams)

                    // Empty track
                    Circle()
                        .trim(from: start, to: start + segmentFraction)
                        .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 6))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                }

                // Center count
                VStack(spacing: 0) {
                    Text("\(completedDreams)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("/\(totalDreams)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(TimeHorizon.allCases, id: \.id) { horizon in
                    let hDreams = dreams.filter { $0.horizon == horizon }
                    let hCompleted = hDreams.filter(\.isCompleted).count

                    HStack(spacing: 6) {
                        Circle()
                            .fill(planetaryColor(horizon))
                            .frame(width: 6, height: 6)
                        Text("\(horizon.shortLabel)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(hCompleted)/\(hDreams.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(16)
        .cosmicSurface(level: .base, radius: 18)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Dream Coach Insight Card

struct CoachInsightCard: View {
    let insight: DreamInsight
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            Text(insight.emoji)
                .font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(insight.body)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .cosmicSurface(level: .base, radius: 14)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Life Simulator Card

struct LifeSimulatorCard: View {
    let projection: LifeProjection
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("🔮 Your Future")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            HStack(spacing: 24) {
                statItem(value: "\(projection.projectedYear)", label: "Completion Year")
                statItem(value: String(format: "%.0f", projection.averageCompletionDays), label: "Avg Days/Dream")
                statItem(value: "\(projection.completedByThen)/\(projection.totalDreams)", label: "Total Done")
            }

            Text("\"\(projection.nextMilestone)\" is your next milestone. At your current pace, all dreams complete by \(projection.projectedYear).")
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
                .lineSpacing(3)
        }
        .padding(16)
        .cosmicSurface(level: .base, radius: 18)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                appeared = true
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.45))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.05, green: 0.02, blue: 0.18).ignoresSafeArea()
        VStack(spacing: 16) {
            ParallelLivesCard(story: ParallelLives.random(for: .threeYears, locale: .india))
            DreamPulseRing(dreams: Dream.seedDreams())
            CoachInsightCard(insight: DreamCoach.analyze(dreams: Dream.seedDreams(), entries: []).first!)
            LifeSimulatorCard(projection: LifeSimulator.project(dreams: Dream.seedDreams()))
        }
        .padding()
    }
}
