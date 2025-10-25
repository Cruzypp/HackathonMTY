import Foundation

// Simple account model to represent bank accounts and credit cards
struct AccountModel: Identifiable, Codable, Equatable {
    enum AccountType: String, Codable {
        case bank
        case creditCard
    }

    let id: UUID
    var name: String
    var type: AccountType
    /// For bank accounts: current available balance. For credit cards: current amount owed (positive = owed) or 0.
    var balance: Double
    /// For credit cards: maximum credit limit
    var creditLimit: Double?

    init(id: UUID = UUID(), name: String, type: AccountType = .bank, balance: Double = 0, creditLimit: Double? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.creditLimit = creditLimit
    }
}

// A planned purchase to simulate
struct PlannedPurchase {
    var id = UUID()
    var accountId: UUID
    var amount: Double
    var date: Date = Date()
    /// months for "Meses sin intereses" (0 = pago al contado)
    var msiMonths: Int = 0
    var title: String?
}

// Monthly projected balance point
struct ProjectedPoint: Identifiable {
    let id = UUID()
    var date: Date
    var balanceByAccount: [UUID: Double]
}

struct MonthlyPayment: Identifiable {
    let id = UUID()
    var monthStart: Date
    var totalPayment: Double
    var breakdown: [UUID: Double] // accountId -> payment
}

struct SimulationResult {
    var projected: [ProjectedPoint]
    var monthlyPayments: [MonthlyPayment]
    var alerts: [String]
    /// 0 (safe) ... 100 (high risk)
    var riskIndex: Int
}
