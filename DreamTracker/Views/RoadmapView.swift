import SwiftUI

// MARK: - Color Palette

extension Color {
    static let dreamBackground = Color(hex: "0A0A0A")
    static let dreamAccent     = Color(hex: "0A84FF")
    static let dreamSuccess    = Color(hex: "30D158")
    static let dreamSecondary  = Color(hex: "98989E")
    static let dreamSurface    = Color(hex: "141414")
}

// MARK: - Roadmap View (Tab 2: Timeline — The Future)

struct RoadmapView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var activeHorizon: TimeHorizon = .oneYear

    private let horizons: [TimeHorizon] = TimeHorizon.allCases

    // MARK: - Filtered Milestones

    private var filteredMilestones: [Milestone] {
        viewModel.milestones.filter { milestone in
            switch activeHorizon {
            case .sixMonths:
                return milestone.year == 1 && (milestone.quarter ?? 1) <= 2
            case .oneYear:
                return milestone.year == 1
            case .threeYears:
                return milestone.year <= 3
            case .fiveYears:
                return milestone.year <= 5
            case .tenYears:
                return true
            }
        }.sorted { a, b in
            if a.year != b.year { return a.year < b.year }
            return (a.quarter ?? 1) < (b.quarter ?? 1)
        }
    }

    private var completedCount: Int {
        filteredMilestones.filter(\.isCompleted).count
    }

    private var milestoneProgress: CGFloat {
        guard !filteredMilestones.isEmpty else { return 0 }
        return CGFloat(completedCount) / CGFloat(filteredMilestones.count)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.dreamBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ---- Header ----
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ---- Progress Bar ----
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // ---- Time Horizon Pills ----
                horizonPills
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // ---- Milestone Timeline ----
                milestoneTimeline
                    .padding(.horizontal, 20)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: activeHorizon)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Timeline")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("The Future — \(activeHorizon.label)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color.dreamSecondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: activeHorizon)
            }
            Spacer()

            // Compact status badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color.dreamSuccess)
                Text("\(completedCount)/\(filteredMilestones.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.dreamSurface)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    )
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: completedCount)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(.white.opacity(0.06))
                    .frame(height: 3)

                // Fill
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        milestoneProgress >= 1.0
                            ? AnyShapeStyle(Color.dreamSuccess)
                            : AnyShapeStyle(Color.dreamAccent)
                    )
                    .frame(width: max(0, geo.size.width * milestoneProgress), height: 3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: milestoneProgress)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Horizon Pills

    private var horizonPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(horizons) { horizon in
                    HorizonPill(
                        label: horizon.label,
                        isSelected: horizon == activeHorizon,
                        progress: progressForHorizon(horizon)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            activeHorizon = horizon
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    /// Returns the progress fraction (0–1) for a given horizon.
    private func progressForHorizon(_ horizon: TimeHorizon) -> CGFloat {
        let milestones = viewModel.milestones.filter { m in
            switch horizon {
            case .sixMonths: return m.year == 1 && (m.quarter ?? 1) <= 2
            case .oneYear:   return m.year == 1
            case .threeYears: return m.year <= 3
            case .fiveYears: return m.year <= 5
            case .tenYears:  return true
            }
        }
        guard !milestones.isEmpty else { return 0 }
        return CGFloat(milestones.filter(\.isCompleted).count) / CGFloat(milestones.count)
    }

    // MARK: - Milestone Timeline

    private var milestoneTimeline: some View {
        Group {
            if filteredMilestones.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredMilestones.enumerated()), id: \.element.id) { index, milestone in
                            TimelineRow(
                                milestone: milestone,
                                isLast: index == filteredMilestones.count - 1,
                                onToggle: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        viewModel.toggleMilestone(id: milestone.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .animation(.easeInOut(duration: 0.35), value: filteredMilestones.map(\.id))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Image(systemName: "trophy")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(.white.opacity(0.12))
            Text("No milestones for \(activeHorizon.label)\nTap + to add your first goal")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color.dreamSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Horizon Pill

private struct HorizonPill: View {
    let label: String
    let isSelected: Bool
    let progress: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color.dreamSecondary)

            // Subtle mini progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 18, height: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isSelected ? Color.dreamAccent : Color.dreamSuccess.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.dreamAccent.opacity(0.15) : Color.dreamSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isSelected ? Color.dreamAccent : .white.opacity(0.08),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Timeline Row

private struct TimelineRow: View {
    let milestone: Milestone
    let isLast: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // ---- LEFT: Year Badge + Connector ----
            VStack(spacing: 0) {
                // Year badge
                Text(yearBadgeText)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(milestone.isCompleted ? Color.dreamSuccess : Color.dreamSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(milestone.isCompleted
                                  ? Color.dreamSuccess.opacity(0.12)
                                  : .white.opacity(0.04))
                    )

                // Vertical connector line
                if !isLast {
                    Rectangle()
                        .fill(.white.opacity(0.06))
                        .frame(width: 0.5, height: 24)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 56)

            // ---- RIGHT: Content Card ----
            Button(action: onToggle) {
                HStack(spacing: 0) {
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(milestone.title)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(milestone.isCompleted ? Color.dreamSecondary : .white)
                            .strikethrough(milestone.isCompleted, color: Color.dreamSecondary.opacity(0.5))
                            .multilineTextAlignment(.leading)

                        if let completedAt = milestone.completedAt, milestone.isCompleted {
                            Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Color.dreamSuccess.opacity(0.7))
                        }
                    }

                    Spacer()

                    // Status dot / toggle
                    ZStack {
                        Circle()
                            .fill(milestone.isCompleted
                                  ? Color.dreamSuccess
                                  : .clear)
                            .frame(width: 22, height: 22)

                        Circle()
                            .stroke(milestone.isCompleted
                                    ? Color.dreamSuccess
                                    : .white.opacity(0.15),
                                    lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if milestone.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(milestone.isCompleted
                              ? Color.dreamSurface
                              : Color.dreamSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            milestone.isCompleted
                                ? Color.dreamSuccess.opacity(0.2)
                                : .white.opacity(0.04),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
        }
        .padding(.bottom, 4)
    }

    private var yearBadgeText: String {
        if let q = milestone.quarter {
            return "Y\(milestone.year) Q\(q)"
        }
        return "Y\(milestone.year)"
    }
}

// MARK: - Preview

#if DEBUG
struct RoadmapView_Previews: PreviewProvider {
    static var previews: some View {
        RoadmapView()
            .environmentObject(AppViewModel())
            .preferredColorScheme(.dark)
    }
}
#endif
