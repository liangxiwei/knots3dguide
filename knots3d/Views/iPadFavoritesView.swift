import SwiftUI

/// iPad专用收藏视图 - 网格布局展示收藏的绳结
struct iPadFavoritesView: View {
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var gridColumns = 3
    @State private var sortOption: FavoritesSortOption = .dateAdded
    @State private var showDeleteAlert = false
    @State private var knotToDelete: KnotDetail?
    
    private var favoriteKnots: [KnotDetail] {
        dataManager.getFavoriteKnots()
    }
    
    private var filteredAndSortedKnots: [KnotDetail] {
        let filtered = searchText.isEmpty ? favoriteKnots : favoriteKnots.filter { knot in
            knot.name.localizedCaseInsensitiveContains(searchText) ||
            knot.description.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortFavorites(filtered, by: sortOption)
    }
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: gridColumns)
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
                // 工具栏
                toolbarSection
                
                // 内容区域
                if favoriteKnots.isEmpty {
                    emptyFavoritesView
                } else if filteredAndSortedKnots.isEmpty {
                    emptySearchResultsView
                } else {
                    favoritesGridContent
                }
            }
            .navigationTitle(LocalizedStrings.TabBar.favorites.localized)
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text(LocalizedStrings.FavoritesMoreExtended.removeConfirmTitle.localized),
                    message: knotToDelete.map { knot in
                        Text(LocalizedStrings.FavoritesMoreExtended.removeConfirmMessage.localized(with: knot.name))
                    },
                    primaryButton: .destructive(Text(LocalizedStrings.Favorites.remove.localized)) {
                        if let knot = knotToDelete {
                            removeFromFavorites(knot)
                        }
                    },
                    secondaryButton: .cancel(Text(LocalizedStrings.Actions.cancel.localized))
                )
            }
    }
    
    // MARK: - 工具栏
    @ViewBuilder
    private var toolbarSection: some View {
        VStack(spacing: 12) {
            // 搜索和控制区域
            HStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField(LocalizedStrings.SearchExtended.searchFavorites.localized, text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .modifier(ConditionalTextInputModifier())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
                
                // 排序菜单
                Menu {
                    Picker(LocalizedStrings.CommonExtended.sortBy.localized, selection: $sortOption) {
                        ForEach(FavoritesSortOption.allCases, id: \.self) { option in
                            Label(option.title, systemImage: option.iconName)
                                .tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: sortOption.iconName)
                        Text(sortOption.title)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 网格列数控制
                Menu {
                    ForEach([2, 3, 4], id: \.self) { columns in
                        Button(action: { gridColumns = columns }) {
                            HStack {
                                Image(systemName: "\(columns).square.grid")
                                Text("\(columns) " + LocalizedStrings.CommonExtended.columns.localized)
                                if gridColumns == columns {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "\(gridColumns).square.grid")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 清空收藏按钮
                if !favoriteKnots.isEmpty {
                    Button(action: showClearAllAlert) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // 统计信息
            HStack {
                Text(LocalizedStrings.FavoritesMoreExtended.totalFavorites.localized(with: favoriteKnots.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty && filteredAndSortedKnots.count != favoriteKnots.count {
                    Text(LocalizedStrings.SearchExtended.filteredResults.localized(with: filteredAndSortedKnots.count, favoriteKnots.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 收藏网格内容
    @ViewBuilder
    private var favoritesGridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredAndSortedKnots) { knot in
                    iPadFavoriteCardView(
                        knot: knot,
                        isSelected: selectedKnot?.id == knot.id,
                        onTap: { selectedKnot = knot },
                        onRemove: { showRemoveAlert(for: knot) }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
    
    @ViewBuilder
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.Search.noResults.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(LocalizedStrings.ActionsExtended.clearSearch.localized) {
                searchText = ""
            }
            .foregroundColor(.blue)
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
    
    private func showRemoveAlert(for knot: KnotDetail) {
        knotToDelete = knot
        showDeleteAlert = true
    }
    
    private func removeFromFavorites(_ knot: KnotDetail) {
        dataManager.toggleFavorite(knot.id)
        
        // 如果删除的是当前选中的绳结，清除选择
        if selectedKnot?.id == knot.id {
            selectedKnot = nil
        }
    }
    
    private func showClearAllAlert() {
        // 这里可以添加清空所有收藏的功能
        // 为了简化，暂时不实现
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

/// iPad专用收藏卡片视图
struct iPadFavoriteCardView: View {
    let knot: KnotDetail
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    
    @StateObject private var dataManager = DataManager.shared
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 绳结图片
            ZStack {
                CompatibleAsyncImage(url: knotImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "link")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
                
                // 移除按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onRemove) {
                            Image(systemName: "heart.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            // 绳结信息
            VStack(alignment: .leading, spacing: 4) {
                Text(knot.name)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                if let aliases = knot.aliases, !aliases.isEmpty {
                    Text(aliases.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                
                Text(knot.description)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
            }
            
            // 分类标签
            if !knot.classification.type.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(knot.classification.type.prefix(3), id: \.self) { type in
                            Text(type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
    
    private var knotImageURL: URL? {
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
    @State private var searchText = ""
    @State private var gridColumns = 3
    @State private var sortOption: FavoritesSortOption = .dateAdded
    @State private var showDeleteAlert = false
    @State private var knotToDelete: KnotDetail?
    
    private var favoriteKnots: [KnotDetail] {
        dataManager.getFavoriteKnots()
    }
    
    private var filteredAndSortedKnots: [KnotDetail] {
        let filtered = searchText.isEmpty ? favoriteKnots : favoriteKnots.filter { knot in
            knot.name.localizedCaseInsensitiveContains(searchText) ||
            knot.description.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortFavorites(filtered, by: sortOption)
    }
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: gridColumns)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbarSection
            
            // 内容区域
            if favoriteKnots.isEmpty {
                emptyFavoritesView
            } else if filteredAndSortedKnots.isEmpty {
                emptySearchResultsView
            } else {
                favoritesGridContent
            }
        }
        .navigationTitle(LocalizedStrings.TabBar.favorites.localized)
        .navigationBarTitleDisplayMode(.large)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(LocalizedStrings.FavoritesMoreExtended.removeConfirmTitle.localized),
                message: knotToDelete.map { knot in
                    Text(LocalizedStrings.FavoritesMoreExtended.removeConfirmMessage.localized(with: knot.name))
                },
                primaryButton: .destructive(Text(LocalizedStrings.Favorites.remove.localized)) {
                    if let knot = knotToDelete {
                        removeFromFavorites(knot)
                    }
                },
                secondaryButton: .cancel(Text(LocalizedStrings.Actions.cancel.localized))
            )
        }
    }
    
    // MARK: - 工具栏
    @ViewBuilder
    private var toolbarSection: some View {
        VStack(spacing: 12) {
            // 搜索和控制区域
            HStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField(LocalizedStrings.SearchExtended.searchFavorites.localized, text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .modifier(ConditionalTextInputModifier())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
                
                // 排序菜单
                Menu {
                    Picker(LocalizedStrings.CommonExtended.sortBy.localized, selection: $sortOption) {
                        ForEach(FavoritesSortOption.allCases, id: \.self) { option in
                            Label(option.title, systemImage: option.iconName)
                                .tag(option)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: sortOption.iconName)
                        Text(sortOption.title)
                        Image(systemName: "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 网格列数控制
                Menu {
                    ForEach([2, 3, 4], id: \.self) { columns in
                        Button(action: { gridColumns = columns }) {
                            HStack {
                                Image(systemName: "\(columns).square.grid")
                                Text("\(columns) " + LocalizedStrings.CommonExtended.columns.localized)
                                if gridColumns == columns {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "\(gridColumns).square.grid")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // 清空收藏按钮
                if !favoriteKnots.isEmpty {
                    Button(action: showClearAllAlert) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            // 统计信息
            HStack {
                Text(LocalizedStrings.FavoritesMoreExtended.totalFavorites.localized(with: favoriteKnots.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty && filteredAndSortedKnots.count != favoriteKnots.count {
                    Text(LocalizedStrings.SearchExtended.filteredResults.localized(with: filteredAndSortedKnots.count, favoriteKnots.count))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 收藏网格内容
    @ViewBuilder
    private var favoritesGridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredAndSortedKnots) { knot in
                    iPadFavoriteCardView(
                        knot: knot,
                        isSelected: selectedKnot?.id == knot.id,
                        onTap: { selectedKnot = knot },
                        onRemove: { showRemoveAlert(for: knot) }
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
    
    @ViewBuilder
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.Search.noResults.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            Button(LocalizedStrings.ActionsExtended.clearSearch.localized) {
                searchText = ""
            }
            .foregroundColor(.blue)
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
    
    private func showRemoveAlert(for knot: KnotDetail) {
        knotToDelete = knot
        showDeleteAlert = true
    }
    
    private func removeFromFavorites(_ knot: KnotDetail) {
        dataManager.toggleFavorite(knot.id)
        
        // 如果删除的是当前选中的绳结，清除选择
        if selectedKnot?.id == knot.id {
            selectedKnot = nil
        }
    }
    
    private func showClearAllAlert() {
        // 这里可以添加清空所有收藏的功能
        // 为了简化，暂时不实现
    }
}