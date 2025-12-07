//
//  OCRScannerView.swift
//  Spendo
//

import SwiftUI
import VisionKit
import Vision

// 小票识别结果数据模型
struct ReceiptData {
    var amount: Double?
    var currency: String = "CNY"
    var date: Date?
    var merchant: String?
    var items: [String] = []
    var note: String?
}

struct OCRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedImage: UIImage?
    @State private var receiptData = ReceiptData()
    @State private var isProcessing = false
    @State private var showImagePicker = false
    @State private var allRecognizedText: [String] = []
    
    let onReceiptScanned: (ReceiptData) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendoTheme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 图片预览区域
                        if let image = scannedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 60))
                                    .foregroundColor(SpendoTheme.textTertiary)
                                Text("tap_to_scan".localized)
                                    .font(.system(size: 15))
                                    .foregroundColor(SpendoTheme.textSecondary)
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(16)
                        }
                        
                        if isProcessing {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("recognizing".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(SpendoTheme.textSecondary)
                            }
                            .padding(.vertical, 30)
                        } else if receiptData.amount != nil {
                            // 识别结果展示
                            VStack(spacing: 16) {
                                Text("recognition_result".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(SpendoTheme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // 金额
                                ReceiptInfoRow(
                                    icon: "yensign.circle.fill",
                                    title: "amount".localized,
                                    value: String(format: "%@%.2f", receiptData.currency == "CNY" ? "¥" : "$", receiptData.amount ?? 0),
                                    valueColor: SpendoTheme.accentGreen
                                )
                                
                                // 货币
                                ReceiptInfoRow(
                                    icon: "dollarsign.circle.fill",
                                    title: "currency".localized,
                                    value: receiptData.currency,
                                    valueColor: SpendoTheme.textPrimary
                                )
                                
                                // 日期
                                if let date = receiptData.date {
                                    ReceiptInfoRow(
                                        icon: "calendar.circle.fill",
                                        title: "date".localized,
                                        value: formatDate(date),
                                        valueColor: SpendoTheme.textPrimary
                                    )
                                }
                                
                                // 商家
                                if let merchant = receiptData.merchant, !merchant.isEmpty {
                                    ReceiptInfoRow(
                                        icon: "storefront.circle.fill",
                                        title: "merchant".localized,
                                        value: merchant,
                                        valueColor: SpendoTheme.textPrimary
                                    )
                                }
                                
                                // 备注/商品
                                if let note = receiptData.note, !note.isEmpty {
                                    ReceiptInfoRow(
                                        icon: "text.bubble.fill",
                                        title: "note".localized,
                                        value: note,
                                        valueColor: SpendoTheme.textSecondary
                                    )
                                }
                            }
                            .padding()
                            .background(SpendoTheme.cardBackground)
                            .cornerRadius(16)
                        }
                        
                        Spacer().frame(height: 20)
                        
                        // 操作按钮
                        VStack(spacing: 12) {
                            Button(action: { showImagePicker = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                    Text(scannedImage == nil ? "拍摄/选择小票" : "重新扫描")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(SpendoTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SpendoTheme.cardBackground)
                                .cornerRadius(12)
                            }
                            
                            // 模拟识别按钮（用于演示）
                            Button(action: { simulateOCR() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 16))
                                    Text("模拟识别")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(SpendoTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(SpendoTheme.cardBackground.opacity(0.5))
                                .cornerRadius(12)
                            }
                            
                            if receiptData.amount != nil {
                                Button(action: {
                                    onReceiptScanned(receiptData)
                                    dismiss()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                        Text("使用识别结果")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(SpendoTheme.primary)
                                    .cornerRadius(14)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ocr_scan".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .foregroundColor(SpendoTheme.textPrimary)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $scannedImage, onImagePicked: { image in
                    if let img = image {
                        performOCR(on: img)
                    }
                })
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    // 模拟OCR识别（用于演示）
    private func simulateOCR() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // 模拟识别结果
            let merchants = ["星巴克", "麦当劳", "全家便利店", "盒马鲜生", "美团外卖", "滴滴出行"]
            let items = ["拿铁咖啡", "午餐套餐", "日用品", "水果蔬菜", "晚餐外卖", "打车费用"]
            let randomIndex = Int.random(in: 0..<merchants.count)
            
            receiptData = ReceiptData(
                amount: Double.random(in: 15...200).rounded() + Double.random(in: 0...99) / 100,
                currency: "CNY",
                date: Date().addingTimeInterval(-Double.random(in: 0...86400)),
                merchant: merchants[randomIndex],
                items: [items[randomIndex]],
                note: items[randomIndex]
            )
            isProcessing = false
        }
    }
    
    // 真实的OCR识别实现
    private func performOCR(on image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        isProcessing = true
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                self.allRecognizedText = recognizedStrings
                self.parseReceiptData(from: recognizedStrings)
                self.isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("OCR识别失败: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    // 解析小票数据
    private func parseReceiptData(from texts: [String]) {
        var data = ReceiptData()
        let fullText = texts.joined(separator: " ")
        
        // 提取金额
        data.amount = extractAmount(from: fullText)
        
        // 提取货币
        data.currency = extractCurrency(from: fullText)
        
        // 提取日期
        data.date = extractDate(from: fullText)
        
        // 提取商家名称（通常在第一行或包含特定关键词）
        data.merchant = extractMerchant(from: texts)
        
        // 提取商品/备注
        data.note = extractNote(from: texts)
        
        receiptData = data
    }
    
    // 提取金额
    private func extractAmount(from text: String) -> Double? {
        let patterns = [
            "(?:合计|总计|实付|应付|金额)[：:￥¥$]*\\s*(\\d+\\.?\\d*)",
            "(?:Total|Amount)[：:]*\\s*[￥¥$]?(\\d+\\.?\\d*)",
            "[￥¥](\\d+\\.?\\d*)",
            "CNY\\s*(\\d+\\.?\\d*)",
            "\\$(\\d+\\.?\\d*)",
            "(\\d+\\.\\d{2})(?:元|$)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: text),
                   let amount = Double(text[swiftRange]) {
                    return amount
                }
            }
        }
        
        return nil
    }
    
    // 提取货币类型
    private func extractCurrency(from text: String) -> String {
        if text.contains("$") || text.lowercased().contains("usd") {
            return "USD"
        } else if text.contains("€") || text.lowercased().contains("eur") {
            return "EUR"
        } else if text.contains("£") || text.lowercased().contains("gbp") {
            return "GBP"
        }
        return "CNY"
    }
    
    // 提取日期
    private func extractDate(from text: String) -> Date? {
        let datePatterns = [
            "\\d{4}[-/年]\\d{1,2}[-/月]\\d{1,2}日?\\s*\\d{1,2}:\\d{2}",
            "\\d{4}[-/年]\\d{1,2}[-/月]\\d{1,2}日?",
            "\\d{1,2}[-/月]\\d{1,2}日?\\s*\\d{1,2}:\\d{2}",
            "\\d{1,2}/\\d{1,2}/\\d{4}"
        ]
        
        let formatters = [
            "yyyy-MM-dd HH:mm",
            "yyyy/MM/dd HH:mm",
            "yyyy年MM月dd日 HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yyyy年MM月dd日",
            "MM-dd HH:mm",
            "MM/dd HH:mm",
            "MM/dd/yyyy"
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                let range = match.range
                if let swiftRange = Range(range, in: text) {
                    let dateString = String(text[swiftRange])
                        .replacingOccurrences(of: "年", with: "-")
                        .replacingOccurrences(of: "月", with: "-")
                        .replacingOccurrences(of: "日", with: "")
                    
                    for format in formatters {
                        let formatter = DateFormatter()
                        formatter.dateFormat = format
                        formatter.locale = Locale(identifier: "zh_CN")
                        if let date = formatter.date(from: dateString) {
                            return date
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // 提取商家名称
    private func extractMerchant(from texts: [String]) -> String? {
        // 通常商家名称在前几行
        for (_, text) in texts.prefix(5).enumerated() {
            // 跳过太短或只是数字的行
            if text.count >= 2 && !text.allSatisfy({ $0.isNumber || $0 == "." || $0 == "-" }) {
                // 跳过包含金额关键词的行
                if !text.contains("合计") && !text.contains("总计") && !text.contains("金额") {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }
    
    // 提取备注
    private func extractNote(from texts: [String]) -> String? {
        // 查找商品名称或描述
        var items: [String] = []
        
        for text in texts {
            // 跳过日期、金额等行
            if text.contains("¥") || text.contains("￥") || text.contains("合计") || text.contains("总计") {
                continue
            }
            if text.contains(":") && (text.contains("日期") || text.contains("时间")) {
                continue
            }
            // 可能是商品名称
            if text.count >= 2 && text.count <= 20 {
                items.append(text)
            }
        }
        
        // 返回前几个可能的商品名称
        if !items.isEmpty {
            return items.prefix(3).joined(separator: ", ")
        }
        return nil
    }
}

// 识别结果行组件
struct ReceiptInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(SpendoTheme.primary)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(SpendoTheme.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(valueColor)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImagePicked: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    OCRScannerView { data in
        print("识别数据: \(data)")
    }
}
