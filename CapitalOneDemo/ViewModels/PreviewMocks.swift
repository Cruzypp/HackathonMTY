import Foundation
import SwiftUI

/// Preview helpers: create a shared sample ledger and month selector so previews can run
enum PreviewMocks {
    static var monthSelector: MonthSelector {
        let ms = MonthSelector()
        return ms
    }

    static var ledger: LedgerViewModel {
        let ms = monthSelector
        let vm = LedgerViewModel(monthSelector: ms)

        // Clear default sample data and add deterministic sample items
        vm.transactions = [
            Tx(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, title: "Coffee at Cafe", category: "Food", amount: 4.5, kind: .expense),
            Tx(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, title: "Grocery Store", category: "Food", amount: 78.2, kind: .expense),
            Tx(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, title: "Salary", category: "Salary", amount: 3200, kind: .income),
            Tx(date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, title: "Freelance", category: "Freelance", amount: 380, kind: .income),
        ]

        vm.budgets = [
            Budget(name: "Food", total: 300),
            Budget(name: "Transport", total: 120),
        ]

        return vm
    }

    static var sampleAccounts: [AccountModel] {
        [
            AccountModel(name: "Cuenta Cheques", type: .bank, balance: 2400.0, creditLimit: nil),
            AccountModel(name: "Tarjeta Principal", type: .creditCard, balance: 200.0, creditLimit: 3000.0),
        ]
    }
}
