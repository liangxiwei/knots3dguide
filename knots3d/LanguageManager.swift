import SwiftUI
import Foundation

// MARK: - 语言管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String = "zh-Hans"
    private var currentBundle: Bundle?
    
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
        updateCurrentBundle()
    }
    
    func setLanguage(_ language: String) {
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: "AppLanguage")
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        updateCurrentBundle()
    }
    
    private func updateCurrentBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
        } else {
            currentBundle = Bundle.main
        }
    }
    
    func localizedString(for key: String) -> String {
        return currentBundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }
    
    var availableLanguages: [(code: String, name: String)] {
        return [
            ("zh-Hans", "中文"),
            ("en", "English"),
            ("da", "Dansk"),
            ("de", "Deutsch"),
            ("es", "Español"),
            ("fr", "Français"),
            ("it", "Italiano"),
            ("ja", "日本語"),
            ("ko", "한국어"),
            ("nl", "Nederlands"),
            ("no", "Norsk"),
            ("pl", "Polski"),
            ("pt", "Português"),
            ("ru", "Русский"),
            ("sv", "Svenska"),
            ("tr", "Türkçe"),
            ("zh-TW", "繁體中文")
        ]
    }
}

// MARK: - 本地化扩展
extension String {
    /// 获取本地化字符串
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
    
    /// 获取带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = LanguageManager.shared.localizedString(for: self)
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
        static let globalSearch = "search_global_search"
        static let discoverKnots = "search_discover_knots"
        static let searchPlaceholderDesc = "search_placeholder_description"
        static let popularSearch = "search_popular_search"
        static let noResultsFound = "search_no_results_found"
        static let tryOtherKeywords = "search_try_other_keywords"
        static let foundKnots = "search_found_knots"
        static let sortedByRelevance = "search_sorted_by_relevance"
        static let nameMatch = "search_match_name"
        static let aliasMatch = "search_match_alias"
        static let descriptionMatch = "search_match_description"
        static let categoryMatch = "search_match_category"
        static let typeMatch = "search_match_type"
        static let fuzzyMatch = "search_match_fuzzy"
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
    
    // MARK: - Category & Type List
    struct Category {
        static let searchCategories = "category_search_categories"
        static let searchTypes = "category_search_types"
        static let noData = "category_no_data"
    }
    
    // MARK: - Common UI Elements
    struct Common {
        static let loadingFailed = "common_loading_failed"
        static let retry = "common_retry"
        static let showDetails = "common_show_details"
        static let hideDetails = "common_hide_details"
        static let recentSearches = "common_recent_searches"
        static let clear = "common_clear"
        static let searchNotFound = "common_search_not_found"
        static let trySuggestions = "common_try_suggestions"
        static let version = "common_version"
        static let buildDate = "common_build_date"
    }
    
    // MARK: - Knot Detail
    struct KnotDetail {
        static let animationDemo = "knot_detail_animation_demo"
        static let animationLoading = "knot_detail_animation_loading"
        static let noAnimationAvailable = "knot_detail_no_animation_available"
        static let detailedInfo = "knot_detail_detailed_info"
    }
    
    // MARK: - Knot List
    struct KnotList {
        static let noKnots = "knot_list_no_knots"
        static let noKnotsInCategory = "knot_list_no_knots_in_category"
    }
    
    // MARK: - Favorites Extended
    struct FavoritesExtended {
        static let addSomeKnots = "favorites_add_some_knots"
    }
    
    // MARK: - Settings Extended
    struct SettingsExtended {
        static let general = "settings_general"
        static let aboutSection = "settings_about_section"
    }
    
    // MARK: - WebView
    struct WebView {
        static let loading = "webview_loading"
    }
    
    // MARK: - DataManager Errors
    struct DataErrors {
        static let fileNotFound = "data_error_file_not_found"
        static let decodingError = "data_error_decoding"
        static let networkError = "data_error_network"
        static let categoriesLoadFailed = "data_error_categories_load_failed"
        static let knotsLoadFailed = "data_error_knots_load_failed"
        static let dataManagerReleased = "data_error_manager_released"
    }
    
    // MARK: - SearchManager Stats
    struct SearchStats {
        static let noResultsFound = "search_stats_no_results"
        static let resultsFound = "search_stats_results_found"
        static let noResultsForQuery = "search_stats_no_results_for_query"
        static let categoriesFound = "search_stats_categories"
        static let typesFound = "search_stats_types"
        static let knotsFound = "search_stats_knots"
        static let matchType = "search_stats_match_type"
    }
}