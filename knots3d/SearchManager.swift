import Foundation
import SwiftUI
import Combine

// MARK: - Search Types

/// 搜索结果类型
enum SearchResultType {
    case category(KnotCategory)
    case knotType(KnotCategory)
    case knot(KnotDetail)
}

/// 绳结匹配类型
enum KnotMatchType {
    case directNameExact        // 绳结名称完全匹配
    case directNamePrefix       // 绳结名称前缀匹配
    case directNameContains     // 绳结名称包含匹配
    case aliasExact            // 别名完全匹配
    case aliasContains         // 别名包含匹配
    case description           // 描述匹配
    case categoryIndirect      // 通过分类间接匹配
    case typeIndirect          // 通过类型间接匹配
    case fuzzy                 // 模糊匹配
}

/// 绳结搜索结果
struct KnotSearchResult: Identifiable {
    let id = UUID()
    let knot: KnotDetail
    let relevanceScore: Double
    let matchedFields: [KnotMatchType]
    let highlightedName: String
    
    /// 获取匹配类型的显示文本
    var matchTypeDescription: String {
        if matchedFields.contains(.directNameExact) || matchedFields.contains(.directNamePrefix) {
            return "名称匹配"
        } else if matchedFields.contains(.aliasExact) || matchedFields.contains(.aliasContains) {
            return "别名匹配"
        } else if matchedFields.contains(.description) {
            return "描述匹配"
        } else if matchedFields.contains(.categoryIndirect) {
            return "分类匹配"
        } else if matchedFields.contains(.typeIndirect) {
            return "类型匹配"
        } else if matchedFields.contains(.fuzzy) {
            return "模糊匹配"
        } else {
            return "匹配"
        }
    }
}

/// 高级搜索结果
struct AdvancedSearchResult: Identifiable {
    let id = UUID()
    let type: SearchResultType
    let relevanceScore: Double
    let highlightedText: String
    
    var title: String {
        switch type {
        case .category(let category), .knotType(let category):
            return category.name
        case .knot(let knot):
            return knot.name
        }
    }
    
    var subtitle: String {
        switch type {
        case .category(let category), .knotType(let category):
            return category.desc
        case .knot(let knot):
            return knot.description
        }
    }
}

/// 搜索配置
struct SearchConfiguration {
    let debounceDelay: TimeInterval = 0.3
    let minSearchLength: Int = 1
    let maxResults: Int = 50
    let enableFuzzySearch: Bool = true
    let enableHighlighting: Bool = true
}

// MARK: - Enhanced Search Manager

class SearchManager: ObservableObject {
    static let shared = SearchManager()
    
    @Published var searchText: String = ""
    @Published var isSearching: Bool = false
    @Published var searchResults: [AdvancedSearchResult] = []
    @Published var searchStats: SearchStats = SearchStats()
    @Published var recentSearches: [String] = []
    
    private let configuration = SearchConfiguration()
    private var searchCancellable: AnyCancellable?
    private var debounceTimer: Timer?
    private let dataManager = DataManager.shared
    
    // 搜索缓存
    private var searchCache: [String: [AdvancedSearchResult]] = [:]
    private let cacheQueue = DispatchQueue(label: "com.knots3d.searchCache", attributes: .concurrent)
    
    init() {
        setupSearchPipeline()
        loadRecentSearches()
    }
    
    // MARK: - Search Pipeline Setup
    
