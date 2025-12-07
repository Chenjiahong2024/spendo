//
//  LanguageManager.swift
//  Spendo
//
//  多语言管理器
//

import Foundation
import SwiftUI
import Combine

// MARK: - 支持的语言（全球语言支持）
enum AppLanguage: String, CaseIterable {
    case system = "system"
    // 东亚
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"
    // 欧洲
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case portuguese = "pt"
    case italian = "it"
    case dutch = "nl"
    case polish = "pl"
    case russian = "ru"
    case turkish = "tr"
    case ukrainian = "uk"
    case greek = "el"
    // 中东/南亚
    case arabic = "ar"
    case hindi = "hi"
    case persian = "fa"
    case hebrew = "he"
    // 东南亚
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case malay = "ms"
    case filipino = "fil"
    // 北欧
    case swedish = "sv"
    case norwegian = "nb"
    case danish = "da"
    case finnish = "fi"
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统 / System"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .english: return "English"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .italian: return "Italiano"
        case .dutch: return "Nederlands"
        case .polish: return "Polski"
        case .russian: return "Русский"
        case .turkish: return "Türkçe"
        case .ukrainian: return "Українська"
        case .greek: return "Ελληνικά"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        case .persian: return "فارسی"
        case .hebrew: return "עברית"
        case .thai: return "ไทย"
        case .vietnamese: return "Tiếng Việt"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        case .filipino: return "Filipino"
        case .swedish: return "Svenska"
        case .norwegian: return "Norsk"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        }
    }
    
    var localeIdentifier: String? {
        switch self {
        case .system: return nil
        default: return self.rawValue
        }
    }
    
    // 是否是RTL语言（从右到左）
    var isRTL: Bool {
        switch self {
        case .arabic, .persian, .hebrew: return true
        default: return false
        }
    }
}

// MARK: - 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateLanguage()
        }
    }
    
    @Published var bundle: Bundle = .main
    
    private init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .system
        updateLanguage()
    }
    
    private func updateLanguage() {
        if let localeId = currentLanguage.localeIdentifier,
           let path = Bundle.main.path(forResource: localeId, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            // 使用系统语言
            self.bundle = .main
        }
        
        // 通知视图更新
        objectWillChange.send()
    }
    
    // 获取本地化字符串
    func localizedString(_ key: String) -> String {
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
    
    // 需要重启提示
    var needsRestart: Bool {
        return true // 某些文本可能需要重启才能完全生效
    }
}

// MARK: - 本地化字符串扩展
extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - 本地化键值
struct L10n {
    // 通用
    static var cancel: String { "cancel".localized }
    static var confirm: String { "confirm".localized }
    static var save: String { "save".localized }
    static var delete: String { "delete".localized }
    static var edit: String { "edit".localized }
    static var done: String { "done".localized }
    static var back: String { "back".localized }
    static var settings: String { "settings".localized }
    static var search: String { "search".localized }
    
    // TabBar
    static var tabLedger: String { "tab_ledger".localized }
    static var tabAssets: String { "tab_assets".localized }
    static var tabSavings: String { "tab_savings".localized }
    static var tabStats: String { "tab_stats".localized }
    static var tabSettings: String { "tab_settings".localized }
    
    // 交易
    static var expense: String { "expense".localized }
    static var income: String { "income".localized }
    static var amount: String { "amount".localized }
    static var category: String { "category".localized }
    static var account: String { "account".localized }
    static var note: String { "note".localized }
    static var date: String { "date".localized }
    static var addTransaction: String { "add_transaction".localized }
    
    // 设置
    static var language: String { "language".localized }
    static var currency: String { "currency".localized }
    static var theme: String { "theme".localized }
    static var personalization: String { "personalization".localized }
    static var themeColor: String { "theme_color".localized }
    static var tabBarStyle: String { "tabbar_style".localized }
    static var iconStyle: String { "icon_style".localized }
    static var animation: String { "animation".localized }
    
    // 统计
    static var totalExpense: String { "total_expense".localized }
    static var totalIncome: String { "total_income".localized }
    static var balance: String { "balance".localized }
    static var thisMonth: String { "this_month".localized }
    static var thisWeek: String { "this_week".localized }
    static var today: String { "today".localized }
    
    // 账户
    static var cash: String { "cash".localized }
    static var bankCard: String { "bank_card".localized }
    static var creditCard: String { "credit_card".localized }
    static var alipay: String { "alipay".localized }
    static var wechatPay: String { "wechat_pay".localized }
    
    // 类别 - 支出
    static var food: String { "food".localized }
    static var transport: String { "transport".localized }
    static var shopping: String { "shopping".localized }
    static var entertainment: String { "entertainment".localized }
    static var housing: String { "housing".localized }
    static var medical: String { "medical".localized }
    static var education: String { "education".localized }
    static var travel: String { "travel".localized }
    static var other: String { "other".localized }
    
    // 类别 - 收入
    static var salary: String { "salary".localized }
    static var bonus: String { "bonus".localized }
    static var investment: String { "investment".localized }
    static var partTime: String { "part_time".localized }
    static var gift: String { "gift".localized }
}
