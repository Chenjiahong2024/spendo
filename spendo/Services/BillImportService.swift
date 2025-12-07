//
//  BillImportService.swift
//  Spendo
//
//  账单导入服务 - 支持多种记账App的账单格式
//

import Foundation
import SwiftData

// MARK: - 导入来源枚举
enum BillImportSource: String, CaseIterable, Identifiable {
    case alipay = "alipay"
    case wechat = "wechat"
    case wangyiyouqian = "wangyiyouqian"
    case qianji = "qianji"
    case suishouji = "suishouji"
    case moze = "moze"
    case shayujizhan = "shayujizhan"
    case youyujizhan = "youyujizhan"
    case tutujizhan = "tutujizhan"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alipay: return "支付宝"
        case .wechat: return "微信"
        case .wangyiyouqian: return "网易有钱"
        case .qianji: return "钱迹"
        case .suishouji: return "随手记"
        case .moze: return "Moze"
        case .shayujizhan: return "鲨鱼记账"
        case .youyujizhan: return "有鱼记账"
        case .tutujizhan: return "图图记账"
        }
    }
    
    var iconName: String {
        switch self {
        case .alipay: return "a.circle.fill"
        case .wechat: return "message.fill"
        case .wangyiyouqian: return "yensign.circle.fill"
        case .qianji: return "dollarsign.circle.fill"
        case .suishouji: return "hand.point.up.fill"
        case .moze: return "m.circle.fill"
        case .shayujizhan: return "fish.fill"
        case .youyujizhan: return "fish.circle.fill"
        case .tutujizhan: return "photo.circle.fill"
        }
    }
    
    var iconColor: String {
        switch self {
        case .alipay: return "#1677FF"
        case .wechat: return "#07C160"
        case .wangyiyouqian: return "#E60012"
        case .qianji: return "#FFB800"
        case .suishouji: return "#FF6B6B"
        case .moze: return "#5856D6"
        case .shayujizhan: return "#34C759"
        case .youyujizhan: return "#FF3B30"
        case .tutujizhan: return "#FF9500"
        }
    }
}

// MARK: - 导入结果
struct BillImportResult {
    var successCount: Int = 0
    var failedCount: Int = 0
    var duplicateCount: Int = 0
    var transactions: [ImportedTransaction] = []
    var errors: [String] = []
}

// MARK: - 导入的交易记录（预览用）
struct ImportedTransaction: Identifiable {
    let id = UUID()
    var date: Date
    var amount: Double
    var type: TransactionType
    var categoryName: String
    var note: String
    var originalData: [String: String] // 原始数据，用于调试
    var isSelected: Bool = true
}

// MARK: - 账单导入服务
class BillImportService {
    static let shared = BillImportService()
    
    private init() {}
    
