import SwiftUI

/// Add New Expense
struct AddExpenseSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerViewModel
    
    @State private var title: String = ""
    @State private var amount: Double? = nil
    @State private var category: String = "Food"
    
    let categories = ["Food", "Transport", "Bills", "Entertainment", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Description (e.g., Coffee)", text: $title)
                    TextField("Amount (USD)", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = amount, amount > 0, !title.isEmpty {
                            ledger.addExpense(title: title, category: category, amount: amount)
                            dismiss()
                        }
                    }
                    .disabled(amount == nil || amount! <= 0 || title.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Add New Income
struct AddIncomeSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerViewModel
    
    @State private var title: String = ""
    @State private var amount: Double? = nil
    @State private var category: String = "Salary"
    
    let categories = ["Salary", "Freelance", "Investment", "Gift", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Source (e.g., Monthly Paycheck)", text: $title)
                    TextField("Amount (USD)", value: $amount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("New Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let amount = amount, amount > 0, !title.isEmpty {
                            ledger.addIncome(title: title, category: category, amount: amount)
                            dismiss()
                        }
                    }
                    .disabled(amount == nil || amount! <= 0 || title.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Add New Budget
struct AddBudgetSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ledger: LedgerViewModel
    
    @State private var name: String = ""
    @State private var total: Double? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name (e.g., Groceries, Rent)", text: $name)
                    TextField("Monthly Limit (USD)", value: $total, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("New Budget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let total = total, total > 0, !name.isEmpty {
                            ledger.addBudget(name: name, total: total)
                            dismiss()
                        }
                    }
                    .disabled(total == nil || total! <= 0 || name.isEmpty)
                    .bold()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
