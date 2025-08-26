import SwiftUI

struct HelloWorldView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Hello World")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Knots 3D")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("即将推出 iPad 和 macOS 版本")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .background(Color(.systemBackground))
        #else
        .background(Color(.windowBackgroundColor))
        #endif
    }
}