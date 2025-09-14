import SwiftUI
import StoreKit

struct SettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showLanguagePicker = false
    
    var body: some View {
        NavigationView {
            List {
                // 语言设置
                Section {
                    Button(action: {
                        showLanguagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.language.localized)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(currentLanguageName)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    // 应用评分
                    Button(action: {
                        rateApp()
                    }) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.rateApp.localized)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text(LocalizedStrings.SettingsExtended.general.localized)
                }
                
                // 关于信息
                Section {
                    SettingsRowView(
                        title: LocalizedStrings.Settings.appVersion.localized,
                        value: appVersion,
                        icon: "info.circle"
                    )
                    
                    NavigationLink(destination: WebViewPage(
                        url: URL(string: "https://knots3dguide.liangxiwei.com/privacy")!,
                        title: LocalizedStrings.Settings.privacyPolicy.localized
                    )) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.privacyPolicy.localized)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.about.localized)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                           
                        }
                    }
                } header: {
                    Text(LocalizedStrings.SettingsExtended.aboutSection.localized)
                }
                
            }
            .navigationTitle(LocalizedStrings.TabBar.settings.localized)
            .sheet(isPresented: $showLanguagePicker) {
                languagePickerView
            }
        }
    }
    
    private var currentLanguageName: String {
        let availableLanguages = languageManager.availableLanguages
        return availableLanguages.first { $0.code == languageManager.currentLanguage }?.name ?? "中文"
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "\(version)"
    }
    
    private func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private var languagePickerView: some View {
        NavigationView {
            List {
                ForEach(languageManager.availableLanguages, id: \.code) { language in
                    Button(action: {
                        languageManager.setLanguage(language.code)
                        showLanguagePicker = false
                    }) {
                        HStack {
                            Text(language.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if language.code == languageManager.currentLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.body.weight(.medium))
                            }
                        }
                    }
                }
            }
            .navigationTitle(LocalizedStrings.Settings.language.localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStrings.Actions.done.localized) {
                        showLanguagePicker = false
                    }
                }
            }
        }
        .modifier(PresentationDetentsModifier())
    }
}

/// 条件性presentationDetents修饰符
struct PresentationDetentsModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.presentationDetents([.fraction(0.8)])
        } else {
            content
        }
    }
}

/// 设置行视图
struct SettingsRowView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
