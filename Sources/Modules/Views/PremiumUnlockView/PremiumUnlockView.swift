//
//  PremiumUnlockViewModel.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

struct PremiumUnlockView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PremiumUnlockViewModel()
    @State private var currentCarouselIndex: Int = 0
    @State private var showCloseButton = false
    // Modal Safari browser view
    @State private var activeDestination: SafariViewDestination?
    
    @EnvironmentObject var appState: AppState
    
    var dismissAction: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if !viewModel.premiumPlans.isEmpty {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        TabView(selection: $currentCarouselIndex) {
                            ForEach(Array(viewModel.appScreenshots.enumerated()), id: \.offset) { index, screenshot in
                                VideoCardView(
                                    videoName: screenshot.imageName,
                                    title: screenshot.title,
                                    description: screenshot.description,
                                    onVideoEnded: {
                                        // Auto-advance to next video when current finishes
                                        withAnimation {
                                            currentCarouselIndex = (currentCarouselIndex + 1) % viewModel.appScreenshots.count
                                        }
                                    }
                                )
                                .tag(index)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .overlay(
                            // Custom indicators at bottom of carousel
                            VStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    ForEach(0..<viewModel.appScreenshots.count, id: \.self) { index in
                                        Capsule()
                                            .fill(index == currentCarouselIndex ? Color.appPrimary : Color.gray.opacity(0.4))
                                            .frame(width: index == currentCarouselIndex ? 20 : 8, height: 8)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentCarouselIndex)
                                    }
                                }
                                .padding(.bottom, 26)
                            }
                        )
                        .frame(maxHeight: .infinity) // Takes all available space
                        
                        // Text elements above plan cards
                        VStack(spacing: 4) {
                            Text(viewModel.appScreenshots.indices.contains(currentCarouselIndex) ?
                                 viewModel.appScreenshots[currentCarouselIndex].title : "UNLOCK PREMIUM FEATURES")
                            .font(.title3)
                            .fontWeight(.bold)
                            
                            Text(viewModel.appScreenshots.indices.contains(currentCarouselIndex) ?
                                 viewModel.appScreenshots[currentCarouselIndex].description : "Discover full functionality with premium")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .lineLimit(2, reservesSpace: true)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        // Plan cards and other content (fixed height)
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                ForEach(Array(viewModel.premiumPlans.enumerated()), id: \.element.id) { index, plan in
                                    PremiumPlanCard(
                                        plan: plan,
                                        isSelected: index == viewModel.selectedPlanIndex
                                    ) {
                                        viewModel.selectedPlanIndex = index
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Safe unwrap for price label
                            if let description = viewModel.subscriptionDescription(for: viewModel.selectedPlanIndex) {
                                Text(description)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                            
                            Button(action: {
                                viewModel.startFreeTrial()
                            }) {
                                HStack(spacing: 8) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "crown.fill")
                                        Text("Start Free Trial")
                                    }
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.appPrimary)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isLoading)
                            .alert("Error", isPresented: .constant(viewModel.purchaseError != nil)) {
                                Button("OK", role: .cancel) {
                                    viewModel.purchaseError = nil
                                }
                            } message: {
                                Text(viewModel.purchaseError?.localizedDescription ?? "Unknown error")
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Footer links
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    Button("Restore Purchases") {
                                        viewModel.restorePurchasesButtonTapped()
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.appPrimary)
                                    
                                    Button("Activate Promocode") {
                                        // Promo code logic
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.appPrimary)
                                    .disabled(true)
                                }
                                
                                HStack(spacing: 16) {
                                    Button("Terms of Use") {
                                        activeDestination = .termsOfUse
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.appPrimary)
                                    
                                    Button("Privacy Policy") {
                                        activeDestination = .privacyPolicy
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.appPrimary)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        
                        //                        .frame(minHeight: 240) // Fixed height for bottom section
                    }
                    .frame(height: geometry.size.height)
                }
            }
            
            // Close button (top-right) - conditionally shown
            if showCloseButton {
                HStack {
                    Spacer()
                    Button(action: {
                        ViewHelpers.hapticFeedback()
                        viewModel.showExitConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(20)
                    }
                }
                .transition(.opacity) // Smooth fade-in animation
            }
            
            // Loading view
            if viewModel.isLoading {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                ProgressView()
                    .scaleEffect(2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if viewModel.showExitConfirmation {
                exitConfirmationPopup
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .sheet(item: $activeDestination) { destination in
            if let url = destination.url {
                SafariView(url: url)
            }
        }
        .onAppear {
            viewModel.selectedPlanIndex = viewModel.premiumPlans.firstIndex(where: { $0.isMostPopular }) ?? 0
            // Show close button after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
        .onChange(of: viewModel.purchaseSuccess) { _, newValue in
            if newValue {
                dismissAction?()
            }
        }
    }

    private var exitConfirmationPopup: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { viewModel.showExitConfirmation = false }
            
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "gift")
                        .font(.largeTitle)
                    Text("Try Premium Free")
                        .font(.title3.weight(.bold))
                    Text("You'll be granted 3-day free access. If you find the app valuable, your subscription will begin automatically. You can cancel anytime before the trial ends to avoid charges.")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                }
                .padding(16)
                .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Button(action: {
                        viewModel.startFreeTrial()
                        viewModel.showExitConfirmation = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                            
                            Text("Start Free Trial")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                    
                    Button("Not Now") {
                        viewModel.showExitConfirmation = false
                        dismissAction?()
                    }
                    //                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                }
                .padding(.bottom, 16)
            }
            .blurredBackgroundRounded()
            .padding(40)
        }
        .zIndex(10)
        .transition(.opacity)
    }
}
