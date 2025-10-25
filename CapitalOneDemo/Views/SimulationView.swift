import SwiftUI

struct SimulationView: View {
    @EnvironmentObject var ledger: LedgerViewModel
    @StateObject private var vm = SimulationViewModel()

    @State private var selectedAccountId: UUID?
    @State private var amountText: String = ""
    @State private var msiMonths: Int = 0
    @State private var result: SimulationResult?
    @State private var customerIdText: String = ""
    @State private var apiKeyText: String = ""
    @State private var isLoadingAccounts: Bool = false
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Simulador de Compra Futura").font(.title2).bold()

                // Account picker
                VStack(alignment: .leading) {
                    Text("Nessie: cargar cuentas reales")
                    HStack {
                        TextField("customer id", text: $customerIdText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("api key", text: $apiKeyText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Button(action: {
                            loadError = nil
                            isLoadingAccounts = true
                            vm.fetchAccountsFromNessie(customerId: customerIdText, apiKey: apiKeyText) { res in
                                isLoadingAccounts = false
                                switch res {
                                case .success(let accounts):
                                    if let first = accounts.first { selectedAccountId = first.id }
                                case .failure(let err):
                                    loadError = String(describing: err)
                                }
                            }
                        }) {
                            if isLoadingAccounts { ProgressView().scaleEffect(0.8) }
                            else { Text("Cargar cuentas") }
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            // quick load from environment if present
                            if let envKey = ProcessInfo.processInfo.environment["NESSIE_KEY"] {
                                apiKeyText = envKey
                            }
                        }) {
                            Text("Usar NESSIE_KEY env")
                        }
                        .buttonStyle(.bordered)
                    }
                    if let e = loadError { Text(e).foregroundColor(.red).font(.caption) }
                    
                    // Credentials management buttons
                    if AuthStore.shared.isLoggedIn {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Sesión activa")
                            Spacer()
                            Button(action: {
                                AuthStore.shared.deleteApiKey()
                                AuthStore.shared.deleteCustomerId()
                                AccountStore.shared.clear()
                                apiKeyText = ""
                                customerIdText = ""
                                vm.accounts = []
                                selectedAccountId = nil
                                result = nil
                            }) {
                                Text("Cerrar sesión")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 6)
                    } else if !customerIdText.isEmpty && !apiKeyText.isEmpty {
                        Button(action: {
                            AuthStore.shared.saveApiKey(apiKeyText)
                            AuthStore.shared.saveCustomerId(customerIdText)
                        }) {
                            Text("💾 Guardar credenciales")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }

                // Account picker
                VStack(alignment: .leading) {
                    Text("Seleccionar cuenta")
                    Picker("Cuenta", selection: Binding(get: {
                        selectedAccountId ?? vm.accounts.first?.id
                    }, set: { new in selectedAccountId = new })) {
                        ForEach(vm.accounts) { acc in
                            Text(acc.name).tag(acc.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Amount
                VStack(alignment: .leading) {
                    Text("Monto de la compra")
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // MSI
                VStack(alignment: .leading) {
                    Text("Meses sin intereses (MSI)")
                    Stepper(value: $msiMonths, in: 0...36) {
                        Text("\(msiMonths) meses")
                    }
                }

                Button(action: runSimulation) {
                    Text("Simular compra")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if let res = result {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Índice de estabilidad:")
                            Spacer()
                            Text("\(res.riskIndex) / 100")
                        }
                        ProgressView(value: Double(res.riskIndex), total: 100)

                        if !res.alerts.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Alertas:").bold()
                                ForEach(res.alerts, id: \.self) { a in
                                    Text("• \(a)")
                                }
                            }
                        }

                        Text("Proyección mensual (saldo por cuenta)").bold()
                        ForEach(res.projected) { p in
                            VStack(alignment: .leading) {
                                Text(DateFormatter.localizedString(from: p.date, dateStyle: .medium, timeStyle: .none))
                                    .font(.caption)
                                ForEach(vm.accounts) { acc in
                                    let bal = p.balanceByAccount[acc.id] ?? 0
                                    HStack {
                                        Text(acc.name).font(.subheadline)
                                        Spacer()
                                        Text(String(format: "$%.2f", bal))
                                            .foregroundColor(bal < 0 ? .red : .primary)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .onAppear {
            vm.configure(ledger: ledger)
            // load cached accounts and refresh if we have stored credentials
            vm.loadCachedAndMaybeRefresh()

            // If stored auth exists, prefill the fields and set selected account
            if let api = AuthStore.shared.readApiKey() {
                apiKeyText = api
            }
            if let cid = AuthStore.shared.readCustomerId() {
                customerIdText = cid
            }
            // load accounts from PreviewMocks if in preview; otherwise app should call vm.load with real accounts
            #if DEBUG
            // Prefill API key/customer id from local secrets if present (local dev convenience)
            if vm.accounts.isEmpty {
                vm.load(accounts: PreviewMocks.sampleAccounts)
                selectedAccountId = vm.accounts.first?.id
            }
            // If LocalSecrets exists (DEBUG) prefill the Nessie inputs for quick testing
            #if canImport(Foundation)
            if let _ = NSClassFromString("XCTest") {
                // running tests: skip
            } else {
                // Use LocalSecrets if available
                #if DEBUG
                apiKeyText = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
                customerIdText = Bundle.main.object(forInfoDictionaryKey: "CUSTOMER_ID") as? String ?? ""
                #endif
            }
            #endif
            #endif
        }
    }

    private func runSimulation() {
        guard let accId = selectedAccountId, let amount = Double(amountText) else { return }
        let purchase = PlannedPurchase(accountId: accId, amount: amount, msiMonths: msiMonths)
        self.result = vm.simulate(purchase: purchase, months: 12)
    }
}

// Previews
struct SimulationView_Previews: PreviewProvider {
    static var previews: some View {
        SimulationView()
            .environmentObject(PreviewMocks.ledger)
            .previewDevice("iPhone 14")
    }
}
