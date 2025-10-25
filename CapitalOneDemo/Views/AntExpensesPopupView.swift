// Popup para mostrar gastos hormiga y estadísticas
import SwiftUI

struct AntExpensesPopupView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @StateObject var antVM = AntExpensesViewModel()
    @State private var selectedPeriod: Period = .month
    
    enum Period: String, CaseIterable, Identifiable {
        case day = "Diary"
        case week = "Semanal"
        case month = "Monthly"
        var id: String { rawValue }
    }
    
    var filteredExpenses: [Tx] {
        switch selectedPeriod {
        case .day:
            let today = Calendar.current.startOfDay(for: Date())
            return antVM.antExpenses.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return antVM.antExpenses.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return antVM.antExpenses.filter { $0.date >= monthAgo }
        }
    }
    
    var totalFiltered: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Section title in English
            Text("Micro-Spending Insights").font(.title2).bold()
            // Assistant section with ChatView
            VStack(alignment: .leading, spacing: 8) {
                Text("Assistant")
                    .font(.headline)
                Text("Here you will receive personalized advice and can talk about your spending.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ChatView()
                    .frame(height: 300)
            }
            .padding(.vertical, 8)

            // Period picker
            Picker("Period", selection: $selectedPeriod) {
                ForEach(Period.allCases) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Data section
            VStack(alignment: .leading, spacing: 8) {
                Text("Total: $\(totalFiltered, specifier: "%.2f")")
                    .font(.headline)
                Text("Potential savings (50%): $\(totalFiltered * 0.5, specifier: "%.2f")")
                    .font(.subheadline)
            }

            // List of micro-spending
            List(filteredExpenses) { tx in
                HStack {
                    Text(tx.title)
                    Spacer()
                    Text(String(format: "$%.2f", tx.amount))
                }
            }
            .frame(maxHeight: 200)

            Divider()

            // Future sections for planning
            VStack(alignment: .leading, spacing: 8) {
                Text("Other Insights")
                    .font(.headline)
                Text("- Category breakdown (e.g. Coffee, Snacks, Transport)")
                Text("- Spending trends (weekly, monthly)")
                Text("- Personalized tips and challenges")
                Text("- Voice assistant integration")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .onAppear {
            antVM.loadAntExpenses(from: ledger.transactions)
        }
    }
}
