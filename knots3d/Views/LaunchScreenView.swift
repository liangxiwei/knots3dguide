import SwiftUI

/// Launch Screen视图 - 应用启动时显示的界面
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            // 背景色
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App图标
                ZStack {
                    // 背景圆圈
                    Circle()
                        .fill(Color.white)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // 绳结图标
                    Image(systemName: "link")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // App名称
                VStack(spacing: 6) {
                    Text("Knots 3D Guide")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("学习绳结的最佳伙伴")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}