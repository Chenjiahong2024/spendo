//
//  AutoClassificationService.swift
//  Spendo
//

import Foundation

class AutoClassificationService {
    static let shared = AutoClassificationService()
    
    private init() {}
    
    // 关键词映射表
    private let keywordMapping: [String: [String]] = [
        "餐饮": ["吃饭", "午饭", "晚饭", "早餐", "午餐", "晚餐", "餐厅", "外卖", "美食", "咖啡", "奶茶", "lunch", "dinner", "breakfast", "food", "restaurant"],
        "交通": ["打车", "地铁", "公交", "出租车", "滴滴", "uber", "taxi", "bus", "subway", "加油", "停车"],
        "购物": ["买", "购买", "淘宝", "京东", "商场", "超市", "shopping", "buy"],
        "娱乐": ["电影", "游戏", "ktv", "旅游", "movie", "game", "travel", "entertainment"],
        "医疗": ["医院", "药", "看病", "体检", "hospital", "medicine", "doctor"],
        "教育": ["学费", "书", "课程", "培训", "tuition", "course", "book"],
        "住房": ["房租", "水电", "租金", "rent", "utility"],
        "通讯": ["话费", "流量", "宽带", "phone", "internet"]
    ]
    
    // 根据文本自动推荐类别
    func suggestCategory(for text: String, type: TransactionType, categories: [Category]) -> Category? {
        let lowercasedText = text.lowercased()
        
        // 遍历关键词映射
        for (categoryName, keywords) in keywordMapping {
            for keyword in keywords {
                if lowercasedText.contains(keyword.lowercased()) {
                    // 查找匹配的类别
                    if let category = categories.first(where: { $0.name == categoryName && $0.type == type }) {
                        return category
                    }
                }
            }
        }
        
        return nil
    }
    
    // 学习用户的分类习惯（简化版）
    func learnFromHistory(note: String, category: Category) {
        // 在实际应用中，可以将用户的手动分类存储到本地
        // 并用于后续的智能推荐
        // 这里只是一个框架示例
        print("学习分类: \(note) -> \(category.name)")
    }
    
    // 基于历史记录预测类别
    func predictCategory(amount: Double, note: String, transactions: [Transaction], categories: [Category]) -> Category? {
        // 简化版：查找相似金额和备注的历史记录
        let similarTransactions = transactions.filter { transaction in
            abs(transaction.amount - amount) < 10 &&
            !transaction.note.isEmpty &&
            transaction.note.lowercased().contains(note.lowercased()[..<min(note.count, 3)].lowercased())
        }
        
        if let mostCommonCategoryId = mostFrequent(categoryIds: similarTransactions.compactMap { $0.categoryId }) {
            return categories.first { $0.id == mostCommonCategoryId }
        }
        
        return suggestCategory(for: note, type: .expense, categories: categories)
    }
    
    // 找出最常见的类别ID
    private func mostFrequent(categoryIds: [UUID]) -> UUID? {
        var counts: [UUID: Int] = [:]
        
        for id in categoryIds {
            counts[id, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// String 扩展
extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    subscript(bounds: PartialRangeUpTo<Int>) -> String {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[startIndex..<end])
    }
}
