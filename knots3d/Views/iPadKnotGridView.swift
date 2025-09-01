import SwiftUI

/// iPad专用绳结网格视图 - 在详情列显示分类下的绳结网格
struct iPadKnotGridView: View {
    let category: KnotCategory
    let tabType: TabType
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var gridColumns = 3
    @State private var sortOption: SortOption = .name
    
    private var baseKnots: [KnotDetail] {
        switch tabType {
        case .categories:
            return dataManager.getKnotsByCategory(category.name)
        case .types:
            return dataManager.getKnotsByType(category.name)
        default:
            return []
        }
    }
    
    private var filteredAndSortedKnots: [KnotDetail] {
        let filtered = searchText.isEmpty ? baseKnots : baseKnots.filter { knot in
            knot.name.localizedCaseInsensitiveContains(searchText) ||
            knot.description.localizedCaseInsensitiveContains(searchText)
        }
        
        return sortKnots(filtered, by: sortOption)
    }
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: gridColumns)
    }
    
    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    contentView
                }
            } else {
                NavigationView {
                    contentView
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbarSection
            
            // 绳结网格
            if filteredAndSortedKnots.isEmpty {
                emptyStateView
            } else {
                knotGridContent
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 工具栏
    @ViewBuilder
    private var toolbarSection: some View {
        VStack(spacing: 12) {
            // 搜索和排序控制
            HStack {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField(LocalizedStrings.SearchExtended.searchKnots.localized, text: $searchText)
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
                        ForEach(SortOption.allCases, id: \.self) { option in
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
            }
            .padding(.horizontal)
            
            // 统计信息
            HStack {
                Text(LocalizedStrings.CommonExtended.totalKnots.localized(with: filteredAndSortedKnots.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !searchText.isEmpty {
                    Text(LocalizedStrings.SearchExtended.searchResults.localized(with: searchText))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 绳结网格内容
    @ViewBuilder
    private var knotGridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredAndSortedKnots) { knot in
                    iPadKnotCardView(
                        knot: knot,
                        isSelected: selectedKnot?.id == knot.id
                    )
                    .onTapGesture {
                        selectedKnot = knot
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 空状态视图
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "link" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? LocalizedStrings.KnotList.noKnots.localized : LocalizedStrings.Search.noResults.localized)
                .font(.headline)
                .foregroundColor(.primary)
            
            if searchText.isEmpty {
                Text(LocalizedStrings.KnotList.noKnotsInCategory.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Button(LocalizedStrings.ActionsExtended.clearSearch.localized) {
                    searchText = ""
                }
                .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 排序方法
    private func sortKnots(_ knots: [KnotDetail], by option: SortOption) -> [KnotDetail] {
        switch option {
        case .name:
            return knots.sorted { $0.name < $1.name }
        case .nameDesc:
            return knots.sorted { $0.name > $1.name }
        case .favorites:
            return knots.sorted { first, second in
                let firstIsFavorite = dataManager.favoriteKnots.contains(first.id)
                let secondIsFavorite = dataManager.favoriteKnots.contains(second.id)
                if firstIsFavorite != secondIsFavorite {
                    return firstIsFavorite
                }
                return first.name < second.name
            }
        }
    }
}

/// 排序选项枚举
enum SortOption: CaseIterable {
    case name
    case nameDesc
    case favorites
    
    var title: String {
        switch self {
        case .name:
            return LocalizedStrings.Sort.nameAsc.localized
        case .nameDesc:
            return LocalizedStrings.Sort.nameDesc.localized
        case .favorites:
            return LocalizedStrings.Sort.favorites.localized
        }
    }
    
    var iconName: String {
        switch self {
        case .name:
            return "textformat.abc"
        case .nameDesc:
            return "textformat.abc.dottedunderline"
        case .favorites:
            return "heart.fill"
        }
    }
}

/// iPad专用绳结卡片视图
struct iPadKnotCardView: View {
    let knot: KnotDetail
    let isSelected: Bool
    
    @StateObject private var dataManager = DataManager.shared
    
    private var isFavorite: Bool {
        dataManager.favoriteKnots.contains(knot.id)
    }
    
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
                
                // 收藏按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: toggleFavorite) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(isFavorite ? .red : .white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: 32, height: 32)
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
                
                Text(knot.description)
                    .font(.caption)
                    .lineLimit(3)
                    .foregroundColor(.secondary)
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
    }
    
    private var knotImageURL: URL? {
        if let cover = knot.cover,
           let imagePath = dataManager.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
    
    private func toggleFavorite() {
        dataManager.toggleFavorite(knot.id)
    }
}

#Preview {
    // 预览需要模拟数据
    struct PreviewWrapper: View {
        @State private var selectedKnot: KnotDetail?
        
        // 模拟分类数据
        private let mockCategory = KnotCategory(
            type: "category",
            name: "Essential Knots",
            desc: "Basic knots everyone should know",
            image: "essential_knots.jpg"
        )
        
        var body: some View {
            iPadKnotGridView(
                category: mockCategory,
                tabType: .categories,
                selectedKnot: $selectedKnot
            )
        }
    }
    
    return PreviewWrapper()
}