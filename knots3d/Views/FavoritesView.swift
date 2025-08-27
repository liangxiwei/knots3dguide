import SwiftUI

struct FavoritesView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var searchManager = SearchManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 增强搜索栏
                EnhancedSearchBar()
                
                // 搜索统计
                if searchManager.searchStats.isValid && !dataManager.favoriteKnots.isEmpty {
                    SearchStatsView(stats: searchManager.searchStats)
                }
                
                // 内容区域
                if dataManager.favoriteKnots.isEmpty {
                    EmptyStateView(
                        title: LocalizedStrings.Favorites.empty,
                        systemImage: "heart",
                        subtitle: "收藏一些绳结后，它们将显示在这里"
                    )
                } else {
                    favoritesList
                }
            }
            .navigationTitle(LocalizedStrings.TabBar.favorites)
            .navigationBarTitleDisplayMode(.large)
        }
        .onDisappear {
            // 离开页面时重置搜索状态
            if !searchManager.searchText.isEmpty {
                searchManager.resetSearch()
            }
        }
    }
    
    @ViewBuilder
    private var favoritesList: some View {
        let filteredFavorites = filteredFavoriteKnots
        
        if filteredFavorites.isEmpty && !searchManager.searchText.isEmpty {
            EmptySearchResultsView(
                query: searchManager.searchText,
                suggestions: getFavoriteSuggestions()
            )
        } else {
            List(filteredFavorites) { knot in
                NavigationLink(destination: KnotDetailView(knot: knot)) {
                    EnhancedKnotRowView(
                        knot: knot, 
                        showFavoriteButton: true,
                        searchQuery: searchManager.searchText
                    )
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var filteredFavoriteKnots: [KnotDetail] {
        if searchManager.searchText.isEmpty {
            return dataManager.getFavoriteKnots()
        } else {
            return searchManager.searchKnots(searchManager.searchText)
                .filter { dataManager.isFavorite($0.id) }
        }
    }
    
    private func getFavoriteSuggestions() -> [String] {
        let favorites = dataManager.getFavoriteKnots()
        return Array(Set(favorites.flatMap { $0.classification.type }))
            .prefix(3)
            .map { String($0) }
    }
}

/// 绳结行视图
struct KnotRowView: View {
    let knot: KnotDetail
    let showFavoriteButton: Bool
    
    @StateObject private var dataManager = DataManager.shared
    
    init(knot: KnotDetail, showFavoriteButton: Bool = false) {
        self.knot = knot
        self.showFavoriteButton = showFavoriteButton
    }
    
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
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 文本信息
            VStack(alignment: .leading, spacing: 4) {
                Text(knot.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(knot.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // 分类信息
                if !knot.classification.type.isEmpty {
                    HStack {
                        ForEach(knot.classification.type.prefix(2), id: \.self) { type in
                            Text(type)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 收藏按钮
            if showFavoriteButton {
                Button(action: {
                    dataManager.toggleFavorite(knot.id)
                }) {
                    Image(systemName: dataManager.isFavorite(knot.id) ? "heart.fill" : "heart")
                        .foregroundColor(dataManager.isFavorite(knot.id) ? .red : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var coverImageURL: URL? {
        guard let cover = knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

/// 增强绳结行视图（支持搜索高亮）
struct EnhancedKnotRowView: View {
    let knot: KnotDetail
    let showFavoriteButton: Bool
    let searchQuery: String
    
    @StateObject private var dataManager = DataManager.shared
    
    init(knot: KnotDetail, showFavoriteButton: Bool = false, searchQuery: String = "") {
        self.knot = knot
        self.showFavoriteButton = showFavoriteButton
        self.searchQuery = searchQuery
    }
    
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
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 文本信息
            VStack(alignment: .leading, spacing: 4) {
                HighlightedText(
                    text: knot.name,
                    highlight: searchQuery
                )
                .font(.headline)
                .foregroundColor(.primary)
                
                HighlightedText(
                    text: knot.description,
                    highlight: searchQuery
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                
                // 分类信息
                if !knot.classification.type.isEmpty {
                    HStack {
                        ForEach(knot.classification.type.prefix(2), id: \.self) { type in
                            Text(type)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 收藏按钮
            if showFavoriteButton {
                Button(action: {
                    dataManager.toggleFavorite(knot.id)
                }) {
                    Image(systemName: dataManager.isFavorite(knot.id) ? "heart.fill" : "heart")
                        .foregroundColor(dataManager.isFavorite(knot.id) ? .red : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var coverImageURL: URL? {
        guard let cover = knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

#Preview {
    FavoritesView()
}