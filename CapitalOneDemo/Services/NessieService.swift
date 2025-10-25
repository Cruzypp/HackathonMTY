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
    }

    private let base = "https://api.nessieisreal.com"

    /// Fetch accounts for a given customer id.
    /// The completion returns raw decoded helper objects (NessieAccount) which you can map to your app models.
    func fetchAccounts(forCustomerId customerId: String, apiKey: String, completion: @escaping (Result<[NessieAccount], NessieError>) -> Void) {
        // Many Nessie endpoints are under /customers/{id}/accounts - try that path.
        guard let url = URL(string: "\(base)/customers/\(customerId)/accounts?key=\(apiKey)") else {
            completion(.failure(.invalidURL)); return
        }

        let req = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: req) { data, resp, err in
            if let e = err { completion(.failure(.requestFailed(e))); return }
            guard let http = resp as? HTTPURLResponse else { completion(.failure(.invalidURL)); return }
            guard (200..<300).contains(http.statusCode), let d = data else { completion(.failure(.badResponse(http.statusCode))); return }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let arr = try decoder.decode([NessieAccount].self, from: d)
                completion(.success(arr))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }

    /// Create (POST) an account for a customer. The payload should match the API schema.
    func createAccount(forCustomerId customerId: String, apiKey: String, payload: NessieCreateAccountPayload, completion: @escaping (Result<NessieAccount, NessieError>) -> Void) {
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

        let task = URLSession.shared.dataTask(with: req) { data, resp, err in
            if let e = err { completion(.failure(.requestFailed(e))); return }
            guard let http = resp as? HTTPURLResponse else { completion(.failure(.invalidURL)); return }
            guard (200..<300).contains(http.statusCode), let d = data else { completion(.failure(.badResponse(http.statusCode))); return }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let acc = try decoder.decode(NessieAccount.self, from: d)
                completion(.success(acc))
            } catch {
                completion(.failure(.decoding(error)))
            }
        }
        task.resume()
    }
}

// MARK: - Helper types (adjust to actual API schema if needed)
struct NessieAccount: Codable, @unchecked Sendable {
    // The Nessie examples often use _id strings for object ids
    var _id: String?
    var type: String?
    var nickname: String?
    var rewards: Int?
    var balance: NessieBalance?
}

struct NessieBalance: Codable, @unchecked Sendable {
    var amount: Double?
    var limit: Double? // sometimes provided for credit-like accounts
}

struct NessieCreateAccountPayload: Codable, @unchecked Sendable {
    var type: String
    var nickname: String?
    var rewards: Int?
    var balance: NessieBalance?
}
