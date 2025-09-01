import SwiftUI

/// iPad专用全局搜索视图 - 适配大屏布局
@available(iOS 16.0, *)
struct iPadGlobalSearchView: View {
    @StateObject private var searchManager = SearchManager.shared
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedKnot: KnotDetail?
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // 左侧搜索栏和结果统计
                VStack(spacing: 0) {
                    searchHeader
                    
                    if searchManager.searchText.isEmpty {
                        emptySearchState
                    } else if searchManager.isSearching {
                        LoadingView()
                    } else if knotSearchResults.isEmpty {
                        noResultsState
                    } else {
                        searchResultsSidebar
                    }
                }
                .frame(maxWidth: 350)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // 右侧详情区域
                if let selectedResult = selectedSearchResult {
                    iPadKnotDetailView(knot: selectedResult.knot)
                        .id(selectedResult.knot.id) // 强制在绳结切换时重新创建详情视图
                } else {
                    searchPlaceholderView
                }
            }
            .navigationTitle(LocalizedStrings.Search.globalSearch.localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text(LocalizedStrings.Actions.back.localized)
                                .font(.system(size: 17))
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    @State private var selectedSearchResult: KnotSearchResult?
    
    // MARK: - 搜索头部
    @ViewBuilder
    private var searchHeader: some View {
        VStack(spacing: 16) {
            // 搜索栏
            EnhancedSearchBar()
            
            // 搜索统计
            if !knotSearchResults.isEmpty {
                knotSearchStatsView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 搜索结果侧边栏
    @ViewBuilder
    private var searchResultsSidebar: some View {
        List(knotSearchResults) { result in
            Button(action: {
                selectedSearchResult = result
                selectedKnot = result.knot
            }) {
                iPadSearchResultRowView(
                    searchResult: result,
                    isSelected: selectedSearchResult?.knot.id == result.knot.id
                )
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }
    
    // MARK: - 空状态视图
    @ViewBuilder
    private var emptySearchState: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.3))
            
            VStack(spacing: 12) {
                Text(LocalizedStrings.Search.discoverKnots.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(LocalizedStrings.Search.searchPlaceholderDesc.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 无结果状态
    @ViewBuilder
    private var noResultsState: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(LocalizedStrings.Search.noResultsFound.localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(LocalizedStrings.Search.tryOtherKeywords.localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - 搜索占位视图
    @ViewBuilder
    private var searchPlaceholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(LocalizedStrings.CommonExtended.selectItem.localized)
                .font(.title2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 搜索统计视图
    @ViewBuilder
    private var knotSearchStatsView: some View {
        let results = knotSearchResults
        if !results.isEmpty {
            VStack(spacing: 8) {
                HStack {
                    Text(LocalizedStrings.Search.foundKnots.localized(with: results.count))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(LocalizedStrings.Search.sortedByRelevance.localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 匹配类型分布
                if !results.isEmpty {
                    let matchTypes = getMatchTypeDistribution(results: results)
                    if !matchTypes.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(matchTypes, id: \.0) { type, count in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(getMatchTypeColor(type))
                                        .frame(width: 6, height: 6)
                                    Text("\(type): \(count)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 数据和方法
    private var knotSearchResults: [KnotSearchResult] {
        return searchManager.searchKnotsComprehensive(searchManager.searchText)
    }
    
    // 获取匹配类型分布统计
    private func getMatchTypeDistribution(results: [KnotSearchResult]) -> [(String, Int)] {
        var distribution: [String: Int] = [:]
        
        for result in results {
            let type = result.matchTypeDescription
            distribution[type] = (distribution[type] ?? 0) + 1
        }
        
        return distribution.sorted { $0.1 > $1.1 }.prefix(3).map { ($0.key, $0.value) }
    }
    
    // 获取匹配类型对应的颜色
    private func getMatchTypeColor(_ type: String) -> Color {
        switch type {
        case LocalizedStrings.Search.nameMatch.localized:
            return .blue
        case LocalizedStrings.Search.aliasMatch.localized:
            return .green
        case LocalizedStrings.Search.descriptionMatch.localized:
            return .orange
        case LocalizedStrings.Search.categoryMatch.localized:
            return .purple
        case LocalizedStrings.Search.typeMatch.localized:
            return .pink
        case LocalizedStrings.Search.fuzzyMatch.localized:
            return .gray
        default:
            return .secondary
        }
    }
}

// MARK: - iPad搜索结果行视图
struct iPadSearchResultRowView: View {
    let searchResult: KnotSearchResult
    let isSelected: Bool
    
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // 绳结图片
            CompatibleAsyncImage(url: coverImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "link")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                // 绳结名称
                HStack(alignment: .top, spacing: 6) {
                    Text(searchResult.knot.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    // 收藏状态
                    if dataManager.isFavorite(searchResult.knot.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                // 匹配类型和相关度
                HStack(spacing: 6) {
                    // 匹配类型标签
                    HStack(spacing: 3) {
                        Circle()
                            .fill(getMatchTypeColor(searchResult.matchTypeDescription))
                            .frame(width: 4, height: 4)
                        
                        Text(searchResult.matchTypeDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer(minLength: 0)
                    
                    // 相关度分数
                    Text(String(format: "%.0f", searchResult.relevanceScore))
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.gray)
                        .cornerRadius(2)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle()) // 确保整个区域都可以点击
    }
    
    private var coverImageURL: URL? {
        guard let cover = searchResult.knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
    
    // 获取匹配类型对应的颜色
    private func getMatchTypeColor(_ type: String) -> Color {
        switch type {
        case LocalizedStrings.Search.nameMatch.localized:
            return .blue
        case LocalizedStrings.Search.aliasMatch.localized:
            return .green
        case LocalizedStrings.Search.descriptionMatch.localized:
            return .orange
        case LocalizedStrings.Search.categoryMatch.localized:
            return .purple
        case LocalizedStrings.Search.typeMatch.localized:
            return .pink
        case LocalizedStrings.Search.fuzzyMatch.localized:
            return .gray
        default:
            return .secondary
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        iPadGlobalSearchView(selectedKnot: .constant(nil))
    } else {
        Text("iPad Global Search View requires iOS 16+")
    }
}