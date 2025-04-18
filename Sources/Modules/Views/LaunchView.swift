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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .environmentObject(AppState())
                .environmentObject(subscriptionManager)
                .task {
                    await subscriptionManager.checkOnAppLaunch()
                }
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
    @Environment(\.colorScheme) var colorScheme
    @State private var isActive = false
    @State private var showPremiumUnlockView = false
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        Group {
            if isActive {
                if KeychainHelper.hasValidJWTToken || appState.showHomeView {
                    HomeView()
                        .environmentObject(appState)
                        .environmentObject(subscriptionManager)
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
                        PremiumUnlockView {
                            withAnimation {
                                appState.showHomeView = true
                            }
                        }
                        .environmentObject(appState)
                    }
                }
            } else {
                GIFView(gifName: colorScheme == .dark ? "animated-logo-dark" : "animated-logo-light") {
                    isActive = true
                }
            }
        }
    }
}
