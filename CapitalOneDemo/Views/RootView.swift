import SwiftUI

struct SwiftFinRoot: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @State private var topTab: TopTab = .overview

    var body: some View {
        NavigationStack {
            ZStack {
                SwiftFinColor.bgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    Header()
                    TopSegmentedControl(selection: $topTab)

                    // Content card
                    ScrollView {
                        VStack(spacing: 16) {
                            switch topTab {
                            case .overview: OverviewScreen()
                            case .expenses: ExpensesScreen()
                            case .income:   IncomeScreen()
                            case .reports:  ReportsScreen()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .foregroundStyle(SwiftFinColor.textPrimary)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SimulationView()) {
                        Image(systemName: "cart.badge.plus")
                    }
                }
            }
        }
    }
}

// MARK: - Previews
struct SwiftFinRoot_Previews: PreviewProvider {
    static var previews: some View {
        SwiftFinRoot()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
