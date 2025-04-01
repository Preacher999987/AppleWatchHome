//
//  LaunchView.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import SwiftUI
// MARK: - Main App
@main
struct FunkoCollector: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(AppState())
        }
    }
}

struct LaunchView: View {
    @State private var isActive = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if isActive {
                    HomeView()
            } else {
                GIFView(gifName: "animated-logo") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
