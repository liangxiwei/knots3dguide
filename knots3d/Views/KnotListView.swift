import SwiftUI

/// 绳结列表视图（点击分类后显示的绳结列表）
struct KnotListView: View {
    let category: KnotCategory
    let tabType: TabType
    
    @StateObject private var dataManager = DataManager.shared
    @State private var searchText = ""
    
    var body: some View {
        Group {
            if filteredKnots.isEmpty {
                if searchText.isEmpty {
                    EmptyStateView(
                        title: LocalizedStrings.KnotList.noKnots.localized,
                        systemImage: "link",
                        subtitle: LocalizedStrings.KnotList.noKnotsInCategory.localized
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
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: LocalizedStrings.Search.placeholder.localized
        )
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