    // MARK: - 解析CSV文件
    func parseCSV(from url: URL, source: BillImportSource) throws -> BillImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parseCSVContent(content, source: source)
    }
    
    func parseCSVContent(_ content: String, source: BillImportSource) -> BillImportResult {
        var result = BillImportResult()
        
        // 按行分割
        let lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // 根据来源解析
        switch source {
        case .alipay:
            result = parseAlipayBill(lines: lines)
        case .wechat:
            result = parseWechatBill(lines: lines)
        case .qianji:
            result = parseQianjiBill(lines: lines)
        case .suishouji:
            result = parseSuishoujiBill(lines: lines)
        case .moze:
            result = parseMozeBill(lines: lines)
        default:
            result = parseGenericCSV(lines: lines)
        }
        
        return result
    }
    
    // MARK: - 支付宝账单解析
    private func parseAlipayBill(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        // 支付宝账单格式：
        // 交易时间,交易分类,交易对方,商品说明,收/支,金额,收/付款方式,交易状态,交易订单号,商家订单号,备注
        
        // 跳过头部说明行，找到表头
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("交易时间") && line.contains("金额") {
                headerIndex = index
                break
            }
        }
        
        let headers = parseCSVLine(lines[headerIndex])
        let dateIndex = headers.firstIndex(of: "交易时间") ?? 0
        let typeIndex = headers.firstIndex(where: { $0.contains("收/支") }) ?? 4
        let amountIndex = headers.firstIndex(of: "金额") ?? 5
        let categoryIndex = headers.firstIndex(of: "交易分类") ?? 1
        let noteIndex = headers.firstIndex(of: "商品说明") ?? 3
        let counterpartyIndex = headers.firstIndex(of: "交易对方") ?? 2
        let statusIndex = headers.firstIndex(of: "交易状态") ?? 7
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, typeIndex, amountIndex) else { continue }
            
            // 跳过非成功的交易
            if statusIndex < fields.count {
                let status = fields[statusIndex]
                if status.contains("关闭") || status.contains("退款") {
                    continue
                }
            }
            
            // 解析日期
            let dateStr = fields[dateIndex]
            guard let date = parseDate(dateStr) else {
                result.errors.append("无法解析日期: \(dateStr)")
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            let amountStr = fields[amountIndex].replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard let amount = Double(amountStr), amount > 0 else {
                result.failedCount += 1
                continue
            }
            
            // 解析类型
            let typeStr = fields[typeIndex]
            let type: TransactionType = typeStr.contains("收入") ? .income : .expense
            
            // 解析备注
            var note = ""
            if noteIndex < fields.count {
                note = fields[noteIndex]
            }
            if counterpartyIndex < fields.count && !fields[counterpartyIndex].isEmpty {
                note = fields[counterpartyIndex] + (note.isEmpty ? "" : " - " + note)
            }
            
            // 解析分类
            var categoryName = "其他"
            if categoryIndex < fields.count {
                categoryName = mapAlipayCategory(fields[categoryIndex])
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: amount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - 微信账单解析
    private func parseWechatBill(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        // 微信账单格式：
        // 交易时间,交易类型,交易对方,商品,收/支,金额(元),支付方式,当前状态,交易单号,商户单号,备注
        
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("交易时间") && line.contains("金额") {
                headerIndex = index
                break
            }
        }
        
        guard headerIndex < lines.count else { return result }
        
        let headers = parseCSVLine(lines[headerIndex])
        let dateIndex = headers.firstIndex(of: "交易时间") ?? 0
        let typeIndex = headers.firstIndex(where: { $0.contains("收/支") }) ?? 4
        let amountIndex = headers.firstIndex(where: { $0.contains("金额") }) ?? 5
        let categoryIndex = headers.firstIndex(of: "交易类型") ?? 1
        let noteIndex = headers.firstIndex(of: "商品") ?? 3
        let counterpartyIndex = headers.firstIndex(of: "交易对方") ?? 2
        let statusIndex = headers.firstIndex(of: "当前状态") ?? 7
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, typeIndex, amountIndex) else { continue }
            
            // 跳过非成功的交易
            if statusIndex < fields.count {
                let status = fields[statusIndex]
                if status.contains("已退款") || status.contains("已关闭") {
                    continue
                }
            }
            
            // 解析日期
            let dateStr = fields[dateIndex]
            guard let date = parseDate(dateStr) else {
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            let amountStr = fields[amountIndex].replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard let amount = Double(amountStr), amount > 0 else {
                result.failedCount += 1
                continue
            }
            
            // 解析类型
            let typeStr = fields[typeIndex]
            let type: TransactionType = typeStr.contains("收入") ? .income : .expense
            
            // 解析备注
            var note = ""
            if noteIndex < fields.count {
                note = fields[noteIndex]
            }
            if counterpartyIndex < fields.count && !fields[counterpartyIndex].isEmpty {
                let counterparty = fields[counterpartyIndex]
                if counterparty != "/" && !counterparty.isEmpty {
                    note = counterparty + (note.isEmpty ? "" : " - " + note)
                }
            }
            
            // 解析分类
            var categoryName = "其他"
            if categoryIndex < fields.count {
                categoryName = mapWechatCategory(fields[categoryIndex])
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: amount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - 钱迹账单解析
    private func parseQianjiBill(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        // 钱迹账单格式：
        // 时间,分类,金额,账户,备注,账单类型
        
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("时间") && (line.contains("分类") || line.contains("金额")) {
                headerIndex = index
                break
            }
        }
        
        let headers = parseCSVLine(lines[headerIndex])
        let dateIndex = headers.firstIndex(of: "时间") ?? 0
        let categoryIndex = headers.firstIndex(of: "分类") ?? 1
        let amountIndex = headers.firstIndex(of: "金额") ?? 2
        let noteIndex = headers.firstIndex(of: "备注") ?? 4
        let typeIndex = headers.firstIndex(of: "账单类型") ?? headers.firstIndex(of: "类型") ?? 5
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, amountIndex) else { continue }
            
            // 解析日期
            let dateStr = fields[dateIndex]
            guard let date = parseDate(dateStr) else {
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            var amountStr = fields[amountIndex].replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            // 处理负数
            let isNegative = amountStr.hasPrefix("-")
            amountStr = amountStr.replacingOccurrences(of: "-", with: "")
            
            guard let amount = Double(amountStr), amount > 0 else {
                result.failedCount += 1
                continue
            }
            
            // 解析类型
            var type: TransactionType = .expense
            if typeIndex < fields.count {
                let typeStr = fields[typeIndex]
                type = typeStr.contains("收入") ? .income : .expense
            } else {
                // 如果没有类型字段，根据金额正负判断
                type = isNegative ? .expense : .income
            }
            
            // 解析分类
            var categoryName = "其他"
            if categoryIndex < fields.count {
                categoryName = fields[categoryIndex]
            }
            
            // 解析备注
            var note = ""
            if noteIndex < fields.count {
                note = fields[noteIndex]
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: amount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - 随手记账单解析
    private func parseSuishoujiBill(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        // 随手记账单格式：
        // 交易类型,日期,分类,子分类,账户1,账户2,金额,手续费,账户1余额,账户2余额,备注,货币,账本
        
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            if line.contains("日期") && line.contains("分类") {
                headerIndex = index
                break
            }
        }
        
        let headers = parseCSVLine(lines[headerIndex])
        let typeIndex = headers.firstIndex(of: "交易类型") ?? 0
        let dateIndex = headers.firstIndex(of: "日期") ?? 1
        let categoryIndex = headers.firstIndex(of: "分类") ?? 2
        let subCategoryIndex = headers.firstIndex(of: "子分类") ?? 3
        let amountIndex = headers.firstIndex(of: "金额") ?? 6
        let noteIndex = headers.firstIndex(of: "备注") ?? 10
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, amountIndex) else { continue }
            
            // 解析日期
            let dateStr = fields[dateIndex]
            guard let date = parseDate(dateStr) else {
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            let amountStr = fields[amountIndex].replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard let amount = Double(amountStr), amount > 0 else {
                result.failedCount += 1
                continue
            }
            
            // 解析类型
            var type: TransactionType = .expense
            if typeIndex < fields.count {
                let typeStr = fields[typeIndex]
                if typeStr.contains("收入") {
                    type = .income
                } else if typeStr.contains("转账") {
                    continue // 跳过转账记录
                }
            }
            
            // 解析分类
            var categoryName = "其他"
            if categoryIndex < fields.count {
                categoryName = fields[categoryIndex]
                if subCategoryIndex < fields.count && !fields[subCategoryIndex].isEmpty {
                    categoryName = fields[subCategoryIndex]
                }
            }
            
            // 解析备注
            var note = ""
            if noteIndex < fields.count {
                note = fields[noteIndex]
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: amount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - Moze账单解析
    private func parseMozeBill(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        // Moze账单格式：
        // Date,Category,Subcategory,Amount,Currency,Account,Project,Merchant,Note,Tags
        
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            if line.lowercased().contains("date") && line.lowercased().contains("amount") {
                headerIndex = index
                break
            }
        }
        
        let headers = parseCSVLine(lines[headerIndex])
        let dateIndex = headers.firstIndex(where: { $0.lowercased() == "date" }) ?? 0
        let categoryIndex = headers.firstIndex(where: { $0.lowercased() == "category" }) ?? 1
        let amountIndex = headers.firstIndex(where: { $0.lowercased() == "amount" }) ?? 3
        let noteIndex = headers.firstIndex(where: { $0.lowercased() == "note" }) ?? 8
        let merchantIndex = headers.firstIndex(where: { $0.lowercased() == "merchant" }) ?? 7
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, amountIndex) else { continue }
            
            // 解析日期
            let dateStr = fields[dateIndex]
            guard let date = parseDate(dateStr) else {
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            let amountStr = fields[amountIndex].replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            guard let amount = Double(amountStr) else {
                result.failedCount += 1
                continue
            }
            
            // Moze中负数为支出，正数为收入
            let type: TransactionType = amount < 0 ? .expense : .income
            let absAmount = abs(amount)
            
            // 解析分类
            var categoryName = "其他"
            if categoryIndex < fields.count {
                categoryName = fields[categoryIndex]
            }
            
            // 解析备注
            var note = ""
            if merchantIndex < fields.count && !fields[merchantIndex].isEmpty {
                note = fields[merchantIndex]
            }
            if noteIndex < fields.count && !fields[noteIndex].isEmpty {
                note += (note.isEmpty ? "" : " - ") + fields[noteIndex]
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: absAmount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - 通用CSV解析
    private func parseGenericCSV(lines: [String]) -> BillImportResult {
        var result = BillImportResult()
        
        guard !lines.isEmpty else { return result }
        
        // 尝试找到表头
        var headerIndex = 0
        for (index, line) in lines.enumerated() {
            let lower = line.lowercased()
            if lower.contains("日期") || lower.contains("date") ||
               lower.contains("时间") || lower.contains("time") {
                headerIndex = index
                break
            }
        }
        
        let headers = parseCSVLine(lines[headerIndex])
        
        // 智能匹配列
        let dateIndex = headers.firstIndex(where: { 
            let l = $0.lowercased()
            return l.contains("日期") || l.contains("时间") || l.contains("date") || l.contains("time")
        }) ?? 0
        
        let amountIndex = headers.firstIndex(where: { 
            let l = $0.lowercased()
            return l.contains("金额") || l.contains("amount") || l.contains("money")
        }) ?? 1
        
        let categoryIndex = headers.firstIndex(where: { 
            let l = $0.lowercased()
            return l.contains("分类") || l.contains("类别") || l.contains("category")
        })
        
        let noteIndex = headers.firstIndex(where: { 
            let l = $0.lowercased()
            return l.contains("备注") || l.contains("说明") || l.contains("note") || l.contains("memo")
        })
        
        let typeIndex = headers.firstIndex(where: { 
            let l = $0.lowercased()
            return l.contains("收/支") || l.contains("类型") || l.contains("type")
        })
        
        for i in (headerIndex + 1)..<lines.count {
            let fields = parseCSVLine(lines[i])
            guard fields.count > max(dateIndex, amountIndex) else { continue }
            
            // 解析日期
            guard let date = parseDate(fields[dateIndex]) else {
                result.failedCount += 1
                continue
            }
            
            // 解析金额
            var amountStr = fields[amountIndex]
                .replacingOccurrences(of: "¥", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            let isNegative = amountStr.hasPrefix("-")
            amountStr = amountStr.replacingOccurrences(of: "-", with: "")
            
            guard let amount = Double(amountStr), amount > 0 else {
                result.failedCount += 1
                continue
            }
            
            // 解析类型
            var type: TransactionType = isNegative ? .expense : .income
            if let typeIdx = typeIndex, typeIdx < fields.count {
                let typeStr = fields[typeIdx]
                if typeStr.contains("收入") || typeStr.contains("income") {
                    type = .income
                } else if typeStr.contains("支出") || typeStr.contains("expense") {
                    type = .expense
                }
            }
            
            // 解析分类
            var categoryName = "其他"
            if let catIdx = categoryIndex, catIdx < fields.count {
                categoryName = fields[catIdx]
            }
            
            // 解析备注
            var note = ""
            if let noteIdx = noteIndex, noteIdx < fields.count {
                note = fields[noteIdx]
            }
            
            let transaction = ImportedTransaction(
                date: date,
                amount: amount,
                type: type,
                categoryName: categoryName,
                note: note,
                originalData: Dictionary(uniqueKeysWithValues: zip(headers, fields))
            )
            
            result.transactions.append(transaction)
            result.successCount += 1
        }
        
        return result
    }
    
    // MARK: - 辅助方法
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let formatters: [DateFormatter] = [
            createFormatter("yyyy-MM-dd HH:mm:ss"),
            createFormatter("yyyy/MM/dd HH:mm:ss"),
            createFormatter("yyyy-MM-dd HH:mm"),
            createFormatter("yyyy/MM/dd HH:mm"),
            createFormatter("yyyy-MM-dd"),
            createFormatter("yyyy/MM/dd"),
            createFormatter("MM/dd/yyyy"),
            createFormatter("dd/MM/yyyy"),
        ]
        
        let trimmed = dateStr.trimmingCharacters(in: .whitespaces)
        
        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        
        return nil
    }
    
    private func createFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    // MARK: - 分类映射
    
    private func mapAlipayCategory(_ category: String) -> String {
        let mapping: [String: String] = [
            "餐饮美食": "餐饮",
            "交通出行": "交通",
            "日用百货": "购物",
            "服饰装扮": "购物",
            "充值缴费": "其他",
            "转账红包": "其他",
            "医疗健康": "医疗",
            "文化休闲": "娱乐",
            "教育培训": "教育",
            "住房物业": "住房",
        ]
        
        for (key, value) in mapping {
            if category.contains(key) {
                return value
            }
        }
        return "其他"
    }
    
    private func mapWechatCategory(_ category: String) -> String {
        let mapping: [String: String] = [
            "商户消费": "购物",
            "扫二维码付款": "购物",
            "转账": "其他",
            "微信红包": "其他",
            "群收款": "其他",
        ]
        
        return mapping[category] ?? "其他"
    }
    
    // MARK: - 导入到数据库
    func importTransactions(_ transactions: [ImportedTransaction], 
                           context: ModelContext,
                           categories: [Category],
                           defaultAccountId: UUID?) {
        for imported in transactions where imported.isSelected {
            // 查找匹配的分类
            let categoryId = categories.first(where: { 
                $0.name == imported.categoryName && $0.type == imported.type 
            })?.id ?? categories.first(where: { 
                $0.name == "其他" && $0.type == imported.type 
            })?.id
            
            let transaction = Transaction(
                amount: imported.amount,
                type: imported.type,
                categoryId: categoryId,
                accountId: defaultAccountId,
                date: imported.date,
                note: imported.note
            )
            
            context.insert(transaction)
        }
        
        try? context.save()
    }
}
