import SwiftUI

/// 全局搜索视图
struct GlobalSearchView: View {
    @StateObject private var searchManager = SearchManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                EnhancedSearchBar()
                
                // 搜索结果
                searchResultsContent
            }
            .navigationTitle("全局搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // 清空之前的搜索状态
            if searchManager.searchText.isEmpty {
                searchManager.resetSearch()
            }
        }
    }
    
    @ViewBuilder
    private var searchResultsContent: some View {
        if searchManager.searchText.isEmpty {
            // 空状态
            emptySearchState
        } else if searchManager.isSearching {
            // 搜索中状态
            LoadingView()
        } else if knotSearchResults.isEmpty {
            // 无结果状态 - 不显示建议列表
            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.gray.opacity(0.5))
                
                VStack(spacing: 8) {
                    Text("未找到相关绳结")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("尝试其他关键词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            // 搜索结果列表
            searchResultsList
        }
    }
    
    @ViewBuilder
    private var emptySearchState: some View {
        VStack(spacing: 24) {
            // 搜索图标
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("发现更多绳结")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("搜索绳结名称、描述或分类")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 热门搜索建议
            popularSearchSuggestions
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var popularSearchSuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("热门搜索")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(getPopularSearches(), id: \.self) { term in
                    Button(term) {
                        searchManager.searchText = term
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            // 绳结搜索统计
            knotSearchStatsView
            
            // 统一绳结列表
            List(knotSearchResults) { result in
                NavigationLink(destination: KnotDetailView(knot: result.knot)) {
                    KnotSearchResultRowView(searchResult: result)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var knotSearchResults: [KnotSearchResult] {
        return searchManager.searchKnotsComprehensive(searchManager.searchText)
    }
    
    @ViewBuilder
    private var knotSearchStatsView: some View {
        let results = knotSearchResults
        if !results.isEmpty {
            VStack(spacing: 8) {
                HStack {
                    Text("找到 \(results.count) 个绳结")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("按相关度排序")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 匹配类型分布
                if !results.isEmpty {
                    let matchTypes = getMatchTypeDistribution(results: results)
                    if !matchTypes.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(matchTypes, id: \.0) { type, count in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(getMatchTypeColor(type))
                                        .frame(width: 8, height: 8)
                                    Text("\(type): \(count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
        }
    }
    
    // 获取匹配类型分布统计
    private func getMatchTypeDistribution(results: [KnotSearchResult]) -> [(String, Int)] {
        var distribution: [String: Int] = [:]
        
        for result in results {
            let type = result.matchTypeDescription
            distribution[type] = (distribution[type] ?? 0) + 1
        }
        
        return distribution.sorted { $0.1 > $1.1 }.prefix(3).map { ($0.key, $0.value) }
    }
    
    // 获取匹配类型对应的颜色
    private func getMatchTypeColor(_ type: String) -> Color {
        switch type {
        case "名称匹配":
            return .blue
        case "别名匹配":
            return .green
        case "描述匹配":
            return .orange
        case "分类匹配":
            return .purple
        case "类型匹配":
            return .pink
        case "模糊匹配":
            return .gray
        default:
            return .secondary
        }
    }
    
    private func getPopularSearches() -> [String] {
        return ["Bowline", "Hitch", "Loop", "Bend", "Clove", "Figure", "Knot", "Tie"]
    }
    
    private func getGlobalSuggestions() -> [String] {
        return getPopularSearches()
    }
}

// MARK: - Search Result Components

/// 搜索结果行视图
struct SearchResultRowView: View {
    let title: String
    let subtitle: String
    let type: String
    let icon: String
    let searchQuery: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HighlightedText(text: title, highlight: searchQuery)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HighlightedText(text: subtitle, highlight: searchQuery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.gray)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

/// 搜索结果绳结行视图
struct SearchResultKnotRowView: View {
    let knot: KnotDetail
    let searchQuery: String
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // 绳结图片
            AsyncImage(url: coverImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipped()
            .cornerRadius(6)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HighlightedText(text: knot.name, highlight: searchQuery)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if dataManager.isFavorite(knot.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                HighlightedText(text: knot.description, highlight: searchQuery)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 分类标签
                if !knot.classification.type.isEmpty {
                    HStack {
                        ForEach(knot.classification.type.prefix(2), id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(3)
                        }
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
    
    private var coverImageURL: URL? {
        guard let cover = knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

/// 区块标题视图
struct SectionHeaderView: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .textCase(nil)
    }
}

// MARK: - Knot Search Result Components

/// 绳结搜索结果行视图
struct KnotSearchResultRowView: View {
    let searchResult: KnotSearchResult
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // 绳结图片
            AsyncImage(url: coverImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipped()
            .cornerRadius(8)
            
            // 内容
            VStack(alignment: .leading, spacing: 6) {
                // 绳结名称（高亮）
                HStack(alignment: .top, spacing: 8) {
                    Text(searchResult.highlightedName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // 收藏状态
                    if dataManager.isFavorite(searchResult.knot.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // 描述
                Text(searchResult.knot.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 底部信息：匹配类型 + 分类标签
                HStack(spacing: 8) {
                    // 匹配类型标签
                    HStack(spacing: 4) {
                        Circle()
                            .fill(getMatchTypeColor(searchResult.matchTypeDescription))
                            .frame(width: 6, height: 6)
                        
                        Text(searchResult.matchTypeDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // 分类标签
                    if let firstType = searchResult.knot.classification.type.first {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(firstType)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                    
                    // 相关度分数（调试用，可以在正式版本中移除）
                    Text(String(format: "%.0f", searchResult.relevanceScore))
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(2)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private var coverImageURL: URL? {
        guard let cover = searchResult.knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
    
    // 获取匹配类型对应的颜色
    private func getMatchTypeColor(_ type: String) -> Color {
        switch type {
        case "名称匹配":
            return .blue
        case "别名匹配":
            return .green
        case "描述匹配":
            return .orange
        case "分类匹配":
            return .purple
        case "类型匹配":
            return .pink
        case "模糊匹配":
            return .gray
        default:
            return .secondary
        }
    }
}

// MARK: - Preview

#Preview {
    GlobalSearchView()
}