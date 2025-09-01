import SwiftUI

/// iPad专用绳结详情视图 - 优化大屏幕显示
struct iPadKnotDetailView: View {
    let knot: KnotDetail
    
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedAnimationType: AnimationType = .drawing
    @State private var showFullScreenAnimation = false
    
    private var isFavorite: Bool {
        dataManager.favoriteKnots.contains(knot.id)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部信息区域
                    headerSection
                    
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
                                relatedAndClassificationSection
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                    } else {
                        // 竖屏：垂直布局
                        VStack(spacing: 24) {
                            animationSection
                            detailsSection
                            relatedAndClassificationSection
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(knot.name)
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
                    Text(knot.name)
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
                
                if let aliases = knot.aliases, !aliases.isEmpty {
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
            Text(knot.description)
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
            
            // 动画类型选择
            if hasMultipleAnimations {
                Picker(LocalizedStrings.KnotDetailExtended.animationType.localized, selection: $selectedAnimationType) {
                    if knot.animation?.drawingAnimation != nil {
                        Text(LocalizedStrings.KnotDetailExtended.drawingAnimation.localized)
                            .tag(AnimationType.drawing)
                    }
                    if knot.animation?.rotation360 != nil {
                        Text(LocalizedStrings.KnotDetailExtended.rotation360.localized)
                            .tag(AnimationType.rotation)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
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
                         content: knot.details.usage)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.history.localized, 
                         content: knot.details.history)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.structure.localized, 
                         content: knot.details.structure)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.strengthReliability.localized, 
                         content: knot.details.strengthReliability)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.abok.localized, 
                         content: knot.details.abok)
                
                detailRow(title: LocalizedStrings.KnotDetailExtended.note.localized, 
                         content: knot.details.note)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - 相关绳结和分类信息区域
    @ViewBuilder
    private var relatedAndClassificationSection: some View {
        VStack(spacing: 20) {
            // 相关绳结
            if let related = knot.related, !related.isEmpty {
                relatedKnotsSection(relatedNames: related)
            }
            
            // 分类信息
            classificationSection
        }
    }
    
    // MARK: - 相关绳结区域
    @ViewBuilder
    private func relatedKnotsSection(relatedNames: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.KnotDetailExtended.relatedKnots.localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            let relatedKnots = dataManager.getKnotsByNames(relatedNames)
            
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
                        RelatedKnotCardView(knot: relatedKnot)
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
    
    // MARK: - 分类信息区域
    @ViewBuilder
    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStrings.KnotDetailExtended.classification.localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                // 绳结类型
                if !knot.classification.type.isEmpty {
                    classificationRow(
                        title: LocalizedStrings.KnotDetailExtended.types.localized,
                        items: knot.classification.type,
                        color: .blue
                    )
                }
                
                // 应用场景
                if !knot.classification.foundIn.isEmpty {
                    classificationRow(
                        title: LocalizedStrings.KnotDetailExtended.foundIn.localized,
                        items: knot.classification.foundIn,
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
                        rotation360: knot.animation?.rotation360
                    )
                )
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
            }
        }
        .cornerRadius(12)
    }
    
    private var fullScreenAnimationView: some View {
        GeometryReader { fullScreenGeometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        Button(LocalizedStrings.Actions.done.localized) {
                            showFullScreenAnimation = false
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    let screenSize = fullScreenGeometry.size
                    let animationSize = min(screenSize.width * 0.8, screenSize.height * 0.7)
                    
                    animationView(width: animationSize, height: animationSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer()
                }
            }
        }
    }
    
    
    // MARK: - 计算属性
    private var currentAnimation: AnimationFiles? {
        switch selectedAnimationType {
        case .drawing:
            return knot.animation?.drawingAnimation
        case .rotation:
            return knot.animation?.rotation360
        }
    }
    
    private var hasMultipleAnimations: Bool {
        let hasDrawing = knot.animation?.drawingAnimation != nil
        let hasRotation = knot.animation?.rotation360 != nil
        return hasDrawing && hasRotation
    }
    
    private var staticImageURL: URL? {
        if let cover = knot.cover,
           let imagePath = dataManager.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
    
    private func toggleFavorite() {
        dataManager.toggleFavorite(knot.id)
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
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
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
            .frame(height: 80)
            .clipped()
            .cornerRadius(8)
            
            Text(knot.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
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