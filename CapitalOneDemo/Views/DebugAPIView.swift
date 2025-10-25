import SwiftUI

struct DebugAPIView: View {
    @State private var debugInfo: [String] = []
    @State private var accounts: [Account] = []
    @State private var purchases: [Purchase] = []
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                Button("Test API Connection") {
                    testAPIConnection()
                }
                .padding()
                .background(SwiftFinColor.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                if isLoading {
                    ProgressView("Testing API...")
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(debugInfo.enumerated()), id: \.offset) { _, info in
                            Text(info)
                                .font(.caption)
                                .padding(8)
                                .background(SwiftFinColor.surface)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }
                
                if !accounts.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Accounts Found:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(accounts) { account in
                            VStack(alignment: .leading) {
                                Text("Name: \(account.nickname.isEmpty ? account.type : account.nickname)")
                                Text("Type: \(account.type)")
                                Text("Balance: $\(account.balance)")
                                Text("ID: \(account.id)")
                            }
                            .font(.caption)
                            .padding()
                            .background(SwiftFinColor.surfaceAlt)
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationTitle("API Debug")
        .preferredColorScheme(.dark)
    }
    
    func testAPIConnection() {
        debugInfo.removeAll()
        accounts.removeAll()
        isLoading = true
        
        let apiKey = AuthStore.shared.readApiKey() ?? LocalSecrets.nessieApiKey
        let customerId = AuthStore.shared.readCustomerId() ?? LocalSecrets.nessieCustomerId
        
        debugInfo.append("🔍 Using API Key: \(apiKey.prefix(10))...")
        debugInfo.append("🔍 Using Customer ID: \(customerId)")
        debugInfo.append("🌐 Testing URL: https://api.nessieisreal.com/customers/\(customerId)/accounts")
        
        NessieService.shared.fetchAccounts(forCustomerId: customerId, apiKey: apiKey) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetchedAccounts):
                    self.accounts = fetchedAccounts
                    self.debugInfo.append("✅ Successfully fetched \(fetchedAccounts.count) accounts")
                    
                    for account in fetchedAccounts {
                        let alias = account.nickname.isEmpty ? account.type : account.nickname
                        self.debugInfo.append("📦 Account: \(alias) - $\(account.balance)")
                        
                        if account.type.lowercased().contains("credit") {
                            self.debugInfo.append("💳 Credit Card Found: \(alias)")
                        } else if account.type.lowercased().contains("checking") {
                            self.debugInfo.append("🏦 Checking Account Found: \(alias)")
                        }
                    }
                    
                case .failure(let error):
                    switch error {
                    case .invalidURL:
                        self.debugInfo.append("❌ Invalid URL")
                    case .requestFailed(let reqError):
                        self.debugInfo.append("❌ Request failed: \(reqError.localizedDescription)")
                    case .badResponse(let code):
                        self.debugInfo.append("❌ Bad response code: \(code)")
                    case .decoding(let decError):
                        self.debugInfo.append("❌ Decoding error: \(decError.localizedDescription)")
                    case .mockMode:
                        self.debugInfo.append("Using mock info")
                    }
                }
            }
        }
    }
}

#Preview {
    DebugAPIView()
}
