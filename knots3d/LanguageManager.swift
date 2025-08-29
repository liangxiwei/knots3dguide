import SwiftUI
import Foundation

// MARK: - 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = "zh-Hans"
    
    private init() {
        // 获取用户偏好的语言，默认为中文
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage") {
            currentLanguage = savedLanguage
        } else {
            // 如果没有保存的语言偏好，使用系统语言
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "zh"
            currentLanguage = systemLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
        }
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    var availableLanguages: [(code: String, name: String)] {
        return [
            ("zh-Hans", "中文"),
            ("en", "English")
        ]
    }
}

// MARK: - 本地化扩展
extension String {
    /// 获取本地化字符串
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 获取带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = NSLocalizedString(self, comment: "")
        return String(format: localizedString, arguments: arguments)
    }
}

// MARK: - 本地化字符串常量
struct LocalizedStrings {
    
    // MARK: - Tab Bar
    struct TabBar {
        static let categories = "tab_categories"
        static let types = "tab_types"
        static let favorites = "tab_favorites"
        static let settings = "tab_settings"
    }
    
    // MARK: - Common Actions
    struct Actions {
        static let search = "action_search"
        static let cancel = "action_cancel"
        static let ok = "action_ok"
        static let save = "action_save"
        static let back = "action_back"
        static let done = "action_done"
    }
    
    // MARK: - Search
    struct Search {
        static let placeholder = "search_placeholder"
        static let noResults = "search_no_results"
        static let resultsCount = "search_results_count"
    }
    
    // MARK: - Knot Detail
    struct Detail {
        static let usage = "detail_usage"
        static let history = "detail_history"
        static let aliases = "detail_aliases"
        static let structure = "detail_structure"
        static let strengthReliability = "detail_strength_reliability"
        static let abokNumber = "detail_abok_number"
        static let notes = "detail_notes"
        static let relatedKnots = "detail_related_knots"
        static let classification = "detail_classification"
        static let type = "detail_type"
        static let foundIn = "detail_found_in"
    }
    
    // MARK: - Animation Controls
    struct Controls {
        static let play = "control_play"
        static let pause = "control_pause"
        static let stop = "control_stop"
        static let mirror = "control_mirror"
        static let mode360 = "control_360_mode"
        static let saveFrame = "control_save_frame"
    }
    
    // MARK: - Favorites
    struct Favorites {
        static let empty = "favorites_empty"
        static let add = "favorites_add"
        static let remove = "favorites_remove"
        static let added = "favorites_added"
        static let removed = "favorites_removed"
    }
    
    // MARK: - Settings
    struct Settings {
        static let language = "settings_language"
        static let languageChinese = "settings_language_chinese"
        static let languageEnglish = "settings_language_english"
        static let privacyPolicy = "settings_privacy_policy"
        static let versionInfo = "settings_version_info"
        static let about = "settings_about"
        static let appVersion = "settings_app_version"
    }
    
    // MARK: - Alerts
    struct Alerts {
        static let error = "alert_error"
        static let success = "alert_success"
        static let confirm = "alert_confirm"
    }
    
    // MARK: - Loading States
    struct Loading {
        static let knots = "loading_knots"
        static let animation = "loading_animation"
    }
    
    // MARK: - Error Messages
    struct Errors {
        static let loadData = "error_load_data"
        static let animationLoad = "error_animation_load"
        static let network = "error_network"
    }
    
    // MARK: - Privacy Policy
    struct Privacy {
        static let title = "privacy_title"
        static let dataCollection = "privacy_data_collection"
        static let dataCollectionContent = "privacy_data_collection_content"
        static let dataUsage = "privacy_data_usage"
        static let dataUsageContent = "privacy_data_usage_content"
        static let dataStorage = "privacy_data_storage"
        static let dataStorageContent = "privacy_data_storage_content"
        static let contact = "privacy_contact"
        static let contactContent = "privacy_contact_content"
    }
    
    // MARK: - About
    struct About {
        static let title = "about_title"
        static let description = "about_description"
        static let features = "about_features"
        static let featuresContent = "about_features_content"
        static let dataSource = "about_data_source"
        static let dataSourceContent = "about_data_source_content"
        static let version = "about_version"
        static let developer = "about_developer"
        static let developerContent = "about_developer_content"
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let knotList = "nav_knot_list"
        static let knotDetail = "nav_knot_detail"
    }
    
    // MARK: - Launch Screen
    struct Launch {
        static let subtitle = "app_subtitle"
    }
}