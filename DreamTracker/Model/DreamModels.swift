import Foundation

// MARK: - Time Horizon

public enum TimeHorizon: String, CaseIterable, Identifiable, Codable {
    case sixMonths  = "6 Months"
    case oneYear    = "1 Year"
    case threeYears = "3 Years"
    case fiveYears  = "5 Years"
    case tenYears   = "10 Years"

    public var id: String { rawValue }

    public var shortLabel: String {
        switch self {
        case .sixMonths:  return "6M"
        case .oneYear:    return "1Y"
        case .threeYears: return "3Y"
        case .fiveYears:  return "5Y"
        case .tenYears:   return "10Y"
        }
    }
}

// MARK: - Dream

public struct Dream: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var notes: String
    public var horizon: TimeHorizon
    public var isCompleted: Bool
    public var completedAt: Date?
    public var order: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        horizon: TimeHorizon,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.horizon = horizon
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.order = order
        self.createdAt = createdAt
    }
}

// MARK: - Journal Entry

public struct JournalEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public var content: String
    public var createdAt: Date

    public init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - Default Seed Data

public extension Dream {
    static func seedDreams() -> [Dream] {
        [
            Dream(title: "Run a marathon", horizon: .sixMonths),
            Dream(title: "Read 12 books this year", horizon: .oneYear),
            Dream(title: "Launch my own business", horizon: .threeYears),
            Dream(title: "Achieve financial independence", horizon: .fiveYears),
            Dream(title: "Build a lasting legacy", horizon: .tenYears),
        ]
    }
}
