//
//  Account.swift
//  Spendo
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var currency: String
    var iconName: String
    var iconColorHex: String
    var iconBgColorHex: String
    var subtitle: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        balance: Double = 0.0,
        currency: String = "CNY",
        iconName: String = "banknote",
        iconColorHex: String = "#FFFFFF",
        iconBgColorHex: String = "#007AFF",
        subtitle: String? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.currency = currency
        self.iconName = iconName
        self.iconColorHex = iconColorHex
        self.iconBgColorHex = iconBgColorHex
        self.subtitle = subtitle
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 便捷初始化：从预设创建
    convenience init(from preset: AccountPreset, balance: Double = 0.0, customName: String? = nil) {
        self.init(
            name: customName ?? preset.name,
            type: preset.type,
            balance: balance,
            iconName: preset.iconName,
            iconColorHex: preset.iconColor.toHex(),
            iconBgColorHex: preset.iconBackgroundColor.toHex(),
            subtitle: preset.type.displayName
        )
    }
}

enum AccountType: String, Codable, CaseIterable {
    case cash = "cash"
    case bankCard = "bankCard"
    case creditCard = "creditCard"
    case digital = "digital"
    case investment = "investment"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .cash: return "现金"
        case .bankCard: return "银行卡"
        case .creditCard: return "信用卡"
        case .digital: return "电子账户"
        case .investment: return "投资账户"
        case .other: return "其他"
        }
    }
}
