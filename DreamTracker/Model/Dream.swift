import Foundation

public struct Dream: Codable, Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var content: String
    public var date: Date
    public var lucidityScore: Int
    public var isLucid: Bool
    public var tags: [String]
    public var updatedAt: Date
    public var isDeleted: Bool
    public var isPendingSync: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        date: Date = Date(),
        lucidityScore: Int,
        isLucid: Bool,
        tags: [String] = [],
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        isPendingSync: Bool = true
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.lucidityScore = lucidityScore
        self.isLucid = isLucid
        self.tags = tags
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.isPendingSync = isPendingSync
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, date, lucidityScore, isLucid, tags, updatedAt, isDeleted, isPendingSync
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        date = try container.decode(Date.self, forKey: .date)
        lucidityScore = try container.decode(Int.self, forKey: .lucidityScore)
        isLucid = try container.decode(Bool.self, forKey: .isLucid)
        tags = try container.decode([String].self, forKey: .tags)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        isDeleted = try container.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
        isPendingSync = try container.decodeIfPresent(Bool.self, forKey: .isPendingSync) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(date, forKey: .date)
        try container.encode(lucidityScore, forKey: .lucidityScore)
        try container.encode(isLucid, forKey: .isLucid)
        try container.encode(tags, forKey: .tags)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isDeleted, forKey: .isDeleted)
        try container.encode(isPendingSync, forKey: .isPendingSync)
    }
}
