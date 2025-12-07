//
//  AccountPreset.swift
//  Spendo
//
//  预设账户类型和常用中国支付平台

import SwiftUI

// 预设账户信息
struct AccountPreset: Identifiable {
    let id = UUID()
    let name: String
    let type: AccountType
    let iconName: String
    let iconColor: Color
    let iconBackgroundColor: Color
    let category: AccountPresetCategory
    
    // 是否使用网络图标（可扩展为从GitHub图标库加载）
    var iconURL: String? = nil
}

// 预设账户分类
enum AccountPresetCategory: String, CaseIterable {
    case cash = "现金钱包"
    case bank = "银行账户"
    case alipay = "支付宝"
    case wechat = "微信"
    case other = "其他平台"
    
    var displayName: String { rawValue }
}

// 预设账户数据
struct AccountPresets {
    
    // 所有预设账户
    static let all: [AccountPreset] = cash + bank + alipay + wechat + other
    
    // 现金类
    static let cash: [AccountPreset] = [
        AccountPreset(
            name: "现金钱包",
            type: .cash,
            iconName: "dollarsign.circle.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 1.0, green: 0.8, blue: 0.0),
            category: .cash
        ),
    ]
    
    // 银行卡类
    static let bank: [AccountPreset] = [
        AccountPreset(
            name: "储蓄卡",
            type: .bankCard,
            iconName: "creditcard.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.2, green: 0.6, blue: 1.0),
            category: .bank
        ),
        AccountPreset(
            name: "信用卡",
            type: .creditCard,
            iconName: "creditcard.trianglebadge.exclamationmark",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.6, green: 0.4, blue: 0.8),
            category: .bank
        ),
        AccountPreset(
            name: "工商银行",
            type: .bankCard,
            iconName: "building.columns.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.8, green: 0.2, blue: 0.2),
            category: .bank
        ),
        AccountPreset(
            name: "建设银行",
            type: .bankCard,
            iconName: "building.columns.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.4, blue: 0.8),
            category: .bank
        ),
        AccountPreset(
            name: "招商银行",
            type: .bankCard,
            iconName: "building.columns.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.9, green: 0.3, blue: 0.3),
            category: .bank
        ),
        AccountPreset(
            name: "农业银行",
            type: .bankCard,
            iconName: "building.columns.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.6, blue: 0.4),
            category: .bank
        ),
    ]
    
    // 支付宝系列
    static let alipay: [AccountPreset] = [
        AccountPreset(
            name: "支付宝",
            type: .digital,
            iconName: "a.circle.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.5, blue: 1.0),
            category: .alipay
        ),
        AccountPreset(
            name: "余额宝",
            type: .investment,
            iconName: "chart.pie.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 1.0, green: 0.5, blue: 0.0),
            category: .alipay
        ),
        AccountPreset(
            name: "余利宝",
            type: .investment,
            iconName: "leaf.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.7, blue: 0.5),
            category: .alipay
        ),
        AccountPreset(
            name: "小荷包",
            type: .digital,
            iconName: "handbag.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 1.0, green: 0.3, blue: 0.3),
            category: .alipay
        ),
        AccountPreset(
            name: "蚂蚁财富",
            type: .investment,
            iconName: "chart.line.uptrend.xyaxis",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.6, blue: 0.9),
            category: .alipay
        ),
        AccountPreset(
            name: "花呗",
            type: .creditCard,
            iconName: "sparkles",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.6, blue: 1.0),
            category: .alipay
        ),
        AccountPreset(
            name: "借呗",
            type: .creditCard,
            iconName: "banknote.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.3, green: 0.5, blue: 0.9),
            category: .alipay
        ),
    ]
    
    // 微信系列
    static let wechat: [AccountPreset] = [
        AccountPreset(
            name: "微信钱包",
            type: .digital,
            iconName: "message.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.7, blue: 0.3),
            category: .wechat
        ),
        AccountPreset(
            name: "微信零钱",
            type: .digital,
            iconName: "yensign.circle.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.75, blue: 0.35),
            category: .wechat
        ),
        AccountPreset(
            name: "微信零钱通",
            type: .investment,
            iconName: "diamond.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 1.0, green: 0.7, blue: 0.0),
            category: .wechat
        ),
        AccountPreset(
            name: "腾讯理财通",
            type: .investment,
            iconName: "chart.bar.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.5, blue: 0.9),
            category: .wechat
        ),
        AccountPreset(
            name: "QQ钱包",
            type: .digital,
            iconName: "ellipsis.bubble.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.6, blue: 0.95),
            category: .wechat
        ),
    ]
    
    // 其他平台
    static let other: [AccountPreset] = [
        AccountPreset(
            name: "抖音钱包",
            type: .digital,
            iconName: "music.note",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.1, green: 0.1, blue: 0.1),
            category: .other
        ),
        AccountPreset(
            name: "京东白条",
            type: .creditCard,
            iconName: "bag.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.9, green: 0.2, blue: 0.2),
            category: .other
        ),
        AccountPreset(
            name: "京东金融",
            type: .investment,
            iconName: "chart.xyaxis.line",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.9, green: 0.3, blue: 0.3),
            category: .other
        ),
        AccountPreset(
            name: "美团",
            type: .digital,
            iconName: "fork.knife",
            iconColor: .black,
            iconBackgroundColor: Color(red: 1.0, green: 0.85, blue: 0.0),
            category: .other
        ),
        AccountPreset(
            name: "饿了么",
            type: .digital,
            iconName: "takeoutbag.and.cup.and.straw.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.0, green: 0.6, blue: 0.9),
            category: .other
        ),
        AccountPreset(
            name: "滴滴出行",
            type: .digital,
            iconName: "car.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 1.0, green: 0.5, blue: 0.0),
            category: .other
        ),
        AccountPreset(
            name: "公积金",
            type: .other,
            iconName: "house.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.2, green: 0.6, blue: 0.4),
            category: .other
        ),
        AccountPreset(
            name: "医保账户",
            type: .other,
            iconName: "cross.case.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.3, green: 0.7, blue: 0.4),
            category: .other
        ),
        AccountPreset(
            name: "自定义账户",
            type: .other,
            iconName: "plus.circle.fill",
            iconColor: .white,
            iconBackgroundColor: Color(red: 0.5, green: 0.5, blue: 0.5),
            category: .other
        ),
    ]
    
    // 按分类获取
    static func presets(for category: AccountPresetCategory) -> [AccountPreset] {
        all.filter { $0.category == category }
    }
}
