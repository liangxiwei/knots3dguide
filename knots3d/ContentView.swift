//
//  ContentView.swift
//  knots3d
//
//  Created by liangxw on 2025/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad && horizontalSizeClass == .regular {
                // iPad界面：使用NavigationSplitView布局
                if #available(iOS 16.0, *) {
                    iPadMainView()
                } else {
                    // iOS 16以下的iPad降级到TabView
                    MainTabView()
                }
            } else {
                // iPhone界面：使用传统TabView
                MainTabView()
            }
        }
    }
}

#Preview("iPhone") {
    ContentView()
}

#Preview("iPad") {
    ContentView()
}
