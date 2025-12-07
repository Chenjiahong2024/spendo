# Spendo - 极简记账App

一款专为iOS设计的记账应用，具有简洁的界面和强大的数据分析功能。

## 系统要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## 核心功能

### 1. 快速记账
- ✅ 一键添加收入/支出
- ✅ 自动分类建议
- ✅ 多账户管理
- ✅ 语音输入记账
- ✅ 扫描小票识别

### 2. 数据分析
- ✅ 收支统计饼图
- ✅ 趋势折线图
- ✅ AI智能洞察
- ✅ 按周/月/年分析

### 3. 预算管理
- ✅ 设置总预算
- ✅ 分类预算
- ✅ 实时进度追踪
- ✅ 超预算提醒

### 4. 多账户支持
- ✅ 现金、银行卡、电子账户
- ✅ 自动余额计算
- ✅ 账户间转账记录

### 5. 高级功能
- ✅ 多币种支持
- ✅ 自动分类引擎
- ✅ 数据导出CSV
- ✅ 暗色模式

## 项目结构

```
spendo/
├── SpendoApp.swift              # 应用入口
├── Models/                       # 数据模型
│   ├── Transaction.swift
│   ├── Category.swift
│   ├── Account.swift
│   ├── Budget.swift
│   └── UserSettings.swift
├── Views/                        # 视图
│   ├── MainTabView.swift
│   ├── OnboardingView.swift
│   ├── DashboardView.swift
│   ├── AddTransactionView.swift
│   ├── TransactionListView.swift
│   ├── AnalyticsView.swift
│   ├── BudgetView.swift
│   ├── AccountsView.swift
│   ├── SettingsView.swift
│   ├── VoiceInputView.swift
│   └── OCRScannerView.swift
└── Services/                     # 服务层
    ├── AutoClassificationService.swift
    └── CurrencyService.swift
```

## 安装步骤

1. 克隆项目到本地
```bash
cd ~/Desktop/xcode/spendo
```

2. 在Xcode中打开项目
```bash
open Spendo.xcodeproj
```

3. 选择目标设备或模拟器

4. 按 `Cmd + R` 运行项目

## 使用说明

### 首次使用

1. 打开App后会显示引导页面
2. 选择主币种（默认CNY人民币）
3. 点击"开始使用"进入主界面

### 添加交易

#### 方式1：手动输入
1. 点击底部中间的"+"按钮
2. 输入金额和选择类别
3. 可选：选择账户、添加备注、修改日期
4. 点击"保存"

#### 方式2：语音记账
1. 在添加交易页面点击"语音记账"
2. 说出交易内容，如"午饭50块"
3. 系统自动识别金额和备注

#### 方式3：扫描小票
1. 在添加交易页面点击"扫描小票"
2. 拍摄或选择小票照片
3. 系统自动识别金额

### 查看数据分析

1. 点击底部"统计"标签
2. 切换周期：本周/本月/本年
3. 查看：概览、趋势图、AI洞察

### 设置预算

1. 进入"设置" -> "预算管理"
2. 点击右上角"+"添加预算
3. 输入预算金额和选择周期
4. 可选：选择特定类别

## 技术栈

- **UI**: SwiftUI
- **数据存储**: SwiftData
- **图表**: Swift Charts
- **语音识别**: Speech Framework
- **OCR**: Vision Framework
- **架构**: MVVM

## 权限说明

应用需要以下权限：

- **麦克风权限**: 用于语音记账功能
- **语音识别权限**: 用于识别语音内容
- **相机权限**: 用于扫描小票
- **相册权限**: 用于从相册选择小票

所有权限仅在用户主动使用对应功能时才会请求。

## 数据隐私

- 所有数据存储在本地设备
- 不上传任何个人信息到服务器
- 用户可随时导出或删除数据

## 后续开发计划

- [ ] iCloud云同步
- [ ] Widget小组件
- [ ] Apple Watch支持
- [ ] 数据备份恢复
- [ ] 更多图表类型
- [ ] 账单提醒功能

## 开发者

Spendo Team

## 许可证

MIT License

---

**享受简单高效的记账体验！** 📊💰
