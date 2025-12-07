import Foundation

// 时间周期枚举
// 时间周期枚举
enum SpendoTimePeriod: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day: return "今日"
        case .week: return "本周"
        case .month: return "本月"
        case .year: return "本年"
        }
    }
    
    func contains(_ date: Date, relativeTo now: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.isDate(date, inSameDayAs: now)
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}
