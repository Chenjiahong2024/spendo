//
//  Budget.swift
//  Spendo
//

import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID
    var period: BudgetPeriod
    var totalAmount: Double
    var categoryId: UUID?  // nil表示总预算
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        period: BudgetPeriod,
        totalAmount: Double,
        categoryId: UUID? = nil,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.period = period
        self.totalAmount = totalAmount
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum BudgetPeriod: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}
