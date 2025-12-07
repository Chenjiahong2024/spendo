//
//  CurrencyService.swift
//  Spendo
//

import Foundation
import Combine

// 货币信息结构
struct CurrencyInfo {
    let code: String      // 货币代码
    let symbol: String    // 货币符号
    let name: String      // 货币名称（中文）
    let rate: Double      // 对人民币汇率
}

class CurrencyService: ObservableObject {
    static let shared = CurrencyService()
    
    private init() {
        // 启动时加载缓存的汇率
        loadRatesFromCache()
    }
    
    // 全球主要货币列表（按地区分组）
    static let allCurrencies: [CurrencyInfo] = [
        // 亚洲
        CurrencyInfo(code: "CNY", symbol: "¥", name: "人民币", rate: 1.0),
        CurrencyInfo(code: "HKD", symbol: "HK$", name: "港币", rate: 1.09),
        CurrencyInfo(code: "TWD", symbol: "NT$", name: "新台币", rate: 4.44),
        CurrencyInfo(code: "MOP", symbol: "MOP$", name: "澳门元", rate: 1.12),
        CurrencyInfo(code: "JPY", symbol: "¥", name: "日元", rate: 20.8),
        CurrencyInfo(code: "KRW", symbol: "₩", name: "韩元", rate: 185.0),
        CurrencyInfo(code: "SGD", symbol: "S$", name: "新加坡元", rate: 0.19),
        CurrencyInfo(code: "MYR", symbol: "RM", name: "马来西亚林吉特", rate: 0.62),
        CurrencyInfo(code: "THB", symbol: "฿", name: "泰铢", rate: 4.78),
        CurrencyInfo(code: "VND", symbol: "₫", name: "越南盾", rate: 3450.0),
        CurrencyInfo(code: "PHP", symbol: "₱", name: "菲律宾比索", rate: 7.85),
        CurrencyInfo(code: "IDR", symbol: "Rp", name: "印尼盾", rate: 2180.0),
        CurrencyInfo(code: "INR", symbol: "₹", name: "印度卢比", rate: 11.68),
        CurrencyInfo(code: "PKR", symbol: "Rs", name: "巴基斯坦卢比", rate: 39.0),
        CurrencyInfo(code: "BDT", symbol: "৳", name: "孟加拉塔卡", rate: 15.3),
        CurrencyInfo(code: "LKR", symbol: "Rs", name: "斯里兰卡卢比", rate: 45.0),
        CurrencyInfo(code: "NPR", symbol: "Rs", name: "尼泊尔卢比", rate: 18.7),
        CurrencyInfo(code: "MMK", symbol: "K", name: "缅甸元", rate: 293.0),
        CurrencyInfo(code: "KHR", symbol: "៛", name: "柬埔寨瑞尔", rate: 567.0),
        CurrencyInfo(code: "LAK", symbol: "₭", name: "老挝基普", rate: 2900.0),
        CurrencyInfo(code: "BND", symbol: "B$", name: "文莱元", rate: 0.19),
        
        // 中东
        CurrencyInfo(code: "AED", symbol: "د.إ", name: "阿联酋迪拉姆", rate: 0.51),
        CurrencyInfo(code: "SAR", symbol: "﷼", name: "沙特里亚尔", rate: 0.52),
        CurrencyInfo(code: "QAR", symbol: "﷼", name: "卡塔尔里亚尔", rate: 0.51),
        CurrencyInfo(code: "KWD", symbol: "د.ك", name: "科威特第纳尔", rate: 0.043),
        CurrencyInfo(code: "BHD", symbol: "BD", name: "巴林第纳尔", rate: 0.053),
        CurrencyInfo(code: "OMR", symbol: "﷼", name: "阿曼里亚尔", rate: 0.054),
        CurrencyInfo(code: "ILS", symbol: "₪", name: "以色列谢克尔", rate: 0.52),
        CurrencyInfo(code: "TRY", symbol: "₺", name: "土耳其里拉", rate: 4.78),
        
        // 欧洲
        CurrencyInfo(code: "EUR", symbol: "€", name: "欧元", rate: 0.13),
        CurrencyInfo(code: "GBP", symbol: "£", name: "英镑", rate: 0.11),
        CurrencyInfo(code: "CHF", symbol: "Fr", name: "瑞士法郎", rate: 0.12),
        CurrencyInfo(code: "RUB", symbol: "₽", name: "俄罗斯卢布", rate: 12.5),
        CurrencyInfo(code: "SEK", symbol: "kr", name: "瑞典克朗", rate: 1.45),
        CurrencyInfo(code: "NOK", symbol: "kr", name: "挪威克朗", rate: 1.50),
        CurrencyInfo(code: "DKK", symbol: "kr", name: "丹麦克朗", rate: 0.97),
        CurrencyInfo(code: "PLN", symbol: "zł", name: "波兰兹罗提", rate: 0.56),
        CurrencyInfo(code: "CZK", symbol: "Kč", name: "捷克克朗", rate: 3.20),
        CurrencyInfo(code: "HUF", symbol: "Ft", name: "匈牙利福林", rate: 50.0),
        CurrencyInfo(code: "RON", symbol: "lei", name: "罗马尼亚列伊", rate: 0.64),
        CurrencyInfo(code: "BGN", symbol: "лв", name: "保加利亚列弗", rate: 0.25),
        CurrencyInfo(code: "HRK", symbol: "kn", name: "克罗地亚库纳", rate: 0.97),
        CurrencyInfo(code: "UAH", symbol: "₴", name: "乌克兰格里夫纳", rate: 5.20),
        CurrencyInfo(code: "ISK", symbol: "kr", name: "冰岛克朗", rate: 19.3),
        
        // 北美洲
        CurrencyInfo(code: "USD", symbol: "$", name: "美元", rate: 0.14),
        CurrencyInfo(code: "CAD", symbol: "C$", name: "加拿大元", rate: 0.19),
        CurrencyInfo(code: "MXN", symbol: "Mex$", name: "墨西哥比索", rate: 2.40),
        
        // 南美洲
        CurrencyInfo(code: "BRL", symbol: "R$", name: "巴西雷亚尔", rate: 0.69),
        CurrencyInfo(code: "ARS", symbol: "$", name: "阿根廷比索", rate: 125.0),
        CurrencyInfo(code: "CLP", symbol: "$", name: "智利比索", rate: 125.0),
        CurrencyInfo(code: "COP", symbol: "$", name: "哥伦比亚比索", rate: 560.0),
        CurrencyInfo(code: "PEN", symbol: "S/", name: "秘鲁索尔", rate: 0.52),
        
        // 大洋洲
        CurrencyInfo(code: "AUD", symbol: "A$", name: "澳大利亚元", rate: 0.21),
        CurrencyInfo(code: "NZD", symbol: "NZ$", name: "新西兰元", rate: 0.23),
        CurrencyInfo(code: "FJD", symbol: "FJ$", name: "斐济元", rate: 0.31),
        
        // 非洲
        CurrencyInfo(code: "ZAR", symbol: "R", name: "南非兰特", rate: 2.52),
        CurrencyInfo(code: "EGP", symbol: "E£", name: "埃及镑", rate: 6.85),
        CurrencyInfo(code: "NGN", symbol: "₦", name: "尼日利亚奈拉", rate: 218.0),
        CurrencyInfo(code: "KES", symbol: "KSh", name: "肯尼亚先令", rate: 21.5),
        CurrencyInfo(code: "MAD", symbol: "د.م.", name: "摩洛哥迪拉姆", rate: 1.40),
        CurrencyInfo(code: "TND", symbol: "د.ت", name: "突尼斯第纳尔", rate: 0.44),
        CurrencyInfo(code: "GHS", symbol: "₵", name: "加纳塞地", rate: 1.70),
    ]
    
