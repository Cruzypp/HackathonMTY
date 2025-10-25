import Foundation

// MARK: - Models
struct Tx: Identifiable {
    enum Kind { case expense, income }
    let id = UUID()
    var date: Date
    var title: String
    var category: String
    var amount: Double    // absolute value
    var kind: Kind
    var accountId: String? // Link to Account.id for filtering by type
    var purchaseId: String? = nil // Link to API purchase id to sync user category
}

struct Budget: Identifiable {
    let id = UUID()
    var name: String
    var total: Double
}
