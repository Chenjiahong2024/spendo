//
//  Transaction.swift
//  Spendo
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var categoryId: UUID?
    var accountId: UUID?
    var date: Date
    var note: String
    var currency: String
    var createdAt: Date
    var updatedAt: Date
    
    // 云同步相关字段
    var userId: String?
    var syncStatus: SyncStatus
    
    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        categoryId: UUID? = nil,
        accountId: UUID? = nil,
        date: Date = Date(),
        note: String = "",
        currency: String = "CNY",
        userId: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.categoryId = categoryId
        self.accountId = accountId
        self.date = date
        self.note = note
        self.currency = currency
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userId = userId
        self.syncStatus = .local
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "income"
    case expense = "expense"
    
    var displayName: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        }
    }
}

enum SyncStatus: String, Codable {
    case local = "local"
    case synced = "synced"
    case pending = "pending"
    case conflict = "conflict"
}
