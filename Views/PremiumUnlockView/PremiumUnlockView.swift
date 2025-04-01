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
    @State private var selectedPlanIndex: Int = 0
    @State private var currentCarouselIndex: Int = 0
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button (top-right)
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.showExitConfirmation = true
                    }) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(20)
                    }
                }
                
                // Carousel takes remaining space after other content
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Carousel with dynamic height
                        TabView(selection: $currentCarouselIndex) {
                            ForEach(Array(viewModel.appScreenshots.enumerated()), id: \.offset) { index, screenshot in
                                FeatureCarouselCard(
                                    imageName: screenshot.imageName,
                                    title: screenshot.title,
                                    description: screenshot.description
                                )
                                .tag(index)
                                .padding(.horizontal, 20)
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
                                .padding(.bottom, 8)
                            }
                        )
                        .frame(maxHeight: .infinity) // Takes all available space
                        
                        // Text elements above plan cards
                        VStack(spacing: 4) {
                            Text("UNLOCK PREMIUM FEATURES")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Discover full functionality with premium")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        
                        // Plan cards and other content (fixed height)
                        VStack(spacing: 12) {
//                            Text("CHOOSE YOUR PLAN")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(Array(viewModel.premiumPlans.enumerated()), id: \.element.id) { index, plan in
                                    PremiumPlanCard(
                                        plan: plan,
                                        isSelected: index == selectedPlanIndex
                                    ) {
                                        selectedPlanIndex = index
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            Text("7 days free, then \(viewModel.premiumPlans[selectedPlanIndex].price) per year")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            
                            Button(action: {
                                // Handle trial subscription
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "crown.fill")
                                        .font(.subheadline)
                                    
                                    Text("Start Trial")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.appPrimary)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            // Footer links
                            VStack(spacing: 12) {
                                HStack(spacing: 16) {
                                    Button("Restore Purchases") {
                                        // Restore logic
                                    }
                                    .font(.caption2)
                                    
                                    Button("Activate Promocode") {
                                        // Promo code logic
                                    }
                                    .font(.caption2)
                                }
                                
                                HStack(spacing: 16) {
                                    Button("Terms & Conditions") {
                                        // Show terms
                                    }
                                    .font(.caption2)
                                    
                                    Button("Privacy Policy") {
                                        // Show privacy policy
                                    }
                                    .font(.caption2)
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
            
            if viewModel.showExitConfirmation {
                exitConfirmationPopup
            }
        }
        .onAppear {
            selectedPlanIndex = viewModel.premiumPlans.firstIndex(where: { $0.isMostPopular }) ?? 0
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
                    Text("You'll be granted 7-day free access. After the trial period, you can subscribe if you enjoy using the app.")
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
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                            
                            Text("Start Trial")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appPrimary)
                    
                    Button("Not Now") {
                        viewModel.showExitConfirmation = false
                        dismiss()
                    }
//                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                }
                .padding(.bottom, 16)
            }
            .background(
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                    Color.black.opacity(0.2)
                }
                    .cornerRadius(20)
            )
            .padding(40)
        }
        .zIndex(10)
        .transition(.opacity)
    }
}
