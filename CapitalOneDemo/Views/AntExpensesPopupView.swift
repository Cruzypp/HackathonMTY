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
        VStack(spacing: 0) {
            Text("Micro-Spending Chat")
                .font(.title2).bold()
                .padding(.top, 12)
            ChatView(ledger: ledger)
                .frame(maxHeight: .infinity)
                .padding(.horizontal)
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
}
