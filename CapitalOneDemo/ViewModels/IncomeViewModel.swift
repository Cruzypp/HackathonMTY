import Foundation
import Combine

final class IncomeViewModel: ObservableObject {
    private(set) var ledger: LedgerViewModel?
    private var cancellables = Set<AnyCancellable>()

    func configure(ledger: LedgerViewModel, monthSelector: MonthSelector) {
        guard self.ledger == nil else { return }
        self.ledger = ledger
        ledger.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var totalIncomeThisMonth: Double { ledger?.totalIncomeThisMonth ?? 0 }
    var incomeThisMonth: [Tx] { ledger?.incomeThisMonth ?? [] }
}
