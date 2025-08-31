import SwiftUI

// MARK: - 搜索栏组件

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField(LocalizedStrings.Search.placeholder.localized, text: $text)
                    .onTapGesture {
                        isSearching = true
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
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
                    text = ""
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
}

// MARK: - 加载视图

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(LocalizedStrings.Loading.knots.localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 错误视图

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    let showDetails: Bool
    
    @State private var showDetailedError = false
    
    init(message: String, showDetails: Bool = false, retryAction: @escaping () -> Void) {
        self.message = message
        self.showDetails = showDetails
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(LocalizedStrings.Common.loadingFailed.localized)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            if showDetails || showDetailedError {
                Text(message)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 8) {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizedStrings.Common.retry.localized)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                if !showDetails {
                    Button(action: {
                        showDetailedError.toggle()
                    }) {
                        Text(showDetailedError ? LocalizedStrings.Common.hideDetails.localized : LocalizedStrings.Common.showDetails.localized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 空状态视图

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let subtitle: String?
    
    init(title: String, systemImage: String, subtitle: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - 工具扩展

// MARK: - Enhanced Search Components

/// 增强搜索栏
struct EnhancedSearchBar: View {
    @StateObject private var searchManager = SearchManager.shared
    @State private var showSuggestions = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField(LocalizedStrings.Search.placeholder.localized, text: $searchManager.searchText, onCommit: {
                        // 提交搜索时隐藏建议
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSuggestions = false
                        }
                        hideKeyboard()
                    })
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .modifier(ConditionalTextInputModifier())
                        .onChange(of: searchManager.searchText) { _ in
                            // 不再显示搜索建议
                            showSuggestions = false
                        }
                    
                    if searchManager.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !searchManager.searchText.isEmpty {
                        Button(action: {
                            searchManager.resetSearch()
                            withAnimation {
                                showSuggestions = false
                            }
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
                
                if showSuggestions {
                    Button(LocalizedStrings.Actions.cancel.localized) {
                        searchManager.resetSearch()
                        withAnimation {
                            showSuggestions = false
                        }
                        hideKeyboard()
                    }
                    .foregroundColor(.blue)
                    .transition(.move(edge: .trailing))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: showSuggestions)
            
            // 搜索建议已移除
        }
    }
}

/// 最近搜索视图
struct RecentSearchesView: View {
    let searches: [String]
    let onSelect: (String) -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(LocalizedStrings.Common.recentSearches.localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(LocalizedStrings.Common.clear.localized) {
                    onClear()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            ForEach(searches.prefix(5), id: \.self) { search in
                Button(action: {
                    onSelect(search)
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.gray)
                            .font(.caption)
                        
                        Text(search)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .foregroundColor(.gray)
                            .font(.caption2)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                if search != searches.prefix(5).last {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray4))
                .padding(.horizontal),
            alignment: .bottom
        )
    }
}

/// 搜索统计视图
struct SearchStatsView: View {
    let stats: SearchStats
    
    var body: some View {
        HStack {
            Text(stats.formattedSummary)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if stats.totalResults > 0 {
                Text(stats.detailedSummary)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemGray6).opacity(0.5))
    }
}

/// 空搜索结果视图
struct EmptySearchResultsView: View {
    let query: String
    let suggestions: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(LocalizedStrings.Common.searchNotFound.localized(with: query))
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStrings.Common.trySuggestions.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                SearchManager.shared.searchText = suggestion
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

/// 增强分类行视图（支持搜索高亮）
struct EnhancedCategoryRowView: View {
    let category: KnotCategory
    let searchQuery: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 图片
            CompatibleAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            
            // 文本信息
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
        }
        .padding(.vertical, 8)
    }
    
    private var imageURL: URL? {
        if let imagePath = DataManager.shared.getImagePath(for: category.image) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

/// 高亮文本视图
struct HighlightedText: View {
    let text: String
    let highlight: String
    
    var body: some View {
        if highlight.isEmpty {
            Text(text)
        } else {
            highlightedTextView
        }
    }
    
    private var highlightedTextView: some View {
        let components = splitTextWithHighlight()
        
        return HStack(spacing: 0) {
            ForEach(0..<components.count, id: \.self) { index in
                let component = components[index]
                if component.isHighlighted {
                    Text(component.text)
                        .foregroundColor(.primary)
                        .background(Color.yellow.opacity(0.3))
                } else {
                    Text(component.text)
                }
            }
        }
    }
    
    private func splitTextWithHighlight() -> [TextComponent] {
        guard !highlight.isEmpty, !text.isEmpty else {
            return [TextComponent(text: text, isHighlighted: false)]
        }
        
        let lowercaseText = text.lowercased()
        let lowercaseHighlight = highlight.lowercased()
        
        var components: [TextComponent] = []
        var searchText = text
        var searchLowercase = lowercaseText
        
        while let range = searchLowercase.range(of: lowercaseHighlight) {
            // 添加高亮前的部分
            let beforeRange = searchText.startIndex..<range.lowerBound
            if !beforeRange.isEmpty {
                let beforeText = String(searchText[beforeRange])
                if !beforeText.isEmpty {
                    components.append(TextComponent(text: beforeText, isHighlighted: false))
                }
            }
            
            // 添加高亮部分
            let highlightRange = range.lowerBound..<range.upperBound
            let highlightText = String(searchText[highlightRange])
            components.append(TextComponent(text: highlightText, isHighlighted: true))
            
            // 继续搜索剩余部分
            let remainingStart = range.upperBound
            if remainingStart < searchText.endIndex {
                searchText = String(searchText[remainingStart...])
                searchLowercase = String(searchLowercase[remainingStart...])
            } else {
                break
            }
        }
        
        // 添加剩余文本
        if !searchText.isEmpty {
            components.append(TextComponent(text: searchText, isHighlighted: false))
        }
        
        return components.isEmpty ? [TextComponent(text: text, isHighlighted: false)] : components
    }
}

private struct TextComponent {
    let text: String
    let isHighlighted: Bool
}

// MARK: - iOS 14 Compatible AsyncImage

/// iOS 14 兼容的异步图像视图
struct CompatibleAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            isLoading = false
            return
        }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                } else {
                    self.image = nil
                }
                self.isLoading = false
            }
        }.resume()
    }
}

extension CompatibleAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}

extension CompatibleAsyncImage where Placeholder == Color {
    init(url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(
            url: url,
            content: content,
            placeholder: { Color.gray.opacity(0.3) }
        )
    }
}

// MARK: - iOS 14 Compatible Modifiers

struct ConditionalTextInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .textInputAutocapitalization(.never)
        } else {
            content
                .autocapitalization(.none)
        }
    }
}

struct ConditionalSearchModifier: ViewModifier {
    @Binding var searchText: String
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: LocalizedStrings.Search.placeholder.localized
                )
        } else {
            VStack(spacing: 0) {
                // iOS 14 兼容的搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField(LocalizedStrings.Search.placeholder.localized, text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .modifier(ConditionalTextInputModifier())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                content
            }
        }
    }
}

// MARK: - Fake Search Bar (Button Style)

/// 假搜索栏 - 看起来像输入框但实际是按钮，点击时进入全局搜索
struct FakeSearchBar: View {
    let placeholder: String
    let onTap: () -> Void
    
    init(placeholder: String = "搜索绳结名称或描述", onTap: @escaping () -> Void) {
        self.placeholder = placeholder
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 搜索图标
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
                
                // 占位符文本
                Text(placeholder)
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Extensions

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}