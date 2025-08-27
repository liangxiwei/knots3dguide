import Foundation
import SwiftUI

/// 数据验证工具
struct DataValidator {
    static func validateDataIntegrity() async -> ValidationResult {
        var issues: [String] = []
        var success: [String] = []
        
        // 1. 验证分类数据
        do {
            let categories = try await loadKnotCategories()
            let categoryItems = categories.filter { $0.type == "category" }
            let typeItems = categories.filter { $0.type == "type" }
            
            success.append("✅ 分类数据加载成功: \(categoryItems.count) 个分类, \(typeItems.count) 个类型")
            
            // 检查分类图片
            for category in categoryItems + typeItems {
                if !imageExists(category.image) {
                    issues.append("⚠️ 分类图片缺失: \(category.image)")
                }
            }
            
        } catch {
            issues.append("❌ 分类数据加载失败: \(error.localizedDescription)")
        }
        
        // 2. 验证绳结数据
        do {
            let knotsData = try await loadAllKnots()
            success.append("✅ 绳结数据加载成功: \(knotsData.knots.count) 个绳结")
            
            // 统计数据
            let types = Set(knotsData.knots.flatMap { $0.classification.type })
            let categories = Set(knotsData.knots.flatMap { $0.classification.foundIn })
            success.append("✅ 数据统计: \(types.count) 种类型, \(categories.count) 个应用领域")
            
            // 检查绳结图片
            var missingImages = 0
            for knot in knotsData.knots.prefix(10) { // 只检查前10个避免太慢
                if let cover = knot.cover, !imageExists(cover) {
                    missingImages += 1
                }
            }
            
            if missingImages > 0 {
                issues.append("⚠️ 检测到 \(missingImages) 个绳结图片可能缺失（仅检查了前10个）")
            } else {
                success.append("✅ 前10个绳结的图片文件正常")
            }
            
        } catch {
            issues.append("❌ 绳结数据加载失败: \(error.localizedDescription)")
        }
        
        // 3. 验证本地化文件
        let languages = ["zh-Hans", "en"]
        for language in languages {
            if let path = Bundle.main.path(forResource: language, ofType: "lproj", inDirectory: "Resources/locale"),
               FileManager.default.fileExists(atPath: path) {
                success.append("✅ 本地化文件存在: \(language)")
            } else {
                issues.append("⚠️ 本地化文件缺失: \(language)")
            }
        }
        
        return ValidationResult(success: success, issues: issues)
    }
    
    // MARK: - Helper Functions
    
    private static func loadKnotCategories() async throws -> [KnotCategory] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // 先尝试在Resources根目录查找
                    if let path = Bundle.main.path(forResource: "knots_data", ofType: "json", inDirectory: "Resources") {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        let categories = try JSONDecoder().decode([KnotCategory].self, from: data)
                        continuation.resume(returning: categories)
                        return
                    }
                    
                    // 备选：不指定目录
                    if let path = Bundle.main.path(forResource: "knots_data", ofType: "json") {
                        let data = try Data(contentsOf: URL(fileURLWithPath: path))
                        let categories = try JSONDecoder().decode([KnotCategory].self, from: data)
                        continuation.resume(returning: categories)
                        return
                    }
                    
                    throw DataLoadError.fileNotFound("knots_data.json not found in any expected location")
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func loadAllKnots() async throws -> AllKnotsData {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let path = Bundle.main.path(forResource: "all_knots_data", ofType: "json", inDirectory: "Resources") else {
                        throw DataLoadError.fileNotFound("all_knots_data.json")
                    }
                    
                    let data = try Data(contentsOf: URL(fileURLWithPath: path))
                    let knotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
                    continuation.resume(returning: knotsData)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func imageExists(_ imageName: String) -> Bool {
        return DataManager.shared.getImagePath(for: imageName) != nil
    }
}

// MARK: - Validation Result

struct ValidationResult {
    let success: [String]
    let issues: [String]
    
    var isValid: Bool {
        return issues.isEmpty
    }
    
    var hasWarnings: Bool {
        return issues.contains { $0.contains("⚠️") }
    }
    
    var hasErrors: Bool {
        return issues.contains { $0.contains("❌") }
    }
}

// MARK: - Validation View

struct DataValidationView: View {
    @State private var validationResult: ValidationResult?
    @State private var isValidating = false
    
    var body: some View {
        VStack(spacing: 16) {
            Button("开始数据验证") {
                runValidation()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(isValidating ? Color.gray : Color.green)
            .cornerRadius(8)
            .disabled(isValidating)
            
            if isValidating {
                ProgressView("验证中...")
            }
            
            if let result = validationResult {
                resultView(result)
            }
        }
        .padding()
        .navigationTitle("数据完整性验证")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func resultView(_ result: ValidationResult) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                // 成功信息
                if !result.success.isEmpty {
                    ForEach(result.success, id: \.self) { message in
                        Text(message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                    }
                }
                
                // 问题信息
                if !result.issues.isEmpty {
                    ForEach(result.issues, id: \.self) { issue in
                        Text(issue)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(issue.contains("❌") ? .red : .orange)
                            .padding(.horizontal, 8)
                    }
                }
                
                // 总结
                Divider()
                    .padding(.vertical)
                
                HStack {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.isValid ? .green : (result.hasErrors ? .red : .orange))
                    
                    Text(result.isValid ? "数据验证通过" : "发现 \(result.issues.count) 个问题")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func runValidation() {
        isValidating = true
        Task {
            let result = await DataValidator.validateDataIntegrity()
            await MainActor.run {
                validationResult = result
                isValidating = false
            }
        }
    }
}