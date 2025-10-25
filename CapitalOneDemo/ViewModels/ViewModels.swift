// Resumen financiero para IA y contexto
struct FinancialSummary {
    let totalBalance: Double
    let totalAntExpenses: Double
    let topCategories: [String]
    let recentTransactions: [Tx]
}

extension LedgerViewModel {
    func financialSummary() -> FinancialSummary? {
        guard !accounts.isEmpty else { return nil }
        let totalBalance = accounts.reduce(0) { $0 + $1.balance }
    // Ejemplo: gastos hormiga son transacciones menores a $100 y de tipo 'expense'
    let antExpenses = transactions.filter { $0.amount < 100 && $0.kind == .expense }
        let totalAntExpenses = antExpenses.reduce(0) { $0 + $1.amount }
        let categories = Dictionary(grouping: antExpenses, by: { $0.category })
        let topCategories = categories.keys.sorted { categories[$0]!.count > categories[$1]!.count }
        return FinancialSummary(
            totalBalance: totalBalance,
            totalAntExpenses: totalAntExpenses,
            topCategories: Array(topCategories.prefix(3)),
            recentTransactions: Array(transactions.prefix(5))
        )
    }
}
import Foundation
import SwiftUI
import Combine

// MARK: - Month Selector ViewModel
final class MonthSelector: ObservableObject {
    @Published var selectedDate: Date = Date()

    var currentMonthYear: String {
        selectedDate.formatted(.dateTime.month().year())
    }

    var monthInterval: DateInterval {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year,.month], from: selectedDate))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        return DateInterval(start: start, end: end)
    }

    func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)!
    }

    func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)!
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
}


// MARK: - Ledger ViewModel (formerly LedgerStore)
final class LedgerViewModel: ObservableObject {
    // Suma de saldos de cuentas checking (mock: suma de ingresos menos gastos si no hay cuentas reales)
    var checkingBalanceThisMonth: Double {
        // Si tienes cuentas reales, aquí deberías sumar solo las de tipo "checking".
        // Por ahora, igualamos a netThisMonth para mantenerlo funcional.
        // Si tienes un array de cuentas, reemplaza esta lógica por la suma de balances de cuentas checking.
        return netThisMonth
    }
    // Injected dependency
    @ObservedObject var monthSelector: MonthSelector

    // Listener for Combine
    private var cancellables = Set<AnyCancellable>()

    // Published Data
    @Published var transactions: [Tx] = [
        .init(date: .now, title: "Groceries", category: "Food", amount: 48.2, kind: .expense, accountId: nil),
        .init(date: .now, title: "Metro", category: "Transport", amount: 12, kind: .expense, accountId: nil),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*3)), title: "Salary", category: "Salary", amount: 3200, kind: .income, accountId: nil),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*10)), title: "Upwork", category: "Freelance", amount: 380, kind: .income, accountId: nil),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*5)), title: "Electric Bill", category: "Bills", amount: 450, kind: .expense, accountId: nil),
        .init(date: .now.addingTimeInterval(TimeInterval(-86400*6)), title: "Dinner", category: "Food", amount: 420, kind: .expense, accountId: nil),
    ]

    @Published var budgets: [Budget] = [
        .init(name: "Rent", total: 900),
        .init(name: "Entertainment", total: 600),
        .init(name: "Groceries", total: 700)
    ]

    // New: Hold all accounts for mapping accountId to type
    @Published var accounts: [Account] = []

    // Initializer to receive the dependency
    init(monthSelector: MonthSelector) {
        self.monthSelector = monthSelector

        // Configure listener to force updates when month changes
        monthSelector.$selectedDate
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // Convenience
    private var selectedMonthInterval: DateInterval { monthSelector.monthInterval }

    // Filters
    var expensesThisMonth: [Tx] {
        transactions.filter { $0.kind == .expense && selectedMonthInterval.contains($0.date) }
    }
    var incomeThisMonth: [Tx] {
        transactions.filter { $0.kind == .income && selectedMonthInterval.contains($0.date) }
    }

    // Totals
    var totalSpentThisMonth: Double { expensesThisMonth.reduce(0) { $0 + $1.amount } }
    var totalIncomeThisMonth: Double { incomeThisMonth.reduce(0) { $0 + $1.amount } }
    var netThisMonth: Double { totalIncomeThisMonth - totalSpentThisMonth }

    // Mutations
    func addExpense(title: String, category: String, amount: Double, date: Date = .now, accountId: String? = nil) {
        transactions.append(.init(date: date, title: title, category: category, amount: amount, kind: .expense, accountId: accountId))
    }
    func addIncome(title: String, category: String, amount: Double, date: Date = .now, accountId: String? = nil) {
        transactions.append(.init(date: date, title: title, category: category, amount: amount, kind: .income, accountId: accountId))
    }
    func addBudget(name: String, total: Double) {
        budgets.append(.init(name: name, total: total))
    }

    // Breakdowns
    func spentByCategoryThisMonth() -> [(name: String, amount: Double)] {
        let grouped = Dictionary(grouping: expensesThisMonth, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.amount > $1.amount }
    }
    func usedForBudget(_ name: String) -> Double {
        expensesThisMonth.filter { $0.category == name || ($0.category == "Food" && name == "Groceries") }
            .reduce(0) { $0 + $1.amount }
    }
}
