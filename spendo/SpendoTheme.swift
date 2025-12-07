import SwiftUI
import Combine

// MARK: - 主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // 可用的主题色
    static let themeColors: [Color] = [
        Color(red: 255/255, green: 90/255, blue: 68/255),   // 橙红
        Color.blue,                                          // 蓝色
        Color.green,                                         // 绿色
        Color.purple,                                        // 紫色
        Color.pink,                                          // 粉色
    ]
    
    @Published var accentColorIndex: Int {
        didSet {
            UserDefaults.standard.set(accentColorIndex, forKey: "accentColorIndex")
        }
    }
    
    @Published var iconStyle: Int {
        didSet {
            UserDefaults.standard.set(iconStyle, forKey: "iconStyle")
        }
    }
    
    @Published var animationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(animationsEnabled, forKey: "animationsEnabled")
        }
    }
    
    // TabBar 样式: 0=系统样式, 1=自定义样式
    @Published var tabBarStyle: Int {
        didSet {
            UserDefaults.standard.set(tabBarStyle, forKey: "tabBarStyle")
        }
    }
    
    // 是否使用自定义 TabBar
    var useCustomTabBar: Bool {
        tabBarStyle == 1
    }
    
    private init() {
        self.accentColorIndex = UserDefaults.standard.integer(forKey: "accentColorIndex")
        self.iconStyle = UserDefaults.standard.integer(forKey: "iconStyle")
        self.animationsEnabled = UserDefaults.standard.object(forKey: "animationsEnabled") as? Bool ?? true
        self.tabBarStyle = UserDefaults.standard.integer(forKey: "tabBarStyle") // 默认0=系统样式
    }
    
    // 当前主题色
    var currentAccentColor: Color {
        guard accentColorIndex >= 0 && accentColorIndex < Self.themeColors.count else {
            return Self.themeColors[0]
        }
        return Self.themeColors[accentColorIndex]
    }
    
    // 是否使用填充图标
    var useFilledIcons: Bool {
        iconStyle == 0
    }
    
    // 获取图标名称（根据风格）
    func iconName(_ baseName: String) -> String {
        if useFilledIcons {
            // 如果基础名称已经包含 .fill，直接返回
            if baseName.hasSuffix(".fill") {
                return baseName
            }
            return "\(baseName).fill"
        } else {
            // 移除 .fill 后缀
            return baseName.replacingOccurrences(of: ".fill", with: "")
        }
    }
}

struct SpendoTheme {
    // 主色调 - 动态获取
    static var primary: Color {
        ThemeManager.shared.currentAccentColor
    }
    
    static var primaryGradient: LinearGradient {
        let baseColor = ThemeManager.shared.currentAccentColor
        return LinearGradient(
            colors: [baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 深色背景
    static let background = Color.black
    static let cardBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let cardBackgroundLight = Color(red: 44/255, green: 44/255, blue: 46/255)
    
    // 强调色
    static let accentGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let accentRed = Color(red: 255/255, green: 69/255, blue: 58/255)
    static var accentOrange: Color {
        ThemeManager.shared.currentAccentColor
    }
    
    // 文字颜色
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textTertiary = Color(white: 0.4)
    
    // 圆角
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
    
    static let shadowColor = Color.black.opacity(0.3)
    
    // 动画开关
    static var animationsEnabled: Bool {
        ThemeManager.shared.animationsEnabled
    }
}

// Color 扩展：支持 Hex 颜色转换
extension Color {
    // 从 Hex 字符串创建 Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // 转换为 Hex 字符串
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else {
            return "#000000"
        }
        
        let r: CGFloat = components.count >= 1 ? components[0] : 0
        let g: CGFloat = components.count >= 2 ? components[1] : 0
        let b: CGFloat = components.count >= 3 ? components[2] : 0
        
        return String(format: "#%02lX%02lX%02lX",
                      lroundf(Float(r * 255)),
                      lroundf(Float(g * 255)),
                      lroundf(Float(b * 255)))
    }
}
