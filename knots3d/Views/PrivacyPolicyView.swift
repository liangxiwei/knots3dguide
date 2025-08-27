import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 数据收集
                PolicySectionView(
                    title: LocalizedStrings.Privacy.dataCollection,
                    content: LocalizedStrings.Privacy.dataCollectionContent,
                    icon: "shield.checkerboard"
                )
                
                // 数据使用
                PolicySectionView(
                    title: LocalizedStrings.Privacy.dataUsage,
                    content: LocalizedStrings.Privacy.dataUsageContent,
                    icon: "network"
                )
                
                // 数据存储
                PolicySectionView(
                    title: LocalizedStrings.Privacy.dataStorage,
                    content: LocalizedStrings.Privacy.dataStorageContent,
                    icon: "externaldrive"
                )
                
                // 联系我们
                PolicySectionView(
                    title: LocalizedStrings.Privacy.contact,
                    content: LocalizedStrings.Privacy.contactContent,
                    icon: "envelope"
                )
                
                Spacer(minLength: 50)
            }
            .padding()
        }
        .navigationTitle(LocalizedStrings.Privacy.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PolicySectionView: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
    }
}