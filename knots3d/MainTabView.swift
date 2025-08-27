import SwiftUI

struct MainTabView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var searchManager = SearchManager.shared
    @State private var selectedTab: TabType = .categories
    @State private var showGlobalSearch = false
    
    var body: some View {
        ZStack {
            // 主要内容
            TabView(selection: $selectedTab) {
                // 用途分类Tab
                CategoryListView(tabType: .categories)
                    .tabItem {
                        Image(systemName: TabType.categories.iconName)
                        Text(TabType.categories.title)
                    }
                    .tag(TabType.categories)
                
                // 绳结类型Tab
                CategoryListView(tabType: .types)
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
            
            // 全局搜索按钮
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showGlobalSearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                            Text("全局搜索")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.bottom, 100) // 避免被TabBar遮挡
            }
        }
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