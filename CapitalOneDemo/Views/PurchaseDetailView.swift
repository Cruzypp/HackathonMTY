import SwiftUI

struct PurchaseDetailView: View {
    let purchase: PurchaseDisplay
    // Wheel-style picker selection
    @State private var selectedCategory: String = ""
    @State private var originalCategory: String = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ledger: LedgerViewModel

    private let categories: [String] = [
        "-", "Groceries", "Transport", "Bills", "Shopping", "Dining",
        "Healthcare", "Travel", "Entertainment", "Education", "Other"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(purchase.merchantName)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(SwiftFinColor.textPrimary)
                    Text(purchase.date.formatted(date: .long, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(SwiftFinColor.textSecondary)
                }
                Spacer()
                Text(String(format: "-$%.2f", purchase.amount))
                    .font(.title2).bold()
                    .foregroundStyle(SwiftFinColor.negativeRed)
            }

            Divider()

            // Details
            VStack(alignment: .leading, spacing: 8) {
                RowDetail(label: "Account", value: purchase.accountAlias)
                RowDetail(label: "Place", value: purchase.merchantName)
                RowDetail(label: "Description", value: purchase.rawDescription)
                RowDetail(label: "Purchase ID", value: purchase.id)
            }

            Divider()

            // Category Picker (wheel style)
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                    .foregroundStyle(SwiftFinColor.textPrimary)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .pickerStyle(.wheel)
            }

            Spacer()

            // Confirm button
            Button(action: {
                CategoryStore.shared.setCategory(selectedCategory, for: purchase.id)
                // Update ledger transaction category if we can find it by purchaseId
                if let idx = ledger.transactions.firstIndex(where: { $0.purchaseId == purchase.id }) {
                    ledger.transactions[idx].category = selectedCategory
                }
                originalCategory = selectedCategory
                dismiss()
            }) {
                Text("Confirm Category")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedCategory == "-")
        }
        .padding()
        .background(SwiftFinColor.bgPrimary.ignoresSafeArea())
        .navigationTitle("Purchase")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let initial = purchase.selectedCategory ?? "-"
            selectedCategory = initial
            originalCategory = initial
        }
    }
}

private struct RowDetail: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(SwiftFinColor.textPrimary)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(SwiftFinColor.textPrimary)
        }
    }
}

#Preview {
    let sample = PurchaseDisplay(
        id: "p1",
        merchantName: "Amazon México",
        accountAlias: "BBVA Oro",
        accountId: "acc1",
        amount: 1599,
        date: Date(),
        rawDescription: "Compra de audífonos inalámbricos",
        selectedCategory: "Shopping"
    )
    return NavigationStack { PurchaseDetailView(purchase: sample) }
        .environmentObject(PreviewMocks.monthSelector)
        .environmentObject(PreviewMocks.ledger)
}

// No helpers needed for wheel picker
