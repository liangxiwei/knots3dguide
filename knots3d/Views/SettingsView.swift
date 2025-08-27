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
                            
                            Text(LocalizedStrings.Settings.language)
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
                    Text("通用")
                }
                
                // 关于信息
                Section {
                    SettingsRowView(
                        title: LocalizedStrings.Settings.appVersion,
                        value: appVersion,
                        icon: "info.circle"
                    )
                    
                    Button(action: {
                        // TODO: 实现隐私协议页面
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.privacyPolicy)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: {
                        // TODO: 实现关于页面
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(LocalizedStrings.Settings.about)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("关于")
                }
                
                // 开发者测试功能（仅Debug模式显示）
                #if DEBUG
                Section {
                    NavigationLink(destination: DataTestView()) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("数据加载测试")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink(destination: DataValidationView()) {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            Text("数据完整性验证")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("开发者工具")
                }
                #endif
            }
            .navigationTitle(LocalizedStrings.TabBar.settings)
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
            title: Text(LocalizedStrings.Settings.language),
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