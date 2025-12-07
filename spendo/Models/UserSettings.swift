//
//  UserSettings.swift
//  Spendo
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var primaryCurrency: String
    var theme: AppTheme
    var notificationsEnabled: Bool
    var budgetAlertThreshold: Double  // 预算使用百分比阈值
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        primaryCurrency: String = "CNY",
        theme: AppTheme = .system,
        notificationsEnabled: Bool = true,
        budgetAlertThreshold: Double = 0.8  // 80%
    ) {
        self.id = id
        self.primaryCurrency = primaryCurrency
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.budgetAlertThreshold = budgetAlertThreshold
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .system: return "跟随系统"
        }
    }
}
