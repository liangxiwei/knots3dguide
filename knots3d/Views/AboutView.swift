import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // App 图标和标题
                VStack(spacing: 16) {
                    // App 图标占位（如果有的话）
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 8) {
                        Text(LocalizedStrings.About.title.localized)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(appVersion)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 应用描述
                AboutSectionView(
                    title: "",
                    content: LocalizedStrings.About.description.localized,
                    icon: "",
                    showIcon: false
                )
                
                // 主要功能
                AboutSectionView(
                    title: LocalizedStrings.About.features.localized,
                    content: LocalizedStrings.About.featuresContent.localized,
                    icon: "star.circle.fill"
                )
                
                // 数据来源
                AboutSectionView(
                    title: LocalizedStrings.About.dataSource.localized,
                    content: LocalizedStrings.About.dataSourceContent.localized,
                    icon: "book.circle.fill"
                )
                
                // 开发团队
                AboutSectionView(
                    title: LocalizedStrings.About.developer.localized,
                    content: LocalizedStrings.About.developerContent.localized,
                    icon: "person.2.circle.fill"
                )
                
                // 版本信息卡片
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        Text(LocalizedStrings.About.version.localized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStrings.Common.version.localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text(LocalizedStrings.Common.buildDate.localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(buildDate)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(LocalizedStrings.About.title.localized)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private var buildDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

struct AboutSectionView: View {
    let title: String
    let content: String
    let icon: String
    let showIcon: Bool
    
    init(title: String, content: String, icon: String, showIcon: Bool = true) {
        self.title = title
        self.content = content
        self.icon = icon
        self.showIcon = showIcon
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !title.isEmpty {
                HStack {
                    if showIcon && !icon.isEmpty {
                        Image(systemName: icon)
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(title.isEmpty ? .primary : .secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}