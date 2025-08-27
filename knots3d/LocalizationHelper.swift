import Foundation
import SwiftUI

// MARK: - Localization Helper

extension String {
    /// 获取本地化字符串
    var localized: String {
        return LocalizationHelper.localizedString(for: self)
    }
    
    /// 获取带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        let localizedString = LocalizationHelper.localizedString(for: self)
        return String(format: localizedString, arguments: arguments)
    }
}

// MARK: - Localization Helper

class LocalizationHelper {
    private static var currentBundle: Bundle?
    
    /// 获取本地化字符串
    static func localizedString(for key: String) -> String {
        let bundle = getCurrentBundle()
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
    
    /// 获取当前语言的Bundle
    private static func getCurrentBundle() -> Bundle {
        if let cachedBundle = currentBundle {
            return cachedBundle
        }
        
        let language = LanguageManager.shared.currentLanguage
        
        // 首先尝试从locale目录加载
        if let path = Bundle.main.path(forResource: language, ofType: "lproj", inDirectory: "Resources/locale"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            return bundle
        }
        
        // 备用：从主Bundle加载
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            currentBundle = bundle
            return bundle
        }
        
        // 默认返回主Bundle
        return Bundle.main
    }
    
    /// 重置缓存的Bundle（语言切换时调用）
    static func resetBundle() {
        currentBundle = nil
    }
}

// MARK: - Localized Strings

struct LocalizedStrings {
    
    // MARK: - Tab Bar
    struct TabBar {
        static let categories = "tab_categories".localized
        static let types = "tab_types".localized
        static let favorites = "tab_favorites".localized
        static let settings = "tab_settings".localized
    }
    
    // MARK: - Common Actions
    struct Actions {
        static let search = "action_search".localized
        static let cancel = "action_cancel".localized
        static let ok = "action_ok".localized
        static let save = "action_save".localized
        static let back = "action_back".localized
        static let done = "action_done".localized
    }
    
    // MARK: - Search
    struct Search {
        static let placeholder = "search_placeholder".localized
        static let noResults = "search_no_results".localized
        static func resultsCount(_ count: Int) -> String {
            return "search_results_count".localized(with: count)
        }
    }
    
    // MARK: - Knot Detail
    struct Detail {
        static let usage = "detail_usage".localized
        static let history = "detail_history".localized
        static let structure = "detail_structure".localized
        static let strengthReliability = "detail_strength_reliability".localized
        static let abokNumber = "detail_abok_number".localized
        static let notes = "detail_notes".localized
        static let relatedKnots = "detail_related_knots".localized
        static let classification = "detail_classification".localized
        static let type = "detail_type".localized
        static let foundIn = "detail_found_in".localized
    }
    
    // MARK: - Animation Controls
    struct Controls {
        static let play = "control_play".localized
        static let pause = "control_pause".localized
        static let stop = "control_stop".localized
        static let mirror = "control_mirror".localized
        static let mode360 = "control_360_mode".localized
        static let saveFrame = "control_save_frame".localized
    }
    
    // MARK: - Favorites
    struct Favorites {
        static let empty = "favorites_empty".localized
        static let add = "favorites_add".localized
        static let remove = "favorites_remove".localized
        static let added = "favorites_added".localized
        static let removed = "favorites_removed".localized
    }
    
    // MARK: - Settings
    struct Settings {
        static let language = "settings_language".localized
        static let languageChinese = "settings_language_chinese".localized
        static let languageEnglish = "settings_language_english".localized
        static let privacyPolicy = "settings_privacy_policy".localized
        static let versionInfo = "settings_version_info".localized
        static let about = "settings_about".localized
        static let appVersion = "settings_app_version".localized
    }
    
    // MARK: - Alerts
    struct Alerts {
        static let error = "alert_error".localized
        static let success = "alert_success".localized
        static let confirm = "alert_confirm".localized
    }
    
    // MARK: - Loading States
    struct Loading {
        static let knots = "loading_knots".localized
        static let animation = "loading_animation".localized
    }
    
    // MARK: - Error Messages
    struct Errors {
        static let loadData = "error_load_data".localized
        static let animationLoad = "error_animation_load".localized
        static let network = "error_network".localized
    }
    
    // MARK: - Navigation
    struct Navigation {
        static let knotList = "nav_knot_list".localized
        static let knotDetail = "nav_knot_detail".localized
    }
}

// MARK: - Language Manager

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
        
        // 重置本地化Bundle缓存
        LocalizationHelper.resetBundle()
        
        // 更新应用语言（需要重启应用才能完全生效）
        UserDefaults.standard.set([language], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    var availableLanguages: [(code: String, name: String)] {
        return [
            ("zh-Hans", LocalizedStrings.Settings.languageChinese),
            ("en", LocalizedStrings.Settings.languageEnglish)
        ]
    }
}