import SwiftUI

/// iPad专用收藏视图 - 列表布局展示收藏的绳结
struct iPadFavoritesView: View {
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    @State private var sortOption: FavoritesSortOption = .dateAdded
    
    private var favoriteKnots: [KnotDetail] {
        dataManager.getFavoriteKnots()
    }
    
    private var filteredAndSortedKnots: [KnotDetail] {
        return sortFavorites(favoriteKnots, by: sortOption)
    }
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content
                }
            } else {
                NavigationView {
                    content
                }
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            // 内容区域
            if favoriteKnots.isEmpty {
                emptyFavoritesView
            } else {
                favoritesListContent
            }
        }
        .navigationTitle(LocalizedStrings.TabBar.favorites.localized)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - 收藏列表内容
    @ViewBuilder
    private var favoritesListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAndSortedKnots) { knot in
                    Button(action: {
                        selectedKnot = knot
                    }) {
                        iPadFavoriteRowView(
                            knot: knot,
                            isSelected: selectedKnot?.id == knot.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - 空状态视图
    @ViewBuilder
    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.FavoritesMoreExtended.noFavorites.localized)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(LocalizedStrings.FavoritesMoreExtended.addFavoritesHint.localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 辅助方法
    private func sortFavorites(_ knots: [KnotDetail], by option: FavoritesSortOption) -> [KnotDetail] {
        switch option {
        case .dateAdded:
            // 按照在收藏列表中的顺序（最新添加的在前）
            return knots.reversed()
        case .name:
            return knots.sorted { $0.name < $1.name }
        case .nameDesc:
            return knots.sorted { $0.name > $1.name }
        }
    }
}

/// 收藏排序选项枚举
enum FavoritesSortOption: CaseIterable {
    case dateAdded
    case name
    case nameDesc
    
    var title: String {
        switch self {
        case .dateAdded:
            return LocalizedStrings.Sort.dateAdded.localized
        case .name:
            return LocalizedStrings.Sort.nameAsc.localized
        case .nameDesc:
            return LocalizedStrings.Sort.nameDesc.localized
        }
    }
    
    var iconName: String {
        switch self {
        case .dateAdded:
            return "clock"
        case .name:
            return "textformat.abc"
        case .nameDesc:
            return "textformat.abc.dottedunderline"
        }
    }
}

/// iPad专用收藏行视图 - 类似分类页面的行视图
struct iPadFavoriteRowView: View {
    let knot: KnotDetail
    let isSelected: Bool
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // 绳结图片
            knotImage
            
            // 绳结信息
            knotInfo
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(selectionBackground)
        .overlay(selectionBorder)
    }
    
    // MARK: - 子视图组件
    @ViewBuilder
    private var knotImage: some View {
        CompatibleAsyncImage(url: imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            imagePlaceholder
        }
        .frame(width: 80, height: 80)
        .clipped()
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "link")
                    .foregroundColor(.gray)
            )
    }
    
    @ViewBuilder
    private var knotInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(knot.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(knot.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                
            // 分类标签
            if !knot.classification.type.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(knot.classification.type.prefix(2), id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    
    @ViewBuilder
    private var selectionBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue.opacity(0.15) : Color.clear)
    }
    
    @ViewBuilder
    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
    }
    
    private var imageURL: URL? {
        if let cover = knot.cover,
           let imagePath = dataManager.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

#Preview {
    // 预览需要模拟数据
    struct PreviewWrapper: View {
        @State private var selectedKnot: KnotDetail?
        
        var body: some View {
            iPadFavoritesView(selectedKnot: $selectedKnot)
        }
    }
    
    return PreviewWrapper()
}

// MARK: - iPad收藏详情视图（用于NavigationSplitView的详情列）
/// 专门用于NavigationSplitView详情列的收藏视图，去除导航包装
struct iPadFavoritesDetailView: View {
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    @State private var sortOption: FavoritesSortOption = .dateAdded
    
    private var favoriteKnots: [KnotDetail] {
        dataManager.getFavoriteKnots()
    }
    
    private var filteredAndSortedKnots: [KnotDetail] {
        return sortFavorites(favoriteKnots, by: sortOption)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 内容区域
            if favoriteKnots.isEmpty {
                emptyFavoritesView
            } else {
                favoritesListContent
            }
        }
        .navigationTitle(LocalizedStrings.TabBar.favorites.localized)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - 收藏列表内容
    @ViewBuilder
    private var favoritesListContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAndSortedKnots) { knot in
                    Button(action: {
                        selectedKnot = knot
                    }) {
                        iPadFavoriteRowView(
                            knot: knot,
                            isSelected: selectedKnot?.id == knot.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - 空状态视图
    @ViewBuilder
    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.FavoritesMoreExtended.noFavorites.localized)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(LocalizedStrings.FavoritesMoreExtended.addFavoritesHint.localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 辅助方法
    private func sortFavorites(_ knots: [KnotDetail], by option: FavoritesSortOption) -> [KnotDetail] {
        switch option {
        case .dateAdded:
            // 按照在收藏列表中的顺序（最新添加的在前）
            return knots.reversed()
        case .name:
            return knots.sorted { $0.name < $1.name }
        case .nameDesc:
            return knots.sorted { $0.name > $1.name }
        }
    }
}