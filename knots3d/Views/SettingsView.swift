import SwiftUI

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
            .navigationBarTitleDisplayMode(.large)
        }
        .actionSheet(isPresented: $showLanguagePicker) {
            languageActionSheet
        }
    }
    
    private var currentLanguageName: String {
        let availableLanguages = languageManager.availableLanguages
        return availableLanguages.first { $0.code == languageManager.currentLanguage }?.name ?? "中文"
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private var languageActionSheet: ActionSheet {
        let buttons = languageManager.availableLanguages.map { language in
            ActionSheet.Button.default(Text(language.name)) {
                languageManager.setLanguage(language.code)
            }
        } + [ActionSheet.Button.cancel()]
        
        return ActionSheet(
            title: Text(LocalizedStrings.Settings.language.localized),
            buttons: buttons
        )
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
