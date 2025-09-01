import SwiftUI

/// iPad专用分类列表视图 - 在NavigationSplitView的中间列显示
struct iPadCategoryListView: View {
    let tabType: TabType
    @Binding var selectedCategory: KnotCategory?
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var isSearching = false
    
    private var filteredCategories: [KnotCategory] {
        let categories = tabType == .categories ? dataManager.categories : dataManager.knotTypes
        
        // 调试输出
        print("🔍 iPad分类视图 - tabType: \(tabType), categories数量: \(dataManager.categories.count), types数量: \(dataManager.knotTypes.count)")
        print("📋 当前显示类型的数据数量: \(categories.count)")
        
        if searchText.isEmpty {
            return categories
        } else {
            return categories.filter { category in
                category.name.localizedCaseInsensitiveContains(searchText) ||
                category.desc.localizedCaseInsensitiveContains(searchText)
            }
        }
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
            // 搜索栏
            searchBar
            
            // 内容区域
            if dataManager.isLoading {
                LoadingView()
            } else if let errorMessage = dataManager.errorMessage {
                ErrorView(message: errorMessage) {
                    dataManager.loadData()
                }
            } else {
                categoryContent
            }
        }
        .navigationTitle(tabType.title)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            print("🎯 iPadCategoryListView出现 - tabType: \(tabType)")
            print("📊 当前数据状态 - categories: \(dataManager.categories.count), types: \(dataManager.knotTypes.count), allKnots: \(dataManager.allKnots.count)")
            
            // 如果没有数据，强制加载
            if dataManager.categories.isEmpty && dataManager.knotTypes.isEmpty && dataManager.allKnots.isEmpty {
                print("🔄 数据为空，强制加载数据...")
                dataManager.loadData()
            }
        }
    }
    
    // MARK: - 搜索栏
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(
                    tabType == .categories ? LocalizedStrings.Category.searchCategories.localized : LocalizedStrings.Category.searchTypes.localized,
                    text: $searchText
                )
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .modifier(ConditionalTextInputModifier())
                .onTapGesture {
                    isSearching = true
                }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isSearching {
                Button(LocalizedStrings.Actions.cancel.localized) {
                    searchText = ""
                    isSearching = false
                    hideKeyboard()
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.2), value: isSearching)
    }
    
    // MARK: - 分类内容
    @ViewBuilder
    private var categoryContent: some View {
        let _ = print("🎯 categoryContent被调用 - filteredCategories.isEmpty: \(filteredCategories.isEmpty)")
        
        if filteredCategories.isEmpty {
            let _ = print("📱 显示空状态 - searchText: '\(searchText)', tabType: \(tabType)")
            if searchText.isEmpty {
                EmptyStateView(
                    title: LocalizedStrings.Category.noData.localized,
                    systemImage: tabType == .categories ? "folder" : "tag"
                )
            } else {
                EmptyStateView(
                    title: LocalizedStrings.Search.noResults.localized,
                    systemImage: "magnifyingglass"
                )
            }
        } else {
            let _ = print("📋 显示列表 - 数据数量: \(filteredCategories.count)")
            
            // 使用ScrollView + LazyVStack 替代List，避免渲染问题
            ScrollView {
                LazyVStack(spacing: 0) {
                    Text("找到 \(filteredCategories.count) 个\(tabType == .categories ? "分类" : "类型")")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    ForEach(filteredCategories, id: \.id) { category in
                        Button(action: {
                            print("📝 选择了: \(category.name)")
                            selectedCategory = category
                            selectedKnot = nil
                        }) {
                            HStack {
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
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.clear)
                        }
                        .buttonStyle(.plain)
                        
                        if category.id != filteredCategories.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
}

/// iPad专用分类行视图 - 优化的大屏显示
struct iPadCategoryRowView: View {
    let category: KnotCategory
    let tabType: TabType
    let isSelected: Bool
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        let _ = print("🎯 渲染iPadCategoryRowView - category: \(category.name)")
        
        HStack(spacing: 16) {
            categoryImage
            categoryInfo
            Spacer()
            knotCountBadge
        }
        .padding(.vertical, 8)
        .background(selectionBackground)
        .overlay(selectionBorder)
    }
    
    // MARK: - 子视图组件
    @ViewBuilder
    private var categoryImage: some View {
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
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            )
    }
    
    @ViewBuilder
    private var categoryInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(category.desc)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private var knotCountBadge: some View {
        VStack(spacing: 4) {
            Text("\(knotCount)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(LocalizedStrings.CommonExtended.knots.localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
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
    
    /// 计算该分类下的绳结数量
    private var knotCount: Int {
        switch tabType {
        case .categories:
            return dataManager.getKnotsByCategory(category.name).count
        case .types:
            return dataManager.getKnotsByType(category.name).count
        default:
            return 0
        }
    }
    
    private var imageURL: URL? {
        if let imagePath = DataManager.shared.getImagePath(for: category.image) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

#Preview {
    // 预览需要模拟数据
    struct PreviewWrapper: View {
        @State private var selectedCategory: KnotCategory?
        @State private var selectedKnot: KnotDetail?
        
        var body: some View {
            iPadCategoryListView(
                tabType: .categories,
                selectedCategory: $selectedCategory,
                selectedKnot: $selectedKnot
            )
        }
    }
    
    return PreviewWrapper()
}