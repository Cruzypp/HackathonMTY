import SwiftUI
import Charts

struct ReportsScreen: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @EnvironmentObject var monthSelector: MonthSelector
    @StateObject private var vm = ReportsViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Empty screen - content removed
        }
        .onAppear { vm.configure(ledger: ledger, monthSelector: monthSelector) }
    }
}

// MARK: - Previews
struct ReportsScreen_Previews: PreviewProvider {
    static var previews: some View {
        ReportsScreen()
            .environmentObject(PreviewMocks.ledger)
            .environmentObject(PreviewMocks.monthSelector)
            .previewDevice("iPhone 14")
            .preferredColorScheme(.dark)
    }
}
