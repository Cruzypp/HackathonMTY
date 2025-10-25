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
}

struct Budget: Identifiable {
    let id = UUID()
    var name: String
    var total: Double
}
