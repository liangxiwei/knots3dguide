import SwiftUI

struct KnotDetailView: View {
    let knot: KnotDetail

    @StateObject private var dataManager = DataManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. 标题区域
                titleSection

                // 2. 3D动画区域
                animationSection

                // 3. 详情信息卡片
                detailsSection

                // 4. 相关绳结区域
                if let related = knot.related, !related.isEmpty {
                    relatedKnotsSection(relatedNames: related)
                }

                // 5. 分类信息
                classificationSection
            }
            .padding()
        }
        .navigationTitle(knot.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: favoriteButton)
    }

    // MARK: - Title Section

    @ViewBuilder
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(knot.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()
            }

            // 别名
            if let aliases = knot.aliases, !aliases.isEmpty {
                Text(
                    LocalizedStrings.Detail.aliases.localized + ": "
                        + aliases.joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }

            // // 描述
            // Text(knot.description)
            //     .font(.body)
            //     .foregroundColor(.primary)
            //     .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Animation Section

    @ViewBuilder
    private var animationSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(LocalizedStrings.KnotDetail.animationDemo.localized)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

            }

            if let animation = knot.animation {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let animationHeight: CGFloat = 300
                    let controlsHeight: CGFloat = 80
                    let totalHeight = animationHeight + controlsHeight
                    
                    SpriteKitAnimationView(
                        width: availableWidth,
                        height: animationHeight,
                        showControls: true,
                        animationData: animation
                    )
                    .frame(width: availableWidth, height: totalHeight)
                }
                .frame(height: 380)
                .frame(minHeight: 380, maxHeight: 380)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(LocalizedStrings.KnotDetail.noAnimationAvailable.localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
            }

        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Details Section

    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(LocalizedStrings.KnotDetail.detailedInfo.localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(spacing: 12) {
                // 用途 - 必显示
                if let usage = knot.details.usage, !usage.isEmpty {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.usage.localized,
                        content: usage,
                        icon: "target"
                    )
                }

                // 历史 - 条件显示
                if let history = knot.details.history, !history.isEmpty {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.history.localized,
                        content: history,
                        icon: "book"
                    )
                }

                // 结构 - 条件显示
                if let structure = knot.details.structure, !structure.isEmpty {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.structure.localized,
                        content: structure,
                        icon: "building.2"
                    )
                }

                // 强度可靠性 - 条件显示
                if let strengthReliability = knot.details.strengthReliability,
                    !strengthReliability.isEmpty
                {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.strengthReliability.localized,
                        content: strengthReliability,
                        icon: "bolt"
                    )
                }

                // ABOK编号 - 条件显示
                if let abok = knot.details.abok, !abok.isEmpty {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.abokNumber.localized,
                        content: abok,
                        icon: "book.closed"
                    )
                }

                // 注意事项 - 条件显示
                if let note = knot.details.note, !note.isEmpty {
                    DetailInfoCard(
                        title: LocalizedStrings.Detail.notes.localized,
                        content: note,
                        icon: "exclamationmark.triangle",
                        accentColor: .orange
                    )
                }
            }
        }
    }

    // MARK: - Related Knots Section

    @ViewBuilder
    private func relatedKnotsSection(relatedNames: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStrings.Detail.relatedKnots.localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 12
            ) {
                ForEach(relatedNames.prefix(9), id: \.self) { relatedName in
                    if let relatedKnot = findRelatedKnot(name: relatedName) {
                        NavigationLink(
                            destination: KnotDetailView(knot: relatedKnot)
                        ) {
                            RelatedKnotCard(knot: relatedKnot)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        RelatedKnotCard(knotName: relatedName)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Classification Section

    @ViewBuilder
    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedStrings.Detail.classification.localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                // 类型
                if !knot.classification.type.isEmpty {
                    HStack {
                        Text(LocalizedStrings.Detail.type.localized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        FlowLayout(items: knot.classification.type) { type in
                            NavigationLink(destination: createKnotListView(for: type, tabType: .types)) {
                                Text(type)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // 应用领域
                if !knot.classification.foundIn.isEmpty {
                    HStack {
                        Text(LocalizedStrings.Detail.foundIn.localized + ":")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        FlowLayout(items: knot.classification.foundIn) {
                            foundIn in
                            NavigationLink(destination: createKnotListView(for: foundIn, tabType: .categories)) {
                                Text(foundIn)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Favorite Button

    @ViewBuilder
    private var favoriteButton: some View {
        Button(action: {
            dataManager.toggleFavorite(knot.id)
        }) {
            Image(
                systemName: dataManager.isFavorite(knot.id)
                    ? "heart.fill" : "heart"
            )
            .foregroundColor(dataManager.isFavorite(knot.id) ? .red : .blue)
            .font(.title2)
        }
    }

    // MARK: - Helper Functions

    private func findRelatedKnot(name: String) -> KnotDetail? {
        return dataManager.allKnots.first { knot in
            knot.name == name || knot.aliases?.contains(name) == true
        }
    }
    
    private func createKnotListView(for categoryName: String, tabType: TabType) -> KnotListView {
        let category = KnotCategory(
            type: tabType == .categories ? "category" : "type",
            name: categoryName,
            desc: "",
            image: ""
        )
        return KnotListView(category: category, tabType: tabType)
    }
}

// MARK: - Detail Info Card

struct DetailInfoCard: View {
    let title: String
    let content: String
    let icon: String
    let accentColor: Color

    init(
        title: String,
        content: String,
        icon: String,
        accentColor: Color = .blue
    ) {
        self.title = title
        self.content = content
        self.icon = icon
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .frame(width: 20)

                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }

            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Related Knot Card

struct RelatedKnotCard: View {
    let knot: KnotDetail?
    let knotName: String

    // 支持两种初始化方式
    init(knot: KnotDetail) {
        self.knot = knot
        self.knotName = knot.name
    }

    init(knotName: String) {
        self.knot = nil
        self.knotName = knotName
    }

    var body: some View {
        VStack(spacing: 6) {
            // 图片区域
            AsyncImage(url: coverImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "link")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipped()
            .cornerRadius(6)

            Text(knotName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }

    private var coverImageURL: URL? {
        guard let knot = knot, let cover = knot.cover else { return nil }
        if let imagePath = DataManager.shared.getImagePath(for: cover) {
            return URL(fileURLWithPath: imagePath)
        }
        return nil
    }
}

// MARK: - Flow Layout

struct FlowLayout<Item, ItemView>: View where Item: Hashable, ItemView: View {
    let items: [Item]
    let itemView: (Item) -> ItemView

    init(items: [Item], @ViewBuilder itemView: @escaping (Item) -> ItemView) {
        self.items = items
        self.itemView = itemView
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.chunked(into: 3)), id: \.self) { rowItems in
                HStack {
                    ForEach(rowItems, id: \.self) { item in
                        itemView(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    NavigationView {
        KnotDetailView(
            knot: KnotDetail(
                id: "sample",
                name: "Sample Knot",
                cover: nil,
                aliases: ["Alias 1", "Alias 2"],
                description: "A sample knot for preview purposes.",
                animation: nil,
                details: KnotDetails(
                    usage: "Sample usage description",
                    history: "Sample history",
                    alsoKnownAs: "Sample aliases",
                    structure: "Sample structure",
                    strengthReliability: "Sample strength info",
                    abok: "#123",
                    note: "Sample note"
                ),
                related: ["Related Knot 1", "Related Knot 2"],
                classification: KnotClassification(
                    type: ["Sample Type"],
                    foundIn: ["Sample Category"]
                )
            )
        )
    }
}
