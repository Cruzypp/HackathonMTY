import SwiftUI

struct RecentTransactions: View {
    let title: String
    let rows: [Tx]
    var onViewAll: (() -> Void)? = nil

    var body: some View {
        Card {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let onViewAll {
                    Button("View All >", action: onViewAll)
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
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
            Text("Recent Expenses").font(.headline)
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
            Text("Recent Income").font(.headline)
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
                Circle().fill(SwiftFinColor.surfaceAlt).frame(width: 34, height: 34)
                Image(systemName: icon)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(SwiftFinColor.textSecondary)
            }
            Spacer()
            Text(String(format: "%@$%.2f", amount < 0 ? "−" : "+", abs(amount)))
                .foregroundStyle(amount < 0 ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
        }
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
