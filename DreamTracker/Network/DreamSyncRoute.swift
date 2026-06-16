import Foundation

public enum DreamSyncRoute: APIRoute {
    case pullUpdates(since: Date)
    case pushUpdates(changes: [Dream])
    
    public var path: String {
        switch self {
        case .pullUpdates(let since):
            let formatter = ISO8601DateFormatter()
            let formattedDate = formatter.string(from: since)
            let encodedDate = formattedDate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? formattedDate
            return "dreams/sync?since=\(encodedDate)"
        case .pushUpdates:
            return "dreams/sync"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .pullUpdates:
            return .get
        case .pushUpdates:
            return .post
        }
    }
    
    public var headers: [String: String]? {
        return nil
    }
    
    public var body: Data? {
        switch self {
        case .pullUpdates:
            return nil
        case .pushUpdates(let changes):
            return try? JSONEncoder().encode(changes)
        }
    }
    
    public var requiresAuth: Bool {
        return true
    }
    
    public var requiresAppAttest: Bool {
        return true
    }
}
