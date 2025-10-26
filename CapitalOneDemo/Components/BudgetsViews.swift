import SwiftUI

struct BudgetsSectionConnected: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @State private var showAddBudget = false

    var body: some View {
        Card {
            HStack {
                Text("Budgets")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textDark) // Blanco
                Spacer()
                Button {
                    showAddBudget = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(SwiftFinColor.capitalOneRed)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if ledger.budgets.isEmpty {
                    Text("No budgets set. Tap + to add one.")
                        .font(.subheadline)
                        .foregroundStyle(SwiftFinColor.textDarkSecondary) // Gris claro
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(SwiftFinColor.textDark) // Blanco
                Spacer()
                Text(String(format: "$%.0f / $%.0f", spent, total))
                    .font(.subheadline)
                    .foregroundStyle(SwiftFinColor.textDarkSecondary) // Gris claro
            }

            // Progress Bar con efecto glass
            GeometryReader { geo in
                let w = geo.size.width
                let h: CGFloat = 10
                let progress = spent / total
                let spentW = min(w, w * progress)
                
                ZStack(alignment: .leading) {
                    // Fondo de la barra con efecto glass
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(SwiftFinColor.surfaceAlt.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: h/2)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.1), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .frame(height: h)
                    
                    // Barra de progreso con gradiente
                    RoundedRectangle(cornerRadius: h/2)
                        .fill(
                            LinearGradient(
                                colors: overBudget ? 
                                    [SwiftFinColor.negativeRed, Color(hex: "#B91C1C")] :
                                    [SwiftFinColor.positiveGreen, Color(hex: "#00695C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: h/2)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .frame(width: spentW, height: h)
                        .shadow(
                            color: overBudget ? 
                                SwiftFinColor.negativeRed.opacity(0.3) :
                                SwiftFinColor.positiveGreen.opacity(0.3),
                            radius: 4,
                            y: 2
                        )
                    
                    // Indicador de presupuesto (línea blanca con glow)
                    if progress < 1.0 {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 2, height: h + 4)
                            .position(x: w, y: h/2)
                            .opacity(0.8)
                            .shadow(color: .white.opacity(0.5), radius: 2)
                    }
                }
            }
            .frame(height: 14)
            
            // Remaining/Over Text
            HStack {
                if overBudget {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(String(format: "$%.0f Over Budget", abs(remaining)))
                            .font(.caption)
                            .bold()
                    }
                    .foregroundStyle(SwiftFinColor.negativeRed)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text(String(format: "$%.0f Remaining", remaining))
                            .font(.caption)
                    }
                    .foregroundStyle(SwiftFinColor.textDarkSecondary) // Gris claro para card oscura
                }
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F9FAFB"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#E5E7EB"), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
