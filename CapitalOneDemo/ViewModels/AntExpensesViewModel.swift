// ViewModel para gastos hormiga y simulador de ahorro
import Foundation
import Combine

final class AntExpensesViewModel: ObservableObject {
    @Published var antExpenses: [Tx] = []
    @Published var totalAntExpenses: Double = 0

    // Criterios de gastos hormiga
    let antCategories = ["Café", "Snacks", "Uber", "Comida rápida", "Refrescos"]
    let maxAmount = 50.0

    func loadAntExpenses(from transactions: [Tx]) {
        antExpenses = transactions.filter {
            $0.kind == .expense &&
            $0.amount <= maxAmount &&
            antCategories.contains($0.category)
        }
        totalAntExpenses = antExpenses.reduce(0) { $0 + $1.amount }
    }

    func simulatedSavings(reductionPercent: Double) -> Double {
        return totalAntExpenses * reductionPercent / 100.0
    }
}
