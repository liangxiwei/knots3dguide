import Foundation

// MARK: - Knots Data Models

/// 分类/类型数据模型 (knots_data.json)
struct KnotCategory: Codable, Identifiable, Hashable {
    let id = UUID()
    let type: String        // "category" 或 "type"
    let name: String        // 分类名称
    let desc: String        // 描述
    let image: String       // 图片名称
    
    private enum CodingKeys: String, CodingKey {
        case type, name, desc, image
    }
}

/// 详细绳结数据模型 (all_knots_data.json)
struct AllKnotsData: Codable {
    let extractedAt: String
    let totalKnots: Int
    let knots: [KnotDetail]
}

/// 绳结详情模型
struct KnotDetail: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cover: String?
    let aliases: [String]?
    let description: String
    let animation: KnotAnimation?
    let details: KnotDetails
    let related: [String]?
    let classification: KnotClassification
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: KnotDetail, rhs: KnotDetail) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 动画信息
struct KnotAnimation: Codable {
    let drawingAnimation: AnimationFiles?
    let rotation360: AnimationFiles?
}

/// 动画文件
struct AnimationFiles: Codable {
    let spriteData: String
    let spriteImage: String
}

/// 绳结详细信息
struct KnotDetails: Codable {
    let usage: String?
    let history: String?
    let alsoKnownAs: String?
    let structure: String?
    let strengthReliability: String?
    let abok: String?
    let note: String?
}

/// 分类信息
struct KnotClassification: Codable {
    let type: [String]
    let foundIn: [String]
}

// MARK: - App State Models

/// Tab类型枚举
enum TabType: String, CaseIterable {
    case categories = "categories"
    case types = "types"  
    case favorites = "favorites"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .categories:
            return LocalizedStrings.TabBar.categories.localized
        case .types:
            return LocalizedStrings.TabBar.types.localized
        case .favorites:
            return LocalizedStrings.TabBar.favorites.localized
        case .settings:
            return LocalizedStrings.TabBar.settings.localized
        }
    }
    
    var iconName: String {
        switch self {
        case .categories:
            return "folder.fill"
        case .types:
            return "link"
        case .favorites:
            return "heart.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

/// 列表项模型（用于统一展示）
struct ListItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageName: String?
    let type: ListItemType
    
    enum ListItemType {
        case category
        case knotType  
        case knot
    }
}

// MARK: - Search Models

/// 搜索结果模型
struct SearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let matchType: SearchMatchType
    let originalItem: Any
    
    enum SearchMatchType {
        case name
        case description
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }
}