import Foundation

/// Lightweight client for the (sample) Nessie API.
///
/// NOTE: I don't call the API during edits. This client provides two helpers:
/// - `fetchAccounts(forCustomerId:apiKey:completion:)` to retrieve accounts
/// - `createAccount(forCustomerId:apiKey:payload:completion:)` to POST a new account
///
/// Adjust JSON mapping if the remote schema differs. Handle API key securely in your app (Keychain or env),
/// do not hardcode in source.

final class NessieService {
    static let shared = NessieService()
    private init() {}

    enum NessieError: Error {
        case invalidURL
        case requestFailed(Error)
        case badResponse(Int)
        case decoding(Error)
        case mockMode
    }

    // Set to true to use mock data instead of real API
    var useMockData: Bool = false

    private let base = "http://api.nessieisreal.com"

    // MARK: - Mock Data
    private func mockAccounts() -> [Account] {
        return [
            Account(id: "1", type: "Credit", nickname: "Mi tarjeta", rewards: 100, balance: 1500.0, accountNumber: "1234", customerId: "mockCustomer"),
            Account(id: "2", type: "Checking", nickname: "Cuenta corriente", rewards: 0, balance: 2500.0, accountNumber: "5678", customerId: "mockCustomer")
        ]
    }
    private func mockPurchases() -> [Purchase] {
        return [
            Purchase(id: "p1", merchantId: "m1", medium: "balance", purchaseDate: "2025-10-25", amount: 50.0, status: "completed", description: "Supermercado", type: "groceries", payerId: "1", payeeId: "m1")
        ]
    }
    private func mockDeposits() -> [Deposit] {
        return [
            Deposit(id: "d1", medium: "balance", transaction_date: "2025-10-24", status: "completed", amount: 1000.0, description: "Depósito inicial", payee_id: "1", type: "deposit")
        ]
    }
    private func mockMerchant() -> Merchant {
        return Merchant(id: "m1", name: "Supermercado Demo", category: "groceries", address: Address(street_number: "123", street_name: "Calle Falsa", city: "CDMX", state: "CDMX", zip: "01000"))
    }

    // MARK: - Generic Request Handler
    func performRequest<T: Decodable>(_ req: URLRequest, completion: @escaping (Result<T, NessieError>) -> Void) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10 // segundos
        config.timeoutIntervalForResource = 15 // segundos
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: req) { data, resp, err in
            if let e = err {
                print("❌ NessieService: Request error: \(e)")
                completion(.failure(.requestFailed(e)))
                return
            }
            guard let http = resp as? HTTPURLResponse else {
                completion(.failure(.invalidURL))
                return
            }
            guard (200..<300).contains(http.statusCode), let d = data else {
                completion(.failure(.badResponse(http.statusCode)))
                return
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: d)
                completion(.success(result))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }

    /// Fetch accounts for a given customer id.
    /// The completion returns Account objects from GetModels.swift
    func fetchAccounts(forCustomerId customerId: String, apiKey: String, completion: @escaping (Result<[Account], NessieError>) -> Void) {
        if useMockData {
            completion(.success(mockAccounts()))
            return
        }
        guard let url = URL(string: "\(base)/customers/\(customerId)/accounts?key=\(apiKey)") else {
            completion(.failure(.invalidURL)); return
        }
        let req = URLRequest(url: url)
        performRequest(req, completion: completion)
    }

    /// Create (POST) an account for a customer. The payload should match the API schema.
    func createAccount(forCustomerId customerId: String, apiKey: String, payload: CreateAccountPayload, completion: @escaping (Result<Account, NessieError>) -> Void) {
        if useMockData {
            let mock = Account(id: "mockNew", type: payload.type, nickname: payload.nickname ?? "Nuevo", rewards: payload.rewards ?? 0, balance: payload.balance ?? 0, accountNumber: "9999", customerId: customerId)
            completion(.success(mock))
            return
        }
        guard let url = URL(string: "\(base)/customers/\(customerId)/accounts?key=\(apiKey)") else { completion(.failure(.invalidURL)); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let enc = JSONEncoder()
            enc.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try enc.encode(payload)
        } catch {
            completion(.failure(.decoding(error))); return
        }
        performRequest(req, completion: completion)
    }
    
    /// Fetch purchases for a specific account
    /// Si purchaseEndpoint es nil, usa el endpoint estándar. Si no, usa el endpoint directo proporcionado.
    func fetchPurchases(forAccountId accountId: String, apiKey: String, purchaseEndpoint: String? = nil, completion: @escaping (Result<[Purchase], NessieError>) -> Void) {
        if useMockData {
            completion(.success(mockPurchases()))
            return
        }
        let urlString: String
        if let endpoint = purchaseEndpoint {
            urlString = endpoint
        } else {
            urlString = "\(base)/accounts/\(accountId)/purchases?key=\(apiKey)"
        }
        guard let url = URL(string: urlString) else {
            print("❌ NessieService: URL inválida para compras: \(urlString)")
            completion(.failure(.invalidURL)); return
        }
        let req = URLRequest(url: url)
        print("🌐 NessieService: GET compras desde: \(urlString)")
        let task = URLSession.shared.dataTask(with: req) { data, resp, err in
            if let e = err {
                print("❌ NessieService: Error de red en compras: \(e)")
                completion(.failure(.requestFailed(e)))
                return
            }
            guard let http = resp as? HTTPURLResponse else {
                print("❌ NessieService: Respuesta HTTP inválida en compras")
                completion(.failure(.invalidURL)); return
            }
            print("📡 NessieService: HTTP Status compras: \(http.statusCode)")
            if http.statusCode == 401 || http.statusCode == 403 {
                print("🔑 NessieService: API Key inválida o expirada")
            } else if http.statusCode == 429 {
                print("⏳ NessieService: Límite de requests excedido (rate limit)")
            }
            guard (200..<300).contains(http.statusCode), let d = data else {
                print("❌ NessieService: Código de estado compras: \(http.statusCode)")
                completion(.failure(.badResponse(http.statusCode))); return
            }
            do {
                let decoder = JSONDecoder()
                let purchases = try decoder.decode([Purchase].self, from: d)
                print("✅ NessieService: Decodificadas \(purchases.count) compras")
                completion(.success(purchases))
            } catch {
                print("❌ NessieService: Error decodificando compras: \(error)")
                if let responseString = String(data: d, encoding: .utf8) {
                    print("📄 Respuesta compras: \(responseString)")
                }
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }
    
    /// Fetch deposits for a specific account
    func fetchDeposits(forAccountId accountId: String, apiKey: String, completion: @escaping (Result<[Deposit], NessieError>) -> Void) {
        if useMockData {
            completion(.success(mockDeposits()))
            return
        }
        guard let url = URL(string: "\(base)/accounts/\(accountId)/deposits?key=\(apiKey)") else {
            completion(.failure(.invalidURL)); return
        }
        let req = URLRequest(url: url)
        performRequest(req, completion: completion)
    }
    
    /// Fetch merchant details
    func fetchMerchant(forId merchantId: String, apiKey: String, completion: @escaping (Result<Merchant, NessieError>) -> Void) {
        if useMockData {
            completion(.success(mockMerchant()))
            return
        }
        guard let url = URL(string: "\(base)/merchants/\(merchantId)?key=\(apiKey)") else {
            completion(.failure(.invalidURL)); return
        }
        let req = URLRequest(url: url)
        performRequest(req, completion: completion)
    }
}

