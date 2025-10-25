import SwiftUI

struct BudgetsSectionConnected: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @State private var showAddBudget = false

    var body: some View {
        Card {
            HStack {
                Text("Budgets").font(.headline)
                Spacer()
                Button {
                    showAddBudget = true
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).tint(SwiftFinColor.accentBlue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if ledger.budgets.isEmpty {
                    Text("No budgets set. Tap + to add one.").font(.subheadline)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                } else {
                    ForEach(ledger.budgets) { budget in
                        let used = ledger.usedForBudget(budget.name)
                        BudgetRow(name: budget.name, spent: used, total: budget.total)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddBudget) {
            AddBudgetSheet().presentationDetents([.fraction(0.3)])
        }
    }
}

struct BudgetRow: View {
    let name: String
    let spent: Double
    let total: Double

    var overBudget: Bool { spent > total }
    var remaining: Double { total - spent }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name).font(.subheadline)
                Spacer()
                Text(String(format: "$%.0f / $%.0f", spent, total))
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textSecondary)
            }

            // Progress Bar
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 8
                let progress = spent / total
                let spentW = min(w, w * progress)
                
                ZStack(alignment: .leading) {
                    // Fondo de la barra
                    RoundedRectangle(cornerRadius: h/2).fill(SwiftFinColor.surfaceAlt).frame(height: h)
                    
                    // Barra de progreso
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(overBudget ? SwiftFinColor.negativeRed : SwiftFinColor.positiveGreen)
                        .frame(width: spentW, height: h)
                    
                    // Indicador de presupuesto (línea blanca)
                    if progress < 1.0 {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: h + 4)
                            .position(x: w, y: h/2)
                            .opacity(0.6)
                    }
                }
            }
            .frame(height: 12)
            
            // Remaining/Over Text
            HStack {
                if overBudget {
                    Text(String(format: "$%.0f Over Budget", abs(remaining)))
                        .font(.caption).bold()
                        .foregroundStyle(SwiftFinColor.negativeRed)
                } else {
                    Text(String(format: "$%.0f Remaining", remaining))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
                Spacer()
            }
        }
    }
}
