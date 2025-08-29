import SwiftUI

/// 绳结列表视图（点击分类后显示的绳结列表）
struct KnotListView: View {
    let category: KnotCategory
    let tabType: TabType
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBar(text: $searchText, isSearching: $isSearching)
            
            // 绳结列表
            if filteredKnots.isEmpty {
                if searchText.isEmpty {
                    EmptyStateView(
                        title: "暂无绳结",
                        systemImage: "link",
                        subtitle: "该分类下暂时没有相关绳结"
                    )
                } else {
                    EmptyStateView(
                        title: LocalizedStrings.Search.noResults.localized,
                        systemImage: "magnifyingglass"
                    )
                }
            } else {
                List(filteredKnots) { knot in
                    NavigationLink(destination: KnotDetailView(knot: knot)) {
                        KnotRowView(knot: knot, showFavoriteButton: false)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
    
    private var filteredKnots: [KnotDetail] {
        if searchText.isEmpty {
            return baseKnots
        } else {
            let lowercaseQuery = searchText.lowercased()
            return baseKnots.filter {
                $0.name.lowercased().contains(lowercaseQuery) ||
                $0.description.lowercased().contains(lowercaseQuery)
            }
        }
    }
}

#Preview {
    NavigationView {
        KnotListView(
            category: KnotCategory(
                type: "category",
                name: "Essential Knots",
                desc: "How to tie 18 essential knots.",
                image: "essential_knots.jpg"
            ),
            tabType: .categories
        )
    }
}