import SwiftUI

/// iPad专用主视图 - 使用侧边栏导航布局
@available(iOS 16.0, *)
struct iPadMainView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var searchManager = SearchManager.shared
    @State private var selectedSidebarItem: SidebarItem? = .categories
    @State private var selectedCategory: KnotCategory?
    @State private var selectedKnot: KnotDetail?
    @State private var showGlobalSearch = false
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 侧边栏
            sidebarContent
        } content: {
            // 内容区域（中间列）
            contentView
        } detail: {
            // 详情区域（右侧列）
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .id(languageManager.currentLanguage)
        .fullScreenCover(isPresented: $showGlobalSearch) {
            GlobalSearchView()
        }
        .onAppear {
            print("🍎 iPad界面出现，准备加载数据...")
            setupInitialData()
        }
    }
    
    // MARK: - 侧边栏内容
    @ViewBuilder
    private var sidebarContent: some View {
        List(selection: $selectedSidebarItem) {
            // 搜索按钮
            Button(action: { showGlobalSearch = true }) {
                Label(LocalizedStrings.SearchExtended.searchAllKnots.localized, systemImage: "magnifyingglass")
                    .foregroundColor(.primary)
            }
            .listRowBackground(Color.clear)
            
            Divider()
            
            // 主要分类
            Section(LocalizedStrings.TabBar.categories.localized) {
                NavigationLink(
                    destination: EmptyView(),
                    tag: SidebarItem.categories,
                    selection: $selectedSidebarItem
                ) {
                    Label(LocalizedStrings.TabBar.categories.localized, systemImage: "folder.fill")
                }
                
                NavigationLink(
                    destination: EmptyView(),
                    tag: SidebarItem.types,
                    selection: $selectedSidebarItem
                ) {
                    Label(LocalizedStrings.TabBar.types.localized, systemImage: "link")
                }
            }
            
            // 个人收藏
            Section(LocalizedStrings.CommonExtended.personal.localized) {
                NavigationLink(
                    destination: EmptyView(),
                    tag: SidebarItem.favorites,
                    selection: $selectedSidebarItem
                ) {
                    Label(LocalizedStrings.TabBar.favorites.localized, systemImage: "heart.fill")
                        .badge(dataManager.favoriteKnots.count)
                }
            }
            
            // 设置和其他
            Section(LocalizedStrings.CommonExtended.other.localized) {
                NavigationLink(
                    destination: EmptyView(),
                    tag: SidebarItem.settings,
                    selection: $selectedSidebarItem
                ) {
                    Label(LocalizedStrings.TabBar.settings.localized, systemImage: "gearshape.fill")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(LocalizedStrings.App.title.localized)
        .onChange(of: selectedSidebarItem) { newValue in
            print("🔄 侧边栏切换: \(String(describing: newValue))")
            // 切换侧边栏项目时，清除选中的分类和绳结
            selectedCategory = nil
            selectedKnot = nil
            print("✅ 已清空选中状态")
        }
    }
    
    // MARK: - 内容视图（中间列）
    @ViewBuilder
    private var contentView: some View {
        let _ = print("🎯 contentView渲染 - selectedSidebarItem: \(String(describing: selectedSidebarItem))")
        
        if let selectedItem = selectedSidebarItem {
            switch selectedItem {
            case .categories:
                iPadCategoryListView(
                    tabType: .categories,
                    selectedCategory: $selectedCategory,
                    selectedKnot: $selectedKnot
                )
                .id("categories")
            case .types:
                iPadCategoryListView(
                    tabType: .types,
                    selectedCategory: $selectedCategory,
                    selectedKnot: $selectedKnot
                )
                .id("types")
            case .favorites:
                iPadFavoritesView(selectedKnot: $selectedKnot)
            case .settings:
                SettingsView()
            }
        } else {
            iPadWelcomeView()
        }
    }
    
    // MARK: - 详情视图（右侧列）
    @ViewBuilder
    private var detailView: some View {
        if let selectedKnot = selectedKnot {
            iPadKnotDetailView(knot: selectedKnot)
        } else if let selectedCategory = selectedCategory {
            iPadKnotGridView(
                category: selectedCategory,
                tabType: selectedSidebarItem == .categories ? .categories : .types,
                selectedKnot: $selectedKnot
            )
        } else {
            iPadPlaceholderView()
        }
    }
    
    // MARK: - 初始化数据
    private func setupInitialData() {
        print("📊 检查数据状态 - categories: \(dataManager.categories.count), types: \(dataManager.knotTypes.count), knots: \(dataManager.allKnots.count)")
        
        if dataManager.categories.isEmpty && dataManager.knotTypes.isEmpty && dataManager.allKnots.isEmpty {
            print("🔄 数据为空，开始加载...")
            dataManager.loadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dataManager.preloadImagePaths()
            }
        } else {
            print("✅ 数据已存在，无需重新加载")
        }
    }
}

// MARK: - 侧边栏项目枚举
enum SidebarItem: String, CaseIterable, Hashable {
    case categories = "categories"
    case types = "types"
    case favorites = "favorites"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .categories:
            return LocalizedStrings.TabBar.categories.localized
        case .types:
            return LocalizedStrings.TabBar.types.localized
        case .favorites:
            return LocalizedStrings.TabBar.favorites.localized
        case .settings:
            return LocalizedStrings.TabBar.settings.localized
        }
    }
    
    var iconName: String {
        switch self {
        case .categories:
            return "folder.fill"
        case .types:
            return "link"
        case .favorites:
            return "heart.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

// MARK: - iPad欢迎视图
@available(iOS 16.0, *)
struct iPadWelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "link")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            
            Text(LocalizedStrings.App.welcomeTitle.localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(LocalizedStrings.App.welcomeSubtitle.localized)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - iPad占位视图
@available(iOS 16.0, *)
struct iPadPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.dashed")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.CommonExtended.selectItem.localized)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        iPadMainView()
    } else {
        Text("iPad Main View requires iOS 16+")
    }
}