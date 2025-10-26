import Foundation

/// Simple persistence for user-selected categories per purchase
final class CategoryStore {
    static let shared = CategoryStore()
    private init() {}

    private let prefix = "purchaseCategory."

    func getCategory(for purchaseId: String) -> String? {
        UserDefaults.standard.string(forKey: prefix + purchaseId)
    }

    func setCategory(_ category: String?, for purchaseId: String) {
        let key = prefix + purchaseId
        if let category, !category.isEmpty {
            UserDefaults.standard.set(category, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
