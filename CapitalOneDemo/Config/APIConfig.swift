import Foundation

enum APIConfig {
    static var apiKey: String {
        // Read from Info.plist which gets value from xcconfig
        guard let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !key.isEmpty else {
            // Fallback to hardcoded if not in build settings
            return "65dfb406dc064d7c9e638642279e62ff"
        }
        return key
    }
    
    static let baseURL = "https://api.nessieisreal.com"
}
