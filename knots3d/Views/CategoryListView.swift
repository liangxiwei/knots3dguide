import SwiftUI

/// 统一的分类列表视图（用于用途分类和绳结类型Tab）
struct CategoryListView: View {
    let tabType: TabType
    let onSearchTap: () -> Void
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 假搜索栏（点击进入全局搜索）
                FakeSearchBar(
                    placeholder: tabType == .categories ? "搜索用途分类" : "搜索绳结类型",
                    onTap: onSearchTap
                )
                
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
        let items = tabType == .categories ? dataManager.categories : dataManager.knotTypes
        
        if items.isEmpty {
            EmptyStateView(
                title: "暂无数据",
                systemImage: tabType == .categories ? "folder" : "tag"
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
    CategoryListView(tabType: .categories, onSearchTap: {})
}