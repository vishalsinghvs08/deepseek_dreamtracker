import Foundation

// MARK: - Core Data Models

public struct Goal: Codable, Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var why: String
    public var targetDate: Date
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        why: String = "",
        targetDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.why = why
        self.targetDate = targetDate ?? Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Milestone: Codable, Identifiable, Equatable {
    public let id: UUID
    public let goalID: UUID
    public var title: String
    public var year: Int
    public var quarter: Int?
    public var isCompleted: Bool
    public var completedAt: Date?
    public var order: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        goalID: UUID,
        title: String,
        year: Int,
        quarter: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.title = title
        self.year = year
        self.quarter = quarter
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.order = order
        self.createdAt = createdAt
    }
}

public struct Habit: Codable, Identifiable, Equatable {
    public let id: UUID
    public let goalID: UUID
    public var title: String
    public var isCompletedToday: Bool
    public var streakDays: Int
    public var lastCompletedAt: Date?
    public var createdAt: Date
    public var order: Int

    public init(
        id: UUID = UUID(),
        goalID: UUID,
        title: String,
        isCompletedToday: Bool = false,
        streakDays: Int = 0,
        lastCompletedAt: Date? = nil,
        createdAt: Date = Date(),
        order: Int = 0
    ) {
        self.id = id
        self.goalID = goalID
        self.title = title
        self.isCompletedToday = isCompletedToday
        self.streakDays = streakDays
        self.lastCompletedAt = lastCompletedAt
        self.createdAt = createdAt
        self.order = order
    }
}

public struct Reflection: Codable, Identifiable, Equatable {
    public let id: UUID
    public let goalID: UUID
    public var content: String
    public var promptType: PromptType
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        goalID: UUID,
        content: String,
        promptType: PromptType = .freeform,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.goalID = goalID
        self.content = content
        self.promptType = promptType
        self.createdAt = createdAt
    }
}

public enum PromptType: String, Codable, CaseIterable {
    case monthlyCheckin = "Monthly Check-in"
    case freeform = "Freeform"

    public var prompt: String {
        switch self {
        case .monthlyCheckin:
            return "What went well this month?\nWhat obstacles did you face?\nAre your daily habits still aligning with your 5-year goal?"
        case .freeform:
            return ""
        }
    }
}

// MARK: - Time Horizon (for the Time Dial)

public enum TimeHorizon: String, CaseIterable, Identifiable {
    case sixMonths = "6M"
    case oneYear = "1Y"
    case threeYears = "3Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"

    public var id: String { rawValue }

    public var label: String { rawValue }

    public var index: Int {
        switch self {
        case .sixMonths: return 0
        case .oneYear: return 1
        case .threeYears: return 2
        case .fiveYears: return 3
        case .tenYears: return 4
        }
    }

    public static func fromIndex(_ idx: Int) -> TimeHorizon {
        switch idx {
        case 0: return .sixMonths
        case 1: return .oneYear
        case 2: return .threeYears
        case 3: return .fiveYears
        default: return .tenYears
        }
    }
}

// MARK: - Default Data

public extension Goal {
    static let seedUUID = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

    static let defaultTemplate = Goal(
        id: seedUUID,
        title: "Build the life you've always imagined",
        why: "Deep down you know you're capable of more. This is your space to define what that looks like — and then go make it real, one day at a time.",
        targetDate: Calendar.current.date(byAdding: .year, value: 10, to: Date())!
    )

    static let defaultHabits: [Habit] = [
        Habit(goalID: seedUUID, title: "Morning routine", order: 0),
        Habit(goalID: seedUUID, title: "Deep work (2 hours)", order: 1),
        Habit(goalID: seedUUID, title: "Learn something new", order: 2),
        Habit(goalID: seedUUID, title: "Move your body", order: 3),
        Habit(goalID: seedUUID, title: "Evening reflection", order: 4)
    ]

    static let defaultMilestones: [Milestone] = [
        Milestone(goalID: seedUUID, title: "Define exactly what you want", year: 1, quarter: 1, order: 0),
        Milestone(goalID: seedUUID, title: "Build the foundation skills", year: 1, quarter: 2, order: 1),
        Milestone(goalID: seedUUID, title: "Ship your first version", year: 1, quarter: 3, order: 2),
        Milestone(goalID: seedUUID, title: "Get feedback from real people", year: 1, quarter: 4, order: 3),
        Milestone(goalID: seedUUID, title: "Double down on what works", year: 2, quarter: 1, order: 4),
        Milestone(goalID: seedUUID, title: "Reach 100 true fans", year: 2, quarter: 3, order: 5),
        Milestone(goalID: seedUUID, title: "Quit your day job", year: 3, quarter: 1, order: 6),
        Milestone(goalID: seedUUID, title: "Build a small team", year: 3, quarter: 3, order: 7),
        Milestone(goalID: seedUUID, title: "Achieve financial freedom", year: 5, quarter: 1, order: 8),
        Milestone(goalID: seedUUID, title: "Leave a lasting legacy", year: 10, quarter: 1, order: 9)
    ]
}
