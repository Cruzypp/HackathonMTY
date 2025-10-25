// Pantalla para mostrar gastos hormiga y simulador de ahorro
import SwiftUI

struct AntExpensesView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @StateObject var antVM = AntExpensesViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gastos Hormiga").font(.title2).bold()
            Text("Total: $\(antVM.totalAntExpenses, specifier: "%.2f")")
                .font(.headline)
            List(antVM.antExpenses) { tx in
                HStack {
                    Text(tx.title)
                    Spacer()
                    Text("$\(tx.amount, specifier: "%.2f")")
                }
            }
            Divider()
            Text("Simulador de ahorro")
                .font(.headline)
            HStack {
                Text("Ahorro potencial (50%):")
                Spacer()
                Text("$\(antVM.simulatedSavings(reductionPercent: 50), specifier: "%.2f")")
            }
        }
        .padding()
        .onAppear {
            antVM.loadAntExpenses(from: ledger.transactions)
        }
    }
}
