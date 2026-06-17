import Foundation

// MARK: - Dream Coach — Pattern analysis & insights engine

struct DreamInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let body: String
    let emoji: String

    enum InsightType { case strength, weakness, pattern, suggestion, celebration }
}

enum DreamCoach {
    /// Analyzes dream patterns and produces 1-4 insights
    static func analyze(dreams: [Dream], entries: [JournalEntry]) -> [DreamInsight] {
        var insights: [DreamInsight] = []

        let completed = dreams.filter(\.isCompleted)
        _ = dreams.filter { !$0.isCompleted }
        guard !dreams.isEmpty else { return [] }

        // 1. Horizon completion rate
        for horizon in TimeHorizon.allCases {
            let hDreams = dreams.filter { $0.horizon == horizon }
            let hCompleted = hDreams.filter(\.isCompleted).count
            if !hDreams.isEmpty && hCompleted == hDreams.count {
                insights.append(DreamInsight(
                    type: .celebration,
                    title: "\(horizon.shortLabel) Horizon Clear!",
                    body: "You've completed every dream in your \(horizon.rawValue.lowercased()) horizon. Time to set your next big vision.",
                    emoji: "🎉"
                ))
            }
        }

        // 2. Short-term vs long-term completion pattern
        let shortTerm = dreams.filter { $0.horizon == .sixMonths || $0.horizon == .oneYear }
        let longTerm = dreams.filter { $0.horizon == .fiveYears || $0.horizon == .tenYears }
        let shortRate = shortTerm.isEmpty ? 0 : Double(shortTerm.filter(\.isCompleted).count) / Double(shortTerm.count)
        let longRate = longTerm.isEmpty ? 0 : Double(longTerm.filter(\.isCompleted).count) / Double(longTerm.count)

        if shortRate > 0.6 && longRate < 0.2 && !shortTerm.isEmpty && !longTerm.isEmpty {
            insights.append(DreamInsight(
                type: .pattern,
                title: "Sprint Champion",
                body: "You're great at short-term goals (\(Int(shortRate*100))% completion) but your long-term dreams need attention (\(Int(longRate*100))%). Try decomposing a 5Y dream into smaller milestones.",
                emoji: "🏃"
            ))
        }

        // 3. Neglected horizon
        for horizon in TimeHorizon.allCases {
            let hDreams = dreams.filter { $0.horizon == horizon }
            if !hDreams.isEmpty && hDreams.filter(\.isCompleted).isEmpty {
                let oldest = hDreams.min(by: { $0.createdAt < $1.createdAt })
                if let oldest, Date().timeIntervalSince(oldest.createdAt) > 30 * 24 * 3600 {
                    insights.append(DreamInsight(
                        type: .suggestion,
                        title: "\(horizon.shortLabel) Dreams Need You",
                        body: "Your \(horizon.rawValue.lowercased()) dreams haven't seen progress in over a month. Pick one small step you can take today.",
                        emoji: "⏰"
                    ))
                }
                break
            }
        }

        // 4. Most productive horizon
        if let best = TimeHorizon.allCases.max(by: { a, b in
            let aRate = dreams.filter({ $0.horizon == a }).isEmpty ? 0 :
                Double(dreams.filter({ $0.horizon == a && $0.isCompleted }).count) / Double(dreams.filter({ $0.horizon == a }).count)
            let bRate = dreams.filter({ $0.horizon == b }).isEmpty ? 0 :
                Double(dreams.filter({ $0.horizon == b && $0.isCompleted }).count) / Double(dreams.filter({ $0.horizon == b }).count)
            return aRate < bRate
        }), dreams.filter({ $0.horizon == best && $0.isCompleted }).count > 0 {
            insights.append(DreamInsight(
                type: .strength,
                title: "Your Superpower: \(best.shortLabel)",
                body: "Your \(best.rawValue.lowercased()) goals have the highest completion rate. This is your sweet spot — set ambitious dreams here.",
                emoji: "💪"
            ))
        }

        // 5. Reflection consistency
        if entries.count >= 3 {
            insights.append(DreamInsight(
                type: .strength,
                title: "Reflection Habit",
                body: "You've written \(entries.count) journal entries. Regular reflection is the #1 predictor of long-term goal achievement.",
                emoji: "📝"
            ))
        } else if completed.count >= 3 {
            insights.append(DreamInsight(
                type: .suggestion,
                title: "Capture Your Journey",
                body: "You're achieving dreams! Try journaling about what's working — it'll help you replicate your success at bigger horizons.",
                emoji: "✍️"
            ))
        }

        // 6. Decomposition opportunity
        let bigDreams = dreams.filter { ($0.horizon == .fiveYears || $0.horizon == .tenYears) && !$0.isCompleted }
        if !bigDreams.isEmpty {
            insights.append(DreamInsight(
                type: .suggestion,
                title: "Break It Down",
                body: "You have \(bigDreams.count) big dream\(bigDreams.count > 1 ? "s" : "") waiting. Long-press a 5Y or 10Y dream and tap 'Decompose' to break it into achievable steps.",
                emoji: "🔀"
            ))
        }

        return Array(insights.prefix(4))
    }
}

// MARK: - Life Simulator — Future projection

struct LifeProjection {
    let currentYear: Int
    let projectedYear: Int
    let completedByThen: Int
    let totalDreams: Int
    let averageCompletionDays: Double
    let nextMilestone: String
}

enum LifeSimulator {
    /// Projects when you'll achieve your dreams at current pace
    static func project(dreams: [Dream]) -> LifeProjection {
        let completed = dreams.filter(\.isCompleted)
        let active = dreams.filter { !$0.isCompleted }
        let currentYear = Calendar.current.component(.year, from: Date())

        // Calculate average days to complete a dream
        var totalDays: Double = 0
        var count = 0
        for dream in completed {
            if let done = dream.completedAt {
                let days = done.timeIntervalSince(dream.createdAt) / 86400
                totalDays += days
                count += 1
            }
        }
        let avgDays = count > 0 ? totalDays / Double(count) : 90.0 // default: 90 days

        // Project completion dates
        let remainingDreams = active.count
        let totalDaysNeeded = avgDays * Double(remainingDreams)
        let projectedDate = Date().addingTimeInterval(totalDaysNeeded * 86400)
        let projectedYear = Calendar.current.component(.year, from: projectedDate)

        // Total completed by projected year
        let completedByThen = completed.count + remainingDreams

        // Next milestone
        let nextDream = active.min(by: { $0.createdAt < $1.createdAt })
        let nextMilestone = nextDream?.title ?? "Your next dream"

        return LifeProjection(
            currentYear: currentYear,
            projectedYear: projectedYear,
            completedByThen: completedByThen,
            totalDreams: dreams.count,
            averageCompletionDays: avgDays,
            nextMilestone: nextMilestone
        )
    }
}
