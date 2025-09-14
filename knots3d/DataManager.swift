import Foundation
import SwiftUI
import Combine

// MARK: - Data Load Errors

enum DataLoadError: LocalizedError {
    case fileNotFound(String)
    case decodingError(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return "\(LocalizedStrings.DataErrors.fileNotFound.localized): \(message)"
        case .decodingError(let message):
            return "\(LocalizedStrings.DataErrors.decodingError.localized): \(message)"
        case .networkError(let message):
            return "\(LocalizedStrings.DataErrors.networkError.localized): \(message)"
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
    @Published var isPro: Bool = false
    
    private let favoritesKey = "FavoriteKnots"
    private let proStatusKey = "IsProVersion"
    private var languageObserver: AnyCancellable?
    
    private init() {
        loadFavorites()
        loadProStatus()
        setupLanguageObserver()
    }
    
    // MARK: - Language Observer Setup
    
    private func setupLanguageObserver() {
        languageObserver = LanguageManager.shared.$currentLanguage
            .removeDuplicates()
            .sink { [weak self] _ in
                Task { @MainActor in
                    // 语言切换时重新加载所有数据
                    self?.reloadDataForLanguageChange()
                }
            }
    }
    
    private func reloadDataForLanguageChange() {
        guard !categories.isEmpty || !allKnots.isEmpty else { return } // 只有在已有数据时才重新加载
        
        Task { @MainActor in
            // 并行加载分类和绳结数据
            async let categoriesTask = loadKnotCategoriesAsync()
            async let knotsTask = loadAllKnotsAsync()
            
            let (categoriesResult, knotsResult) = await (categoriesTask, knotsTask)
            
            // 处理分类数据结果
            switch categoriesResult {
            case .success(let knotCategories):
                categories = knotCategories.filter { $0.type == "category" }
                knotTypes = knotCategories.filter { $0.type == "type" }
            case .failure(let error):
                errorMessage = "\(LocalizedStrings.DataErrors.categoriesLoadFailed.localized): \(error.localizedDescription)"
            }
            
            // 处理绳结数据结果
            switch knotsResult {
            case .success(let knotsData):
                allKnots = knotsData.knots
            case .failure(let error):
                // 如果分类数据没有错误，则不覆盖错误消息
                if errorMessage == nil {
                    errorMessage = "\(LocalizedStrings.DataErrors.knotsLoadFailed.localized): \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        guard !isLoading else { 
            return 
        }
        
        Task { @MainActor in
            let startTime = CFAbsoluteTimeGetCurrent()
            
            isLoading = true
            errorMessage = nil
            
            // 并行加载数据
            async let categoriesTask = loadKnotCategoriesAsync()
            async let knotsTask = loadAllKnotsAsync()
            
            let (categoriesResult, knotsResult) = await (categoriesTask, knotsTask)
            // 处理分类数据结果
            switch categoriesResult {
            case .success(let knotCategories):
                categories = knotCategories.filter { $0.type == "category" }
                knotTypes = knotCategories.filter { $0.type == "type" }
            case .failure(let error):
                errorMessage = "\(LocalizedStrings.DataErrors.categoriesLoadFailed.localized): \(error.localizedDescription)"
            }
            
            // 处理绳结数据结果
            switch knotsResult {
            case .success(let knotsData):
                allKnots = knotsData.knots
            case .failure(let error):
                errorMessage = "\(LocalizedStrings.DataErrors.knotsLoadFailed.localized): \(error.localizedDescription)"
            }
            
            isLoading = false
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let loadTime = endTime - startTime
        }
    }
    
    // 异步加载分类数据
    private func loadKnotCategoriesAsync() async -> Result<[KnotCategory], Error> {
        return await Task.detached { [weak self] in
            let startTime = CFAbsoluteTimeGetCurrent()
            guard let self = self else {
                return .failure(DataLoadError.networkError(LocalizedStrings.DataErrors.dataManagerReleased.localized))
            }
            do {
                let result = try self.syncLoadKnotCategories()
                let loadTime = CFAbsoluteTimeGetCurrent() - startTime
                return .success(result)
            } catch {
                return .failure(error)
            }
        }.value
    }
    
    // 异步加载绳结数据
    private func loadAllKnotsAsync() async -> Result<AllKnotsData, Error> {
        return await Task.detached { [weak self] in
            guard let self = self else {
                return .failure(DataLoadError.networkError(LocalizedStrings.DataErrors.dataManagerReleased.localized))
            }
            do {
                let result = try self.syncLoadAllKnots()
                return .success(result)
            } catch {
                return .failure(error)
            }
        }.value
    }
    
    // 同步版本的加载方法（用于异步调用）
    private func syncLoadKnotCategories() throws -> [KnotCategory] {
        let currentLanguage = LanguageManager.shared.currentLanguage
        let localizedFileName = "category_\(currentLanguage)"
        
        // 先尝试加载多语言版本的JSON文件，查找Resources/json目录
        if let path = Bundle.main.path(forResource: localizedFileName, ofType: "json", inDirectory: "Resources/json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 备用：不指定目录查找
        if let path = Bundle.main.path(forResource: localizedFileName, ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 如果找不到对应语言的文件，回退到默认的category.json
        
        // 先尝试在Resources根目录查找
        if let path = Bundle.main.path(forResource: "category", ofType: "json", inDirectory: "Resources") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 备选：在Resources/category目录查找
        if let path = Bundle.main.path(forResource: "category", ofType: "json", inDirectory: "Resources/category") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        // 最后尝试：不指定目录
        if let path = Bundle.main.path(forResource: "category", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let knotCategories = try JSONDecoder().decode([KnotCategory].self, from: data)
            return knotCategories
        }
        
        throw DataLoadError.fileNotFound("category.json not found in any expected location")
    }
    
    private func syncLoadAllKnots() throws -> AllKnotsData {
        let currentLanguage = LanguageManager.shared.currentLanguage
        let localizedFileName = "detailed_knots_data_\(currentLanguage)"
        
        // 先尝试加载多语言版本的JSON文件，查找Resources/detail目录
        if let path = Bundle.main.path(forResource: localizedFileName, ofType: "json", inDirectory: "Resources/detail") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        // 备用：不指定目录查找
        if let path = Bundle.main.path(forResource: localizedFileName, ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        
        // 先尝试在Resources根目录查找
        if let path = Bundle.main.path(forResource: "detailed_knots_data", ofType: "json", inDirectory: "Resources") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        // 备选：不指定目录
        if let path = Bundle.main.path(forResource: "detailed_knots_data", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let allKnotsData = try JSONDecoder().decode(AllKnotsData.self, from: data)
            return allKnotsData
        }
        
        throw DataLoadError.fileNotFound("detailed_knots_data.json not found in any expected location")
    }
    
    // 保留旧版本方法作为同步备用
    private func loadKnotCategories() {
        guard let path = Bundle.main.path(forResource: "category", ofType: "json", inDirectory: "Resources/category"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let knotCategories = try? JSONDecoder().decode([KnotCategory].self, from: data) else {
            errorMessage = LocalizedStrings.Errors.loadData.localized
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
            errorMessage = LocalizedStrings.Errors.loadData.localized
            return
        }
        
        allKnots = allKnotsData.knots
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(_ knotId: String) {
        let wasNotFavorite = !favoriteKnots.contains(knotId)
        
        if favoriteKnots.contains(knotId) {
            favoriteKnots.remove(knotId)
        } else {
            favoriteKnots.insert(knotId)
        }
        saveFavorites()
        
        // 如果是添加到收藏（而不是取消收藏），则请求评分
        if wasNotFavorite {
            ReviewRequestManager.shared.requestReviewIfAppropriate()
        }
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
    
    // MARK: - Pro Status Management
    
    private func loadProStatus() {
        // 对于2.0版本及之前的版本，默认设置为Pro用户
        if !UserDefaults.standard.bool(forKey: "HasSetProStatus") {
            // 第一次启动，设置为Pro版本
            isPro = true
            UserDefaults.standard.set(true, forKey: proStatusKey)
            UserDefaults.standard.set(true, forKey: "HasSetProStatus")
        } else {
            // 已经设置过，读取保存的状态
            isPro = UserDefaults.standard.bool(forKey: proStatusKey)
        }
    }
    
    func setProStatus(_ status: Bool) {
        isPro = status
        UserDefaults.standard.set(status, forKey: proStatusKey)
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
    
    func getKnotsByNames(_ names: [String]) -> [KnotDetail] {
        return allKnots.filter { knot in
            names.contains { name in
                knot.name.localizedCaseInsensitiveContains(name) ||
                (knot.aliases?.contains(name) == true)
            }
        }
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
            
            // 批量预加载，使用 TaskGroup 限制并发数量
            let maxConcurrent = 4
            let chunks = commonImages.chunked(into: maxConcurrent)
            
            for chunk in chunks {
                await withTaskGroup(of: Void.self) { group in
                    for imageName in chunk {
                        group.addTask { [weak self] in
                            _ = self?.getImagePath(for: imageName)
                        }
                    }
                }
            }
            
        }
    }
    
}