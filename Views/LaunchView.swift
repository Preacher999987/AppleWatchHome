//
//  LaunchView.swift
//  Fun Kollector
//
//  Created by Home on 29.03.2025.
//

import SwiftUI
import GoogleSignIn

// MARK: - Main App
@main
struct FunkoCollector: App {
    @StateObject private var navCoordinator = NavigationCoordinator()
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(AppState())
                .onOpenURL { url in
                          GIDSignIn.sharedInstance.handle(url)
                        }
                .onAppear {
                          GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                              // Check if `user` exists; otherwise, do something with `error`
                          }
                    
                    UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self])
                        .tintColor = UIColor(Color.appPrimary)
                    
                }
        }
        .environmentObject(navCoordinator)
    }
}

struct LaunchView: View {
    @State private var isActive = true
    @State private var showPremiumUnlockView = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if isActive {
                if KeychainHelper.hasValidJWTToken || appState.showHomeView {
                    HomeView()
                        .environmentObject(appState)
                        .sheet(isPresented: $appState.showAuthView) {
                            AuthView()
                                .environmentObject(appState)
                        }
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
