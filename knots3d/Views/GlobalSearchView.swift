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
            // 空状态或搜索历史
            emptySearchState
        } else if searchManager.isSearching {
            // 搜索中状态
            LoadingView()
        } else if searchManager.searchResults.isEmpty {
            // 无结果状态
            EmptySearchResultsView(
                query: searchManager.searchText,
                suggestions: getGlobalSuggestions()
            )
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
            
            // 快速搜索建议
            if !searchManager.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("最近搜索")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(searchManager.recentSearches.prefix(4), id: \.self) { search in
                            Button(action: {
                                searchManager.searchText = search
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Text(search)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // 热门搜索建议
                popularSearchSuggestions
            }
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
            // 搜索统计
            SearchStatsView(stats: searchManager.searchStats)
            
            // 分组搜索结果
            List {
                searchResultSections
            }
            .listStyle(PlainListStyle())
        }
    }
    
    @ViewBuilder
    private var searchResultSections: some View {
        let categoryResults = searchManager.searchCategories(searchManager.searchText)
        let typeResults = searchManager.searchTypes(searchManager.searchText)
        let knotResults = searchManager.searchKnots(searchManager.searchText)
        
        // 分类结果
        if !categoryResults.isEmpty {
            Section {
                ForEach(categoryResults.prefix(5)) { category in
                    NavigationLink(destination: KnotListView(category: category, tabType: .categories)) {
                        SearchResultRowView(
                            title: category.name,
                            subtitle: category.desc,
                            type: "用途分类",
                            icon: "folder",
                            searchQuery: searchManager.searchText
                        )
                    }
                }
            } header: {
                SectionHeaderView(title: "用途分类", count: categoryResults.count)
            }
        }
        
        // 类型结果
        if !typeResults.isEmpty {
            Section {
                ForEach(typeResults.prefix(5)) { type in
                    NavigationLink(destination: KnotListView(category: type, tabType: .types)) {
                        SearchResultRowView(
                            title: type.name,
                            subtitle: type.desc,
                            type: "绳结类型",
                            icon: "tag",
                            searchQuery: searchManager.searchText
                        )
                    }
                }
            } header: {
                SectionHeaderView(title: "绳结类型", count: typeResults.count)
            }
        }
        
        // 绳结结果
        if !knotResults.isEmpty {
            Section {
                ForEach(knotResults.prefix(10)) { knot in
                    NavigationLink(destination: KnotDetailView(knot: knot)) {
                        SearchResultKnotRowView(
                            knot: knot,
                            searchQuery: searchManager.searchText
                        )
                    }
                }
            } header: {
                SectionHeaderView(title: "绳结", count: knotResults.count)
            }
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

// MARK: - Preview

#Preview {
    GlobalSearchView()
}