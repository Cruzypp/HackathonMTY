import Foundation

final class AccountStore {
    static let shared = AccountStore()
    private init() {}

    private let key = "CapitalOneDemoAccounts.v1"

    func save(_ accounts: [AccountModel]) {
        do {
            let data = try JSONEncoder().encode(accounts)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to save accounts: \(error)")
        }
    }

    func load() -> [AccountModel] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            let arr = try JSONDecoder().decode([AccountModel].self, from: data)
            return arr
        } catch {
            print("Failed to decode accounts: \(error)")
            return []
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