    // 货币代码列表
    static var currencyCodes: [String] {
        allCurrencies.map { $0.code }
    }
    
    // 汇率表
    private var exchangeRates: [String: Double] {
        Dictionary(uniqueKeysWithValues: Self.allCurrencies.map { ($0.code, $0.rate) })
    }
    
    // 币种符号
    private var currencySymbols: [String: String] {
        Dictionary(uniqueKeysWithValues: Self.allCurrencies.map { ($0.code, $0.symbol) })
    }
    
    // 获取货币信息
    static func info(for code: String) -> CurrencyInfo? {
        allCurrencies.first { $0.code == code }
    }
    
    // MARK: - 实时汇率
    
    // 缓存的实时汇率（基于 CNY）
    @Published var liveRates: [String: Double] = [:]
    @Published var lastUpdateTime: Date?
    @Published var isUpdating = false
    
    // 获取汇率（优先使用实时汇率）
    func getRate(for currency: String) -> Double {
        if let liveRate = liveRates[currency] {
            return liveRate
        }
        return exchangeRates[currency] ?? 1.0
    }
    
    // 转换货币
    func convert(amount: Double, from: String, to: String) -> Double {
        let fromRate = getRate(for: from)
        let toRate = getRate(for: to)
        
        // 先转换为基准货币(CNY)，再转换为目标货币
        let baseAmount = amount / fromRate
        return baseAmount * toRate
    }
    
