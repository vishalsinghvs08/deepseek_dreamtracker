import Foundation

public protocol APIRoute {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var requiresAuth: Bool { get }
    var requiresAppAttest: Bool { get }
}
