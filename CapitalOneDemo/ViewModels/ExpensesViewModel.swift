import Foundation
import Combine

final class ExpensesViewModel: ObservableObject {
    private(set) var ledger: LedgerViewModel?
    private var cancellables = Set<AnyCancellable>()

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { return }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var totalSpentThisMonth: Double { ledger?.totalSpentThisMonth ?? 0 }
    var budgets: [Budget] { ledger?.budgets ?? [] }
    func spentByCategoryThisMonth() -> [(name: String, amount: Double)] { ledger?.spentByCategoryThisMonth() ?? [] }
    func usedForBudget(_ name: String) -> Double { ledger?.usedForBudget(name) ?? 0 }
}
