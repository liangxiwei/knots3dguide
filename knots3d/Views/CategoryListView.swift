import SwiftUI

/// 统一的分类列表视图（用于用途分类和绳结类型Tab）
struct CategoryListView: View {
    let tabType: TabType
    
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var searchManager = SearchManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 增强搜索栏
                EnhancedSearchBar()
                
                // 搜索统计
                if searchManager.searchStats.isValid {
                    SearchStatsView(stats: searchManager.searchStats)
                }
                
                // 列表内容
                if dataManager.isLoading {
                    LoadingView()
                } else if let errorMessage = dataManager.errorMessage {
                    ErrorView(message: errorMessage) {
                        dataManager.loadData()
                    }
                } else {
                    categoryList
                }
            }
            .navigationTitle(tabType.title)
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
    private var categoryList: some View {
        let items = filteredItems
        
        if items.isEmpty && !searchManager.searchText.isEmpty {
            EmptySearchResultsView(
                query: searchManager.searchText,
                suggestions: getSuggestions()
            )
        } else if items.isEmpty {
            EmptyStateView(
                title: "暂无数据",
                systemImage: tabType == .categories ? "folder" : "tag"
            )
        } else {
            List(items) { category in
                NavigationLink(destination: KnotListView(category: category, tabType: tabType)) {
                    EnhancedCategoryRowView(category: category, searchQuery: searchManager.searchText)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var filteredItems: [KnotCategory] {
        // 如果没有搜索，显示所有项目
        if searchManager.searchText.isEmpty {
            return tabType == .categories ? dataManager.categories : dataManager.knotTypes
        }
        
        // 使用增强搜索管理器
        switch tabType {
        case .categories:
            return searchManager.searchCategories(searchManager.searchText)
        case .types:
            return searchManager.searchTypes(searchManager.searchText)
        default:
            return []
        }
    }
    
    private func getSuggestions() -> [String] {
        let allItems = tabType == .categories ? dataManager.categories : dataManager.knotTypes
        return Array(Set(allItems.map { $0.name.components(separatedBy: " ").first ?? "" }))
            .filter { !$0.isEmpty }
            .prefix(3)
            .map { String($0) }
    }
}

/// 分类行视图
struct CategoryRowView: View {
    let category: KnotCategory
    
    var body: some View {
        HStack(spacing: 16) {
            // 图片
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 文本信息
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(category.desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 箭头
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private var imageURL: URL? {
        if let imagePath = DataManager.shared.getImagePath(for: category.image) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

#Preview {
    CategoryListView(tabType: .categories)
}