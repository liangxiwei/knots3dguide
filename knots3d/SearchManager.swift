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