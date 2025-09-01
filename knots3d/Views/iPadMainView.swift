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
        Group {
            if selectedSidebarItem == .settings {
                // 设置页面：使用独立的NavigationStack，全屏显示，不使用分栏布局
                NavigationStack {
                    VStack {
                        // 顶部导航栏，包含返回按钮
                        HStack {
                            Button(action: {
                                selectedSidebarItem = .categories
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text(LocalizedStrings.Actions.back.localized)
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.leading)
                            
                            Spacer()
                            
                            Text(LocalizedStrings.TabBar.settings.localized)
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // 右侧占位符，保持标题居中
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(LocalizedStrings.Actions.back.localized)
                            }
                            .foregroundColor(.clear)
                            .padding(.trailing)
                        }
                        .padding(.vertical, 12)
                        .background(Color(.systemGroupedBackground))
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color(.separator)),
                            alignment: .bottom
                        )
                        
                        // 设置内容
                        SettingsView()
                    }
                    .navigationBarHidden(true)
                }
            } else {
                // 其他页面：使用NavigationSplitView三栏布局
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
            }
        }
        .id(languageManager.currentLanguage)
        .fullScreenCover(isPresented: $showGlobalSearch) {
            if #available(iOS 16.0, *) {
                iPadGlobalSearchView(selectedKnot: $selectedKnot)
            } else {
                GlobalSearchView()
            }
        }
        .onAppear {
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
                Label(LocalizedStrings.TabBar.categories.localized, systemImage: "folder.fill")
                    .tag(SidebarItem.categories)
                
                Label(LocalizedStrings.TabBar.types.localized, systemImage: "link")
                    .tag(SidebarItem.types)
            }
            
            // 个人收藏
            Section(LocalizedStrings.CommonExtended.personal.localized) {
                Label(LocalizedStrings.TabBar.favorites.localized, systemImage: "heart.fill")
                    .badge(dataManager.favoriteKnots.count)
                    .tag(SidebarItem.favorites)
            }
            
            // 设置和其他
            Section(LocalizedStrings.CommonExtended.other.localized) {
                Label(LocalizedStrings.TabBar.settings.localized, systemImage: "gearshape.fill")
                    .tag(SidebarItem.settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(LocalizedStrings.App.title.localized)
        .onChange(of: selectedSidebarItem) { newValue in
            // 切换侧边栏项目时，清除选中的分类和绳结
            selectedCategory = nil
            selectedKnot = nil
            
            // 根据tab类型调整列布局（设置页面不使用分栏布局，所以不需要处理）
            if newValue != .settings {
                // 分类、类型和收藏tab都使用doubleColumn（显示三列）
                columnVisibility = .doubleColumn
            }
        }
    }
    
    // MARK: - 内容视图（中间列）
    @ViewBuilder
    private var contentView: some View {
        
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
                // 收藏tab：在中间列显示收藏列表
                iPadFavoritesView(selectedKnot: $selectedKnot)
                    .id("favorites")
            case .settings:
                // 设置页面现在使用独立的NavigationStack，不会进入这里
                Color.clear
            }
        } else {
            iPadWelcomeView()
        }
    }
    
    // MARK: - 详情视图（右侧列）
    @ViewBuilder
    private var detailView: some View {
        Group {
            if selectedSidebarItem == .favorites {
                // 收藏tab：显示绳结详情或占位视图
                if let selectedKnot = selectedKnot {
                    iPadKnotDetailView(knot: selectedKnot)
                        .id(selectedKnot.id) // 强制在绳结切换时重新创建视图
                } else {
                    iPadPlaceholderView()
                }
            } else if let selectedKnot = selectedKnot {
                iPadKnotDetailView(knot: selectedKnot)
                    .id(selectedKnot.id) // 强制在绳结切换时重新创建视图
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showGlobalSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                }
                .accessibilityLabel(LocalizedStrings.SearchExtended.searchAllKnots.localized)
            }
        }
    }
    
    // MARK: - 初始化数据
    private func setupInitialData() {
        
        if dataManager.categories.isEmpty && dataManager.knotTypes.isEmpty && dataManager.allKnots.isEmpty {
            dataManager.loadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dataManager.preloadImagePaths()
            }
        } else {
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