//
//  ContentView.swift
//  knots3d
//
//  Created by liangxw on 2025/8/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        NavigationView {
            VStack(spacing: 30) {
                Text("Knots 3D")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                SpriteKitAnimationView(width: 250, height: 250, showControls: true)
                
                Text("SpriteKit 高性能精灵动画")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
        #else
        HelloWorldView()
        #endif
    }
}

#Preview {
    ContentView()
}
