import SwiftUI

/// iPad专用分类列表视图 - 在NavigationSplitView的中间列显示
struct iPadCategoryListView: View {
    let tabType: TabType
    @Binding var selectedCategory: KnotCategory?
    @Binding var selectedKnot: KnotDetail?
    
    @StateObject private var dataManager = DataManager.shared
    
    private var filteredCategories: [KnotCategory] {
        let categories = tabType == .categories ? dataManager.categories : dataManager.knotTypes
        
        
        return categories
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
            // 如果没有数据，强制加载
            if dataManager.categories.isEmpty && dataManager.knotTypes.isEmpty && dataManager.allKnots.isEmpty {
                dataManager.loadData()
            }
        }
    }
    
    
    // MARK: - 分类内容
    @ViewBuilder
    private var categoryContent: some View {
        if filteredCategories.isEmpty {
            EmptyStateView(
                title: LocalizedStrings.Category.noData.localized,
                systemImage: tabType == .categories ? "folder" : "tag"
            )
        } else {
            
            // 使用ScrollView + LazyVStack 替代List，保持原有的图片显示功能
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredCategories, id: \.id) { category in
                        Button(action: {
                            selectedCategory = category
                            selectedKnot = nil
                        }) {
                            iPadCategoryRowView(
                                category: category,
                                tabType: tabType,
                                isSelected: selectedCategory?.id == category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
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
        HStack(spacing: 16) {
            categoryImage
            categoryInfo
            Spacer(minLength: 0)
            knotCountBadge
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(selectionBackground)
        .overlay(selectionBorder)
        .contentShape(Rectangle()) // 确保整个区域都可以点击
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