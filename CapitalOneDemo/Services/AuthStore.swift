import Foundation

final class AuthStore {
    static let shared = AuthStore()
    private init() {}

    private let service = "CapitalOneDemoAuth"
    private let accountApiKey = "nessie_api_key"
    private let accountCustomerId = "nessie_customer_id"

    func saveApiKey(_ key: String) {
        guard let d = key.data(using: .utf8) else { return }
        KeychainHelper.standard.save(d, service: service, account: accountApiKey)
    }

    func readApiKey() -> String? {
        guard let d = KeychainHelper.standard.read(service: service, account: accountApiKey) else { return nil }
        return String(data: d, encoding: .utf8)
    }

    func deleteApiKey() {
        KeychainHelper.standard.delete(service: service, account: accountApiKey)
    }

    func saveCustomerId(_ id: String) {
        guard let d = id.data(using: .utf8) else { return }
        KeychainHelper.standard.save(d, service: service, account: accountCustomerId)
    }

    func readCustomerId() -> String? {
        guard let d = KeychainHelper.standard.read(service: service, account: accountCustomerId) else { return nil }
        return String(data: d, encoding: .utf8)
    }

    func deleteCustomerId() {
        KeychainHelper.standard.delete(service: service, account: accountCustomerId)
    }

    var isLoggedIn: Bool {
        return readApiKey() != nil && readCustomerId() != nil
    }
}
