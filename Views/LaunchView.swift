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
            LaunchView()
                .environmentObject(AppState())
        }
    }
}

struct LaunchView: View {
    @State private var isActive = false
    @State private var showPremiumUnlockView = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if isActive {
                if KeychainHelper.hasValidToken() {
                    HomeView()
                } else {
                    WelcomeView(continueAction: {
                        withAnimation {
                            showPremiumUnlockView = true
                        }
                    })
                    .presentationDetents([.medium, .large])
                    .fullScreenCover(isPresented: $showPremiumUnlockView) {
                        PremiumUnlockView()
                            .environmentObject(appState)
                    }
                }
            } else {
                GIFView(gifName: "animated-logo") {
                    isActive = true
                }
            }
        }
    }
}