    // 获取币种符号
    func symbol(for currency: String) -> String {
        return currencySymbols[currency] ?? currency
    }
    
    // 格式化金额
    func formatAmount(_ amount: Double, currency: String) -> String {
        let symbol = self.symbol(for: currency)
        return "\(symbol)\(String(format: "%.2f", amount))"
    }
    
    // MARK: - 从 API 获取实时汇率
    
    /// 更新汇率（从 frankfurter.app 或 exchangerate.host 获取）
    func updateExchangeRates(completion: @escaping (Bool) -> Void) {
        guard !isUpdating else {
            completion(false)
            return
        }
        
        isUpdating = true
        
        // 使用 frankfurter.app 免费 API（基于欧洲央行数据）
        // 获取基于 CNY 的汇率
        let urlString = "https://api.frankfurter.app/latest?from=CNY"
        
        guard let url = URL(string: urlString) else {
            isUpdating = false
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isUpdating = false
                
                guard let data = data, error == nil else {
                    print("汇率更新失败: \(error?.localizedDescription ?? "未知错误")")
                    // 尝试备用 API
                    self?.updateFromBackupAPI(completion: completion)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let rates = json["rates"] as? [String: Double] {
                        
                        // 更新汇率缓存
                        var newRates: [String: Double] = ["CNY": 1.0]
                        for (code, rate) in rates {
                            newRates[code] = rate
                        }
                        
                        self?.liveRates = newRates
                        self?.lastUpdateTime = Date()
                        self?.saveRatesToCache(newRates)
                        
                        print("汇率更新成功，共 \(newRates.count) 种货币")
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    print("解析汇率数据失败: \(error)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 备用 API
    private func updateFromBackupAPI(completion: @escaping (Bool) -> Void) {
        let urlString = "https://open.er-api.com/v6/latest/CNY"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("备用API也失败: \(error?.localizedDescription ?? "未知错误")")
                    completion(false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let rates = json["rates"] as? [String: Double] {
                        
                        var newRates: [String: Double] = [:]
                        for (code, rate) in rates {
                            newRates[code] = rate
                        }
                        
                        self?.liveRates = newRates
                        self?.lastUpdateTime = Date()
                        self?.saveRatesToCache(newRates)
                        
                        print("备用API更新成功")
                        completion(true)
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - 缓存管理
    
    private let ratesCacheKey = "cachedExchangeRates"
    private let ratesTimestampKey = "exchangeRatesTimestamp"
    
    private func saveRatesToCache(_ rates: [String: Double]) {
        UserDefaults.standard.set(rates, forKey: ratesCacheKey)
        UserDefaults.standard.set(Date(), forKey: ratesTimestampKey)
    }
    
    func loadRatesFromCache() {
        if let cached = UserDefaults.standard.dictionary(forKey: ratesCacheKey) as? [String: Double] {
            liveRates = cached
            lastUpdateTime = UserDefaults.standard.object(forKey: ratesTimestampKey) as? Date
        }
    }
    
    // 检查是否需要更新（超过1小时自动更新）
    var needsUpdate: Bool {
        guard let lastUpdate = lastUpdateTime else { return true }
        return Date().timeIntervalSince(lastUpdate) > 3600 // 1小时
    }
    
    // 格式化上次更新时间
    var lastUpdateTimeString: String {
        guard let time = lastUpdateTime else { return "从未更新" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: time, relativeTo: Date())
    }
}
