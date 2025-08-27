import Foundation
import SwiftUI

// MARK: - Data Load Errors

enum DataLoadError: LocalizedError {
    case fileNotFound(String)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return "File not found: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Data Manager

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var categories: [KnotCategory] = []
    @Published var knotTypes: [KnotCategory] = []
    @Published var allKnots: [KnotDetail] = []
    @Published var favoriteKnots: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let favoritesKey = "FavoriteKnots"
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard !isLoading else { return } // 防止重复加载
        
        Task { @MainActor in
            isLoading = true
            errorMessage = nil
            
            do {
                // 并行加载数据
                async let categoriesTask = loadKnotCategoriesAsync()
                async let knotsTask = loadAllKnotsAsync()
                
                let (categoriesResult, knotsResult) = await (categoriesTask, knotsTask)
                
                // 处理分类数据结果
                switch categoriesResult {
                case .success(let knotCategories):
                    categories = knotCategories.filter { $0.type == "category" }
                    knotTypes = knotCategories.filter { $0.type == "type" }
                    print("✅ 成功加载分类数据: \(categories.count) 个分类, \(knotTypes.count) 个类型")
                case .failure(let error):
                    errorMessage = "分类数据加载失败: \(error.localizedDescription)"
                    print("❌ 分类数据加载失败: \(error)")
                }
                
                // 处理绳结数据结果
                switch knotsResult {
                case .success(let knotsData):
                    allKnots = knotsData.knots
                    print("✅ 成功加载绳结数据: \(allKnots.count) 个绳结")
                case .failure(let error):
                    errorMessage = "绳结数据加载失败: \(error.localizedDescription)"
                    print("❌ 绳结数据加载失败: \(error)")
                }
                
            } catch {
                errorMessage = "数据加载异常: \(error.localizedDescription)"
                print("❌ 数据加载异常: \(error)")
            }
            
            isLoading = false
        }
    }
    
    // 异步加载分类数据
    private func loadKnotCategoriesAsync() async -> Result<[KnotCategory], Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.syncLoadKnotCategories()
                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    // 异步加载绳结数据
    private func loadAllKnotsAsync() async -> Result<AllKnotsData, Error> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try self.syncLoadAllKnots()
                    continuation.resume(returning: .success(result))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    // 同步版本的加载方法（用于异步调用）
    private func syncLoadKnotCategories() throws -> [KnotCategory] {
        // 先尝试在Resources根目录查找
        if let path = Bundle.main.path(forResource: "knots_data", ofType: "json", inDirectory: "Resources") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 备选：在Resources/category目录查找
        if let path = Bundle.main.path(forResource: "knots_data", ofType: "json", inDirectory: "Resources/category") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 最后尝试：不指定目录
        if let path = Bundle.main.path(forResource: "knots_data", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        throw DataLoadError.fileNotFound("knots_data.json not found in any expected location")
    }
    
    private func syncLoadAllKnots() throws -> AllKnotsData {
        // 先尝试在Resources根目录查找
        if let path = Bundle.main.path(forResource: "all_knots_data", ofType: "json", inDirectory: "Resources") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        // 备选：不指定目录
        if let path = Bundle.main.path(forResource: "all_knots_data", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        throw DataLoadError.fileNotFound("all_knots_data.json not found in any expected location")
    }
    
    // 保留旧版本方法作为同步备用
    private func loadKnotCategories() {
        guard let path = Bundle.main.path(forResource: "knots_data", ofType: "json", inDirectory: "Resources/category"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let knotCategories = try? JSONDecoder().decode([KnotCategory].self, from: data) else {
            errorMessage = LocalizedStrings.Errors.loadData
            return
        }
        
        // 分离用途分类和绳结类型
        categories = knotCategories.filter { $0.type == "category" }
        knotTypes = knotCategories.filter { $0.type == "type" }
    }
    
    private func loadAllKnots() {
        guard let path = Bundle.main.path(forResource: "all_knots_data", ofType: "json", inDirectory: "Resources"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let allKnotsData = try? JSONDecoder().decode(AllKnotsData.self, from: data) else {
            errorMessage = LocalizedStrings.Errors.loadData
            return
        }
        
        allKnots = allKnotsData.knots
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(_ knotId: String) {
        if favoriteKnots.contains(knotId) {
            favoriteKnots.remove(knotId)
        } else {
            favoriteKnots.insert(knotId)
        }
        saveFavorites()
    }
    
    func isFavorite(_ knotId: String) -> Bool {
        return favoriteKnots.contains(knotId)
    }
    
    func getFavoriteKnots() -> [KnotDetail] {
        return allKnots.filter { favoriteKnots.contains($0.id) }
    }
    
    private func saveFavorites() {
        let favoritesArray = Array(favoriteKnots)
        UserDefaults.standard.set(favoritesArray, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        let favoritesArray = UserDefaults.standard.array(forKey: favoritesKey) as? [String] ?? []
        favoriteKnots = Set(favoritesArray)
    }
    
    // MARK: - Search Functions
    
    func searchInCategories(_ query: String) -> [KnotCategory] {
        guard !query.isEmpty else { return categories }
        
        let lowercaseQuery = query.lowercased()
        return categories.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.desc.lowercased().contains(lowercaseQuery)
        }
    }
    
    func searchInTypes(_ query: String) -> [KnotCategory] {
        guard !query.isEmpty else { return knotTypes }
        
        let lowercaseQuery = query.lowercased()
        return knotTypes.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.desc.lowercased().contains(lowercaseQuery)
        }
    }
    
    func searchInFavorites(_ query: String) -> [KnotDetail] {
        let favorites = getFavoriteKnots()
        guard !query.isEmpty else { return favorites }
        
        let lowercaseQuery = query.lowercased()
        return favorites.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery)
        }
    }
    
    func searchAllKnots(_ query: String) -> [KnotDetail] {
        guard !query.isEmpty else { return [] }
        
        let lowercaseQuery = query.lowercased()
        return allKnots.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.description.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Helper Functions
    
    func getKnotsByCategory(_ categoryName: String) -> [KnotDetail] {
        return allKnots.filter { knot in
            knot.classification.foundIn.contains(categoryName)
        }
    }
    
    func getKnotsByType(_ typeName: String) -> [KnotDetail] {
        return allKnots.filter { knot in
            knot.classification.type.contains(typeName)
        }
    }
    
    func getKnotById(_ id: String) -> KnotDetail? {
        return allKnots.first { $0.id == id }
    }
    
    // MARK: - Image Path Resolution
    
    /// 图片路径缓存
    private var imagePathCache: [String: String?] = [:]
    private let cacheQueue = DispatchQueue(label: "com.knots3d.imageCache", attributes: .concurrent)
    
    func getImagePath(for imageName: String) -> String? {
        return cacheQueue.sync {
            // 检查缓存
            if let cachedPath = imagePathCache[imageName] {
                return cachedPath
            }
            
            let path = findImagePath(for: imageName)
            
            // 使用barrier确保写操作线程安全
            cacheQueue.async(flags: .barrier) { [weak self] in
                self?.imagePathCache[imageName] = path
            }
            
            return path
        }
    }
    
    private func findImagePath(for imageName: String) -> String? {
        // 确定文件名和扩展名
        let cleanName = imageName.replacingOccurrences(of: ".jpg", with: "")
                                 .replacingOccurrences(of: ".webp", with: "")
                                 .replacingOccurrences(of: ".png", with: "")
        
        // 可能的扩展名和目录
        let extensions = ["jpg", "webp", "png"]
        let directories = ["Resources/category", "Resources/images", "Resources/sprite"]
        
        for directory in directories {
            for ext in extensions {
                if let path = Bundle.main.path(forResource: cleanName, ofType: ext, inDirectory: directory) {
                    return path
                }
            }
        }
        
        // 如果没找到，尝试不指定目录
        for ext in extensions {
            if let path = Bundle.main.path(forResource: cleanName, ofType: ext) {
                return path
            }
        }
        
        return nil
    }
    
    /// 清空图片路径缓存
    func clearImageCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.imagePathCache.removeAll()
        }
    }
    
    /// 预加载常用图片路径
    func preloadImagePaths() {
        Task {
            // 在主线程获取图片名称列表
            let commonImages = await MainActor.run {
                categories.map { $0.image } + knotTypes.map { $0.image }
            }
            
            // 批量预加载，限制并发数量
            let maxConcurrent = 4
            let semaphore = DispatchSemaphore(value: maxConcurrent)
            
            await withTaskGroup(of: Void.self) { group in
                for imageName in commonImages {
                    group.addTask { [weak self] in
                        semaphore.wait()
                        defer { semaphore.signal() }
                        _ = self?.getImagePath(for: imageName)
                    }
                }
            }
            
            print("✅ 预加载完成: \(commonImages.count) 个图片路径")
        }
    }
}