    private func setupSearchPipeline() {
        searchCancellable = $searchText
            .debounce(for: .seconds(configuration.debounceDelay), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
    }
    
    // MARK: - Enhanced Search Functions
    
    private func performSearch(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedQuery.count >= configuration.minSearchLength else {
            searchResults = []
            searchStats = SearchStats()
            return
        }
        
        isSearching = true
        
        // 检查缓存
        if let cachedResults = getFromCache(query: trimmedQuery) {
            DispatchQueue.main.async {
                self.searchResults = cachedResults
                self.updateSearchStats(for: trimmedQuery, results: cachedResults)
                self.isSearching = false
            }
            return
        }
        
        // 异步搜索
        Task {
            let results = await performAdvancedSearch(query: trimmedQuery)
            
            await MainActor.run {
                self.searchResults = Array(results.prefix(self.configuration.maxResults))
                self.updateSearchStats(for: trimmedQuery, results: results)
                self.isSearching = false
                
                // 缓存结果
                self.cacheResults(query: trimmedQuery, results: results)
                
                // 保存搜索历史
                if !results.isEmpty {
                    self.addToRecentSearches(query: trimmedQuery)
                }
            }
        }
    }
    
    private func performAdvancedSearch(query: String) async -> [AdvancedSearchResult] {
        var allResults: [AdvancedSearchResult] = []
        
        // 搜索分类
        let categories = dataManager.categories
        for category in categories {
            if let result = createSearchResult(from: .category(category), query: query) {
                allResults.append(result)
            }
        }
        
        // 搜索类型
        let types = dataManager.knotTypes
        for type in types {
            if let result = createSearchResult(from: .knotType(type), query: query) {
                allResults.append(result)
            }
        }
        
        // 搜索绳结
        let knots = dataManager.allKnots
        for knot in knots {
            if let result = createSearchResult(from: .knot(knot), query: query) {
                allResults.append(result)
            }
        }
        
        // 按相关度排序
        return allResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func createSearchResult(from type: SearchResultType, query: String) -> AdvancedSearchResult? {
        let (title, subtitle) = getTitleAndSubtitle(from: type)
        
        // 计算相关度分数
        let relevanceScore = calculateRelevanceScore(query: query, title: title, subtitle: subtitle)
        guard relevanceScore > 0 else { return nil }
        
        // 生成高亮文本
        let highlightedText = configuration.enableHighlighting 
            ? generateHighlightedText(original: title, query: query)
            : title
        
        return AdvancedSearchResult(
            type: type,
            relevanceScore: relevanceScore,
            highlightedText: highlightedText
        )
    }
    
    private func getTitleAndSubtitle(from type: SearchResultType) -> (String, String) {
        switch type {
        case .category(let category), .knotType(let category):
            return (category.name, category.desc)
        case .knot(let knot):
            return (knot.name, knot.description)
        }
    }
    
    // MARK: - Relevance Scoring
    
    private func calculateRelevanceScore(query: String, title: String, subtitle: String) -> Double {
        let lowercaseQuery = query.lowercased()
        let lowercaseTitle = title.lowercased()
        let lowercaseSubtitle = subtitle.lowercased()
        
        var score = 0.0
        
        // 完全匹配 (最高分)
        if lowercaseTitle == lowercaseQuery {
            score += 100.0
        } else if lowercaseTitle.contains(lowercaseQuery) {
            // 标题包含查询
            if lowercaseTitle.hasPrefix(lowercaseQuery) {
                score += 80.0 // 前缀匹配
            } else {
                score += 60.0 // 普通包含
            }
        }
        
        // 子标题匹配
        if lowercaseSubtitle.contains(lowercaseQuery) {
            score += 30.0
        }
        
        // 模糊匹配 (可选)
        if configuration.enableFuzzySearch && score == 0 {
            let fuzzyScore = calculateFuzzyScore(query: lowercaseQuery, target: lowercaseTitle)
            if fuzzyScore > 0.7 {
                score += fuzzyScore * 20.0
            }
        }
        
        return score
    }
    
    private func calculateFuzzyScore(query: String, target: String) -> Double {
        // 简单的模糊匹配算法
        let queryChars = Array(query)
        let targetChars = Array(target)
        
        var matchCount = 0
        var targetIndex = 0
        
        for queryChar in queryChars {
            while targetIndex < targetChars.count {
                if targetChars[targetIndex] == queryChar {
                    matchCount += 1
                    targetIndex += 1
                    break
                }
                targetIndex += 1
            }
        }
        
        guard query.count > 0 else { return 0.0 }
        return Double(matchCount) / Double(query.count)
    }
    
    // MARK: - Text Highlighting
    
    private func generateHighlightedText(original: String, query: String) -> String {
        let lowercaseOriginal = original.lowercased()
        let lowercaseQuery = query.lowercased()
        
        if let range = lowercaseOriginal.range(of: lowercaseQuery) {
            let start = original.distance(from: original.startIndex, to: range.lowerBound)
            let length = query.count
            let startIndex = original.index(original.startIndex, offsetBy: start)
            let endIndex = original.index(startIndex, offsetBy: length)
            
            let prefix = String(original[..<startIndex])
            let matched = String(original[startIndex..<endIndex])
            let suffix = String(original[endIndex...])
            
            return "\(prefix)**\(matched)**\(suffix)"
        }
        
        return original
    }
    
    // MARK: - Cache Management
    
    private func getFromCache(query: String) -> [AdvancedSearchResult]? {
        return cacheQueue.sync {
            return searchCache[query]
        }
    }
    
    private func cacheResults(query: String, results: [AdvancedSearchResult]) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.searchCache[query] = results
            
            // 限制缓存大小
            if let cache = self?.searchCache, cache.count > 50 {
                let oldestKeys = Array(cache.keys).prefix(cache.count - 50)
                for key in oldestKeys {
                    self?.searchCache.removeValue(forKey: key)
                }
            }
        }
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.searchCache.removeAll()
        }
    }
    
    // MARK: - Search Statistics
    
    private func updateSearchStats(for query: String, results: [AdvancedSearchResult]) {
        let categories = results.compactMap { 
            if case .category = $0.type { return $0 } else { return nil }
        }
        let types = results.compactMap { 
            if case .knotType = $0.type { return $0 } else { return nil }
        }
        let knots = results.compactMap { 
            if case .knot = $0.type { return $0 } else { return nil }
        }
        
        searchStats = SearchStats(
            query: query,
            totalResults: results.count,
            categoryResults: categories.count,
            typeResults: types.count,
            knotResults: knots.count,
            searchTime: Date()
        )
    }
    
    // MARK: - Recent Searches
    
    private func addToRecentSearches(query: String) {
        if let index = recentSearches.firstIndex(of: query) {
            recentSearches.remove(at: index)
        }
        
        recentSearches.insert(query, at: 0)
        
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        saveRecentSearches()
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "RecentSearches")
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.array(forKey: "RecentSearches") as? [String] ?? []
    }
    
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }
    
    // MARK: - Public Search Methods
    
    func searchCategories(_ query: String) -> [KnotCategory] {
        return searchResults.compactMap { 
            if case .category(let category) = $0.type { return category } else { return nil }
        }
    }
    
    func searchTypes(_ query: String) -> [KnotCategory] {
        return searchResults.compactMap { 
            if case .knotType(let type) = $0.type { return type } else { return nil }
        }
    }
    
    func searchKnots(_ query: String) -> [KnotDetail] {
        return searchResults.compactMap { 
            if case .knot(let knot) = $0.type { return knot } else { return nil }
        }
    }
    
    // MARK: - Knot-Centric Search (新的绳结为中心的搜索)
    
    /// 综合搜索绳结：包括直接匹配绳结字段和通过分类/类型间接匹配
    func searchKnotsComprehensive(_ query: String) -> [KnotSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= configuration.minSearchLength else {
            return []
        }
        
        let allKnots = dataManager.allKnots
        var knotResults: [KnotSearchResult] = []
        
        for knot in allKnots {
            if let result = createKnotSearchResult(knot: knot, query: trimmedQuery) {
                knotResults.append(result)
            }
        }
        
        // 按相关度排序
        return knotResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    /// 创建绳结搜索结果，包含多种匹配策略
    private func createKnotSearchResult(knot: KnotDetail, query: String) -> KnotSearchResult? {
        let lowercaseQuery = query.lowercased()
        var totalScore = 0.0
        var matchedFields: [KnotMatchType] = []
        
        // 1. 直接匹配绳结名称 (最高优先级: 100分)
        let knotName = knot.name.lowercased()
        if knotName == lowercaseQuery {
            totalScore += 100.0
            matchedFields.append(.directNameExact)
        } else if knotName.contains(lowercaseQuery) {
            if knotName.hasPrefix(lowercaseQuery) {
                totalScore += 85.0
                matchedFields.append(.directNamePrefix)
            } else {
                totalScore += 70.0
                matchedFields.append(.directNameContains)
            }
        }
        
        // 2. 匹配绳结别名
        if let aliases = knot.aliases {
            for alias in aliases {
                let lowercaseAlias = alias.lowercased()
                if lowercaseAlias == lowercaseQuery {
                    totalScore += 95.0
                    matchedFields.append(.aliasExact)
                    break
                } else if lowercaseAlias.contains(lowercaseQuery) {
                    totalScore += 60.0
                    matchedFields.append(.aliasContains)
                    break
                }
            }
        }
        
        // 3. 匹配绳结描述 (中等优先级: 50分)
        let description = knot.description.lowercased()
        if description.contains(lowercaseQuery) {
            totalScore += 50.0
            matchedFields.append(.description)
        }
        
        // 4. 通过分类间接匹配 (中等优先级: 40分)
        let categories = dataManager.categories
        for category in categories {
            if category.name.lowercased().contains(lowercaseQuery) {
                // 检查这个绳结是否属于这个分类
                if knot.classification.foundIn.contains(where: { $0.lowercased() == category.name.lowercased() }) {
                    totalScore += 40.0
                    matchedFields.append(.categoryIndirect)
                    break
                }
            }
        }
        
        // 5. 通过类型间接匹配 (中等优先级: 35分)
        let types = dataManager.knotTypes
        for type in types {
            if type.name.lowercased().contains(lowercaseQuery) {
                // 检查这个绳结是否属于这个类型
                if knot.classification.type.contains(where: { $0.lowercased() == type.name.lowercased() }) {
                    totalScore += 35.0
                    matchedFields.append(.typeIndirect)
                    break
                }
            }
        }
        
        // 6. 模糊匹配 (低优先级: 15-25分)
        if configuration.enableFuzzySearch && totalScore == 0 {
            let fuzzyScore = calculateFuzzyScore(query: lowercaseQuery, target: knotName)
            if fuzzyScore > 0.6 {
                totalScore += fuzzyScore * 25.0
                matchedFields.append(.fuzzy)
            }
        }
        
        // 如果没有任何匹配，返回nil
        guard totalScore > 0 else { return nil }
        
        return KnotSearchResult(
            knot: knot,
            relevanceScore: totalScore,
            matchedFields: matchedFields,
            highlightedName: configuration.enableHighlighting ? generateHighlightedText(original: knot.name, query: query) : knot.name
        )
    }
    
    // MARK: - Utility Methods
    
    func resetSearch() {
        searchText = ""
        searchResults = []
        searchStats = SearchStats()
        isSearching = false
    }
}

