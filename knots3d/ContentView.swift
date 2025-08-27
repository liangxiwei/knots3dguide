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
        MainTabView()
        #else
        HelloWorldView()  // iPad和macOS暂时显示HelloWorld
        #endif
    }
}

#Preview {
    ContentView()
}
