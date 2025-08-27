import SwiftUI

struct MainTabView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var searchManager = SearchManager.shared
    @State private var selectedTab: TabType = .categories
    @State private var showGlobalSearch = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 用途分类Tab
            CategoryListView(tabType: .categories, onSearchTap: {
                showGlobalSearch = true
            })
            .tabItem {
                Image(systemName: TabType.categories.iconName)
                Text(TabType.categories.title)
            }
            .tag(TabType.categories)
            
            // 绳结类型Tab
            CategoryListView(tabType: .types, onSearchTap: {
                showGlobalSearch = true
            })
            .tabItem {
                Image(systemName: TabType.types.iconName)
                Text(TabType.types.title)
            }
            .tag(TabType.types)
            
            // 收藏Tab
            FavoritesView()
                .tabItem {
                    Image(systemName: TabType.favorites.iconName)
                    Text(TabType.favorites.title)
                }
                .tag(TabType.favorites)
            
            // 设置Tab
            SettingsView()
                .tabItem {
                    Image(systemName: TabType.settings.iconName)
                    Text(TabType.settings.title)
                }
                .tag(TabType.settings)
        }
        .accentColor(.blue)
        .fullScreenCover(isPresented: $showGlobalSearch) {
            GlobalSearchView()
        }
        .onAppear {
            // 应用启动时加载数据
            if dataManager.categories.isEmpty && dataManager.knotTypes.isEmpty && dataManager.allKnots.isEmpty {
                dataManager.loadData()
                
                // 预加载常用图片路径
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    dataManager.preloadImagePaths()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}