// MARK: - Search Statistics

struct SearchStats {
    let query: String
    let totalResults: Int
    let categoryResults: Int
    let typeResults: Int
    let knotResults: Int
    let searchTime: Date
    
    init() {
        self.query = ""
        self.totalResults = 0
        self.categoryResults = 0
        self.typeResults = 0
        self.knotResults = 0
        self.searchTime = Date()
    }
    
    init(query: String, totalResults: Int, categoryResults: Int, typeResults: Int, knotResults: Int, searchTime: Date) {
        self.query = query
        self.totalResults = totalResults
        self.categoryResults = categoryResults
        self.typeResults = typeResults
        self.knotResults = knotResults
        self.searchTime = searchTime
    }
    
    var isValid: Bool {
        return !query.isEmpty
    }
    
    var formattedSummary: String {
        if totalResults == 0 {
            return "未找到结果"
        } else {
            return "找到 \(totalResults) 个结果"
        }
    }
    
    var detailedSummary: String {
        if totalResults == 0 {
            return "未找到与\"\(query)\"相关的内容"
        }
        
        var parts: [String] = []
        if categoryResults > 0 { parts.append("\(categoryResults)个分类") }
        if typeResults > 0 { parts.append("\(typeResults)个类型") }
        if knotResults > 0 { parts.append("\(knotResults)个绳结") }
        
        return "找到 \(parts.joined(separator: "、"))"
    }
}
