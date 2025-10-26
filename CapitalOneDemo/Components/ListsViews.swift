import SwiftUI

struct RecentTransactions: View {
    let title: String
    let rows: [Tx]
    var onViewAll: (() -> Void)? = nil

    var body: some View {
        Card {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark) // Blanco para card oscura
                Spacer()
                if let onViewAll {
                    Button("View All >", action: onViewAll)
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.capitalOneRed)
                }
            }
            VStack(spacing: 10) {
                ForEach(rows) { tx in
                    RowTx(icon: tx.kind == .expense ? "arrow.down.circle" : "arrow.up.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: tx.kind == .expense ? -tx.amount : tx.amount)
                }
            }
        }
    }
}

struct RecentExpenses: View {
    @EnvironmentObject var ledger: LedgerViewModel
    var body: some View {
        Card {
            Text("Recent Expenses")
                .font(.headline)
                .foregroundStyle(SwiftFinColor.textDark) // Blanco
            VStack(spacing: 10) {
                ForEach(ledger.expensesThisMonth.sorted { $0.date > $1.date }.prefix(4)) { tx in
                    RowTx(icon: "arrow.down.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: -tx.amount)
                }
            }
        }
    }
}

struct RecentIncome: View {
    @EnvironmentObject var ledger: LedgerViewModel
    var body: some View {
        Card {
            Text("Recent Income")
                .font(.headline)
                .foregroundStyle(SwiftFinColor.textDark) // Blanco
            VStack(spacing: 10) {
                ForEach(ledger.incomeThisMonth.sorted { $0.date > $1.date }.prefix(3)) { tx in
                    RowTx(icon: "arrow.up.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: tx.amount)
                }
            }
        }
    }
}

struct RowTx: View {
    let icon: String
    let title: String
    let subtitle: String
    let amount: Double
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SwiftFinColor.surfaceAlt.opacity(0.8), SwiftFinColor.surface.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(
                        amount < 0 ? 
                            SwiftFinColor.negativeRed : 
                            SwiftFinColor.positiveGreen
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(SwiftFinColor.textDark) // Blanco
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(SwiftFinColor.textDarkSecondary) // Gris claro
            }
            
            Spacer()
            
            Text(String(format: "%@$%.2f", amount < 0 ? "−" : "+", abs(amount)))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(amount < 0 ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
        }
        .padding(.vertical, 4)
    }
}

struct ViewAllExpensesView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ledger.expensesThisMonth.sorted { $0.date > $1.date }) { tx in
                    RowTx(icon: "arrow.down.circle",
                          title: tx.title,
                          subtitle: tx.category + " · " + tx.date.formatted(date: .abbreviated, time: .omitted),
                          amount: -tx.amount)
                }
                .listRowBackground(SwiftFinColor.surface) // dark list background
            }
            .navigationTitle("All Expenses")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .listStyle(.plain)
            .background(SwiftFinColor.bgPrimary.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
}
