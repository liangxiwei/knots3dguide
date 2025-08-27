import Foundation
import SwiftUI

/// 数据加载测试和调试工具
class DataLoadingTests: ObservableObject {
    static let shared = DataLoadingTests()
    
    @Published var testResults: [String] = []
    @Published var isRunning = false
    
    private init() {}
    
    func runAllTests() {
        isRunning = true
        testResults.removeAll()
        
        testKnotCategoriesLoading()
        testAllKnotsLoading()
        testImagePathResolving()
        testSearchFunctionality()
        testFavoritesManagement()
        
        isRunning = false
    }
    
    private func addResult(_ message: String) {
        DispatchQueue.main.async {
            self.testResults.append(message)
            print("Test: \(message)")
        }
    }
    
    // MARK: - Test Functions
    
    private func testKnotCategoriesLoading() {
        addResult("=== 测试分类数据加载 ===")
        
        // 先尝试在Resources根目录查找
        var path: String?
        if let foundPath = Bundle.main.path(forResource: "knots_data", ofType: "json", inDirectory: "Resources") {
            path = foundPath
        } else if let foundPath = Bundle.main.path(forResource: "knots_data", ofType: "json") {
            path = foundPath
        }
        
        guard let validPath = path else {
            addResult("❌ 无法找到 knots_data.json 文件")
            return
        }
        
        addResult("✅ 找到分类数据文件: \(validPath)")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: validPath))
            let categories = try JSONDecoder().decode([KnotCategory].self, from: data)
            
            let categoryItems = categories.filter { $0.type == "category" }
            let typeItems = categories.filter { $0.type == "type" }
            
            addResult("✅ 成功加载分类数据:")
            addResult("  - 用途分类: \(categoryItems.count) 项")
            addResult("  - 绳结类型: \(typeItems.count) 项")
            
            // 显示前几个分类
            for (index, category) in categoryItems.prefix(3).enumerated() {
                addResult("  [\(index+1)] \(category.name): \(category.desc)")
            }
            
        } catch {
            addResult("❌ 解析分类数据失败: \(error.localizedDescription)")
        }
    }
    
    private func testAllKnotsLoading() {
        addResult("\n=== 测试所有绳结数据加载 ===")
        
        guard let path = Bundle.main.path(forResource: "all_knots_data", ofType: "json", inDirectory: "Resources") else {
            addResult("❌ 无法找到 all_knots_data.json 文件")
            return
        }
        
        addResult("✅ 找到绳结数据文件: \(path)")
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            
            addResult("✅ 成功加载绳结数据:")
            addResult("  - 总数量: \(knotsData.totalKnots) 个绳结")
            addResult("  - 实际数量: \(knotsData.knots.count) 个绳结")
            addResult("  - 提取时间: \(knotsData.extractedAt)")
            
            // 统计分类信息
            let allTypes = knotsData.knots.flatMap { $0.classification.type }
            let uniqueTypes = Set(allTypes)
            let allFoundIn = knotsData.knots.flatMap { $0.classification.foundIn }
            let uniqueFoundIn = Set(allFoundIn)
            
            addResult("  - 涉及类型: \(uniqueTypes.count) 种")
            addResult("  - 应用领域: \(uniqueFoundIn.count) 个")
            
            // 显示前几个绳结
            for (index, knot) in knotsData.knots.prefix(3).enumerated() {
                addResult("  [\(index+1)] \(knot.name): \(knot.description)")
            }
            
        } catch {
            addResult("❌ 解析绳结数据失败: \(error.localizedDescription)")
        }
    }
    
    private func testImagePathResolving() {
        addResult("\n=== 测试图片路径解析 ===")
        
        let testImages = [
            "essential_knots.jpg",
            "munter-hitch.webp", 
            "nonexistent.jpg"
        ]
        
        for imageName in testImages {
            if let path = DataManager.shared.getImagePath(for: imageName) {
                let exists = FileManager.default.fileExists(atPath: path)
                addResult("✅ \(imageName) -> \(exists ? "存在" : "不存在")")
            } else {
                addResult("❌ \(imageName) -> 未找到")
            }
        }
    }
    
    private func testSearchFunctionality() {
        addResult("\n=== 测试搜索功能 ===")
        
        DataManager.shared.loadData()
        
        // 测试分类搜索
        let categoryResults = DataManager.shared.searchInCategories("knot")
        addResult("✅ 分类搜索 'knot': \(categoryResults.count) 个结果")
        
        // 测试类型搜索  
        let typeResults = DataManager.shared.searchInTypes("loop")
        addResult("✅ 类型搜索 'loop': \(typeResults.count) 个结果")
        
        // 测试绳结搜索
        let knotResults = DataManager.shared.searchAllKnots("hitch")
        addResult("✅ 绳结搜索 'hitch': \(knotResults.count) 个结果")
    }
    
    private func testFavoritesManagement() {
        addResult("\n=== 测试收藏功能 ===")
        
        DataManager.shared.loadData()
        
        let testKnotId = "munter"
        
        // 测试添加收藏
        DataManager.shared.toggleFavorite(testKnotId)
        let isFavorite1 = DataManager.shared.isFavorite(testKnotId)
        addResult("✅ 添加收藏: \(isFavorite1 ? "成功" : "失败")")
        
        // 测试移除收藏
        DataManager.shared.toggleFavorite(testKnotId)
        let isFavorite2 = DataManager.shared.isFavorite(testKnotId)
        addResult("✅ 移除收藏: \(!isFavorite2 ? "成功" : "失败")")
        
        // 测试收藏列表
        let favorites = DataManager.shared.getFavoriteKnots()
        addResult("✅ 当前收藏数量: \(favorites.count)")
    }
}

/// 数据测试界面
struct DataTestView: View {
    @StateObject private var testRunner = DataLoadingTests.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Button("运行数据测试") {
                    testRunner.runAllTests()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(testRunner.isRunning ? Color.gray : Color.blue)
                .cornerRadius(8)
                .disabled(testRunner.isRunning)
                
                if testRunner.isRunning {
                    ProgressView("测试运行中...")
                }
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(testRunner.testResults.enumerated()), id: \.offset) { _, result in
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("数据加载测试")
        }
    }
}