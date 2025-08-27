import SwiftUI

/// 统一的分类列表视图（用于用途分类和绳结类型Tab）
struct CategoryListView: View {
    let tabType: TabType
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText, isSearching: $isSearching)
                
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
    }
    
    @ViewBuilder
    private var categoryList: some View {
        let items = filteredItems
        
        if items.isEmpty {
            EmptyStateView(
                title: LocalizedStrings.Search.noResults,
                systemImage: "magnifyingglass"
            )
        } else {
            List(items) { category in
                NavigationLink(destination: KnotListView(category: category, tabType: tabType)) {
                    CategoryRowView(category: category)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var filteredItems: [KnotCategory] {
        let baseItems: [KnotCategory]
        
        switch tabType {
        case .categories:
            baseItems = dataManager.categories
        case .types:
            baseItems = dataManager.knotTypes
        default:
            baseItems = []
        }
        
        if searchText.isEmpty {
            return baseItems
        } else {
            let lowercaseQuery = searchText.lowercased()
            return baseItems.filter {
                $0.name.lowercased().contains(lowercaseQuery) ||
                $0.desc.lowercased().contains(lowercaseQuery)
            }
        }
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