//
//  ApiModels.swift
//  CapitalOneDemo
//
//  Created by Cruz Yael Pérez González on 25/10/25.
//

// MARK - Address and Customer struct
import Foundation

struct Address: Codable {
    var street_number: String
    var street_name: String
    var city: String
    var state: String
    var zip: String
}

struct Customer: Codable, Identifiable {
    var id: String
    var firts_name: String
    var last_name: String
    var adress: Address
    
    enum CoinigKeys: String, CodingKey {
        case id = "_id", firts_name, last_name, adress
    }
    
}


// MARK: - Helper types (adjust to actual API schema if needed)
struct Account: Codable, Identifiable {
    let id: String
    let type: String
    let nickname: String
    let rewards: Int
    let balance: Double
    let accountNumber: String
    let customerId: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case type
        case nickname
        case rewards
        case balance
        case accountNumber = "account_number"
        case customerId = "customer_id"
    }

    private enum BalanceCodingKeys: String, CodingKey {
        case amount
    }
    
    init(id: String,
         type: String,
         nickname: String,
         rewards: Int,
         balance: Double,
         accountNumber: String,
         customerId: String) {
        self.id = id
        self.type = type
        self.nickname = nickname
        self.rewards = rewards
        self.balance = balance
        self.accountNumber = accountNumber
        self.customerId = customerId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        rewards = try container.decodeIfPresent(Int.self, forKey: .rewards) ?? 0
        accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        customerId = try container.decodeIfPresent(String.self, forKey: .customerId) ?? ""
        if let doubleBalance = try? container.decode(Double.self, forKey: .balance) {
            balance = doubleBalance
        } else if let intBalance = try? container.decode(Int.self, forKey: .balance) {
            balance = Double(intBalance)
        } else if let stringBalance = try? container.decode(String.self, forKey: .balance),
                  let parsedBalance = Double(stringBalance) {
            balance = parsedBalance
        } else if let nestedContainer = try? container.nestedContainer(keyedBy: BalanceCodingKeys.self, forKey: .balance) {
            if let nestedAmount = try? nestedContainer.decode(Double.self, forKey: .amount) {
                balance = nestedAmount
            } else if let nestedAmount = try? nestedContainer.decode(Int.self, forKey: .amount) {
                balance = Double(nestedAmount)
            } else if let amountString = try? nestedContainer.decode(String.self, forKey: .amount),
                      let nestedAmount = Double(amountString) {
                balance = nestedAmount
            } else {
                balance = 0
            }
        } else {
            balance = 0
        }
    }
}

struct Deposit: Codable, Identifiable {
    
    let id: String
    let medium: String
    let transaction_date: String
    let status: String
    let amount: Double
    let description: String
    let payee_id: String
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id", medium, transaction_date, status, amount, description, payee_id, type
    }
}

struct Merchant: Codable, Identifiable {
    let id: String
    let name: String
    let category: String?
    let address: Address

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case category
        case address
    }
}

struct CreateAccountPayload: Codable, @unchecked Sendable {
    var type: String
    var nickname: String?
    var rewards: Int?
    var balance: Double?
}

struct Purchase: Codable, Identifiable {
    let id: String
    let merchantId: String
    let medium: String
    let purchaseDate: String
    let amount: Double
    let status: String
    let description: String
    let type: String
    let payerId: String
    let payeeId: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case merchantId = "merchant_id"
        case medium
        case purchaseDate = "purchase_date"
        case amount
        case status
        case description
        case type
        case payerId = "payer_id"
        case payeeId = "payee_id"
    }
}

