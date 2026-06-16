import Foundation

public enum Secrets {
    public static var backendURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "BACKEND_URL") as? String,
              let url = URL(string: urlString) else {
            return URL(string: "https://api.dreamtracker.com")!
        }
        return url
    }
    
    public static let keychainService = "com.dreamtracker.app.secure-store"
}
