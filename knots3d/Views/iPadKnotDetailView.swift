import SwiftUI

/// iPad专用绳结详情视图 - 优化大屏幕显示
struct iPadKnotDetailView: View {
    let knot: KnotDetail
    
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedAnimationType: AnimationType = .drawing
    @State private var showFullScreenAnimation = false
    @State private var selectedKnot: KnotDetail
    @State private var shouldScrollToTop = false
    
    init(knot: KnotDetail) {
        self.knot = knot
        self._selectedKnot = State(initialValue: knot)
    }
    
    private var isFavorite: Bool {
        dataManager.favoriteKnots.contains(selectedKnot.id)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部信息区域
                        headerSection
                            .id("top")
                    
                    if geometry.size.width > 800 {
                        // 横屏或大屏幕：左右分栏布局
                        HStack(alignment: .top, spacing: 24) {
                            // 左侧：动画区域
                            VStack {
                                animationSection
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            
                            // 右侧：详情信息
                            VStack(alignment: .leading, spacing: 24) {
                                detailsSection
                                relatedKnotsInlineSection
                                classificationSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    } else {
                        // 竖屏：垂直布局
                        VStack(spacing: 24) {
                            animationSection
                            detailsSection
                            relatedKnotsInlineSection
                            classificationSection
                        }
                        .padding()
                    }
                }
                .onChange(of: shouldScrollToTop) { _ in
                    if shouldScrollToTop {
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        shouldScrollToTop = false
                    }
                }
            }
            }
        }
        .navigationTitle(selectedKnot.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFullScreenAnimation) {
            fullScreenAnimationView
        }
    }
    
    // MARK: - 头部信息区域
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 绳结标题和别名
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(selectedKnot.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 收藏按钮
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(isFavorite ? .red : .gray)
                    }
                }
                
                if let aliases = selectedKnot.aliases, !aliases.isEmpty {
                    Text(LocalizedStrings.KnotDetailExtended.alsoKnownAs.localized + ": " + aliases.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            // 绳结描述
            Text(selectedKnot.description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - 动画区域
    @ViewBuilder
    private var animationSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(LocalizedStrings.KnotDetailExtended.animation.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 全屏按钮
                Button(action: { showFullScreenAnimation = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // 动画视图
            GeometryReader { animationGeometry in
                let spriteHeight = min(animationGeometry.size.width * 1.2, 320)
                animationView(width: animationGeometry.size.width, height: spriteHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            }
            .frame(height: 420) // 增加高度为控制按钮留出空间
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 详情信息区域
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.KnotDetailExtended.details.localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                detailRow(title: LocalizedStrings.KnotDetailExtended.usage.localized, 
                         content: selectedKnot.details.usage)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.history.localized, 
                         content: selectedKnot.details.history)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.structure.localized, 
                         content: selectedKnot.details.structure)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.strengthReliability.localized, 
                         content: selectedKnot.details.strengthReliability)
                
                detailRowWithLeftAlignment(title: LocalizedStrings.KnotDetailExtended.abok.localized, 
                                          content: selectedKnot.details.abok)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.note.localized, 
                         content: selectedKnot.details.note)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 相关绳结区域
    @ViewBuilder
    private var relatedKnotsInlineSection: some View {
        if let related = selectedKnot.related, !related.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStrings.KnotDetailExtended.relatedKnots.localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                let relatedKnots = dataManager.getKnotsByNames(related)
                
                if relatedKnots.isEmpty {
                    Text(LocalizedStrings.KnotDetailExtended.noRelatedKnots.localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(relatedKnots.prefix(4)) { relatedKnot in
                            RelatedKnotCardView(knot: relatedKnot) {
                                // 点击相关绳结，切换到对应绳结详情并回到顶部
                                selectedKnot = relatedKnot
                                shouldScrollToTop = true
                            }
                        }
                    }
                    
                    if relatedKnots.count > 4 {
                        Text(LocalizedStrings.CommonExtended.andMore.localized(with: relatedKnots.count - 4))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - 分类信息区域
    @ViewBuilder
    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.KnotDetailExtended.classification.localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                // 绳结类型
                if !selectedKnot.classification.type.isEmpty {
                    classificationRow(
                        title: LocalizedStrings.KnotDetailExtended.types.localized,
                        items: selectedKnot.classification.type,
                        color: .blue
                    )
                }
                
                // 应用场景
                if !selectedKnot.classification.foundIn.isEmpty {
                    classificationRow(
                        title: LocalizedStrings.KnotDetailExtended.foundIn.localized,
                        items: selectedKnot.classification.foundIn,
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 辅助方法
    @ViewBuilder
    private func detailRow(title: String, content: String?) -> some View {
        if let content = content, !content.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func detailRowWithLeftAlignment(title: String, content: String?) -> some View {
        if let content = content, !content.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func classificationRow(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            SimpleFlowLayout(items: items, color: color)
        }
    }
    
    @ViewBuilder
    private func animationView(width: CGFloat, height: CGFloat) -> some View {
        Group {
            if let animation = currentAnimation {
                SpriteKitAnimationView(
                    width: width,
                    height: height,
                    showControls: true,
                    animationData: KnotAnimation(
                        drawingAnimation: animation,
                        rotation360: selectedKnot.animation?.rotation360
                    )
                )
                .id(selectedKnot.id) // 强制在绳结切换时重新创建动画视图
            } else {
                // 静态图片占位
                CompatibleAsyncImage(url: staticImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: width, height: height)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: width, height: height)
                        .overlay(
                            Image(systemName: "link")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                .id(selectedKnot.id) // 确保静态图片也会正确更新
            }
        }
        .cornerRadius(12)
    }
    
    private var fullScreenAnimationView: some View {
        GeometryReader { fullScreenGeometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button(LocalizedStrings.Actions.done.localized) {
                            showFullScreenAnimation = false
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                    }
                    
                    // 在动画视图上方添加Spacer实现垂直居中
                    Spacer()
                    
                    let screenSize = fullScreenGeometry.size
                    let animationSize = min(screenSize.width * 0.85, screenSize.height * 0.6)
                    
                    // 全屏动画视图
                    Group {
                        if let animation = currentAnimation {
                            SpriteKitAnimationView(
                                width: animationSize,
                                height: animationSize,
                                showControls: true,
                                animationData: KnotAnimation(
                                    drawingAnimation: animation,
                                    rotation360: selectedKnot.animation?.rotation360
                                )
                            )
                            .id("fullscreen-\(selectedKnot.id)") // 确保全屏时重新创建
                        } else {
                            // 静态图片占位
                            CompatibleAsyncImage(url: staticImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: animationSize, height: animationSize)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: animationSize, height: animationSize)
                                    .overlay(
                                        Image(systemName: "link")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }
                    .cornerRadius(12)
                    
                    Spacer()
                }
            }
        }
    }
    
    
    // MARK: - 计算属性
    private var currentAnimation: AnimationFiles? {
        switch selectedAnimationType {
        case .drawing:
            return selectedKnot.animation?.drawingAnimation
        case .rotation:
            return selectedKnot.animation?.rotation360
        }
    }
    
    private var hasMultipleAnimations: Bool {
        let hasDrawing = selectedKnot.animation?.drawingAnimation != nil
        let hasRotation = selectedKnot.animation?.rotation360 != nil
        return hasDrawing && hasRotation
    }
    
    private var staticImageURL: URL? {
        if let cover = selectedKnot.cover,
           let imagePath = dataManager.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
    
    private func toggleFavorite() {
        dataManager.toggleFavorite(selectedKnot.id)
    }
}

// MARK: - 动画类型枚举
enum AnimationType: CaseIterable {
    case drawing
    case rotation
}

// MARK: - 相关绳结卡片视图
struct RelatedKnotCardView: View {
    let knot: KnotDetail
    let onTap: () -> Void
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                CompatibleAsyncImage(url: knotImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "link")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120) // 增加高度从80到120，让图片更完整
                .clipped()
                .cornerRadius(8)
            
                Text(knot.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var knotImageURL: URL? {
        if let cover = knot.cover,
           let imagePath = dataManager.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

// MARK: - 简单流式布局（兼容iOS 14+）
struct SimpleFlowLayout: View {
    let items: [String]
    let color: Color
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(items.chunked(into: 3), id: \.self) { rowItems in
                HStack(spacing: 8) {
                    ForEach(rowItems, id: \.self) { item in
                        Text(item)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.2))
                            .foregroundColor(color)
                            .cornerRadius(12)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Array Extension
extension Array where Element == String {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    // 预览需要模拟数据
    let mockKnot = KnotDetail(
        id: "bowline",
        name: "Bowline",
        cover: "bowline.webp",
        aliases: ["King of Knots"],
        description: "The bowline is an ancient and simple knot used to form a fixed loop at the end of a rope.",
        animation: KnotAnimation(
            drawingAnimation: AnimationFiles(spriteData: "bowline.json", spriteImage: "bowline.png"),
            rotation360: nil
        ),
        details: KnotDetails(
            usage: "One of the most useful knots, the bowline fastens securely but can be untied easily.",
            history: "An ancient knot used by sailors for centuries.",
            alsoKnownAs: "King of Knots",
            structure: "Forms a secure loop that won't slip.",
            strengthReliability: "Very strong and reliable.",
            abok: "#1010",
            note: "Easy to untie even after being under load."
        ),
        related: ["Figure Eight", "Sheet Bend"],
        classification: KnotClassification(
            type: ["Loop", "Essential"],
            foundIn: ["Boating", "Climbing", "Rescue"]
        )
    )
    
    if #available(iOS 16.0, *) {
        return NavigationStack {
            iPadKnotDetailView(knot: mockKnot)
        }
    } else {
        return NavigationView {
            iPadKnotDetailView(knot: mockKnot)
        }
    }
}
