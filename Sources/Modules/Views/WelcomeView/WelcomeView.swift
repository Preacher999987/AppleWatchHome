//
//  WelcomeView.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    // TODO: Add Testimonials Carousel later
    private let testimonials = [
        Testimonial(
            text: "I cataloged 200+ Pops in minutes with the bulk photo feature!",
            author: "Sarah K.",
            collectionSize: "1,240 Pops"
        ),
        Testimonial(
            text: "The value tracking helped me insure my rare collection properly.",
            author: "Michael T.",
            collectionSize: "580 Pops"
        ),
        Testimonial(
            text: "Never miss a new release with the series completion alerts!",
            author: "FunkoFan42",
            collectionSize: "3,750 Pops"
        )
    ]
    
    var continueAction: () -> Void
        
        @State private var currentPage = 0
        private let featureCards = [
            FeatureCard(
                icon: "sparkles",
                title: "One Photo. Many Finds.",
                description: "Capture your collection in bunches—Our AI will identify and catalog them all, just like that.",
                color: .blue
            ),
            FeatureCard(
                icon: "dollarsign.arrow.circlepath",
                title: "Earnings tracked ✓ Spending mapped ✓ ROI unlocked ✓",
                description: "Your shelf just became a smart asset.",
                color: .green
            ),
            FeatureCard(
                icon: "app.badge.checkmark",
                title: "Curate Like a Connoisseur",
                description: "Create a sleek digital showcase. Explore, share, and admire—all a tap away.",
                color: .orange
            ),
            FeatureCard(
                icon: "arkit",
                title: "Your smart, virtual collection starts here!",
                description: "Step into the future of collecting, today!",
                color: .purple
            )
        ]
        
        // Consistent horizontal padding for all elements
        private let horizontalPadding: CGFloat = 20
        
        var body: some View {
            ZStack {
                // Dynamic background for dark/light mode
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Welcome Message with same padding
                        VStack(spacing: 16) {
                            Text("Welcome to")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, horizontalPadding)
                                .padding(.top, 40)
                            
                            // App Logo with constrained width
                            Image(colorScheme == .dark ? "logo-white" : "logo-dark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
//                                .frame(height: 80)
                                .padding(.horizontal, horizontalPadding)
//                                .colorInvertIfLight()
                            
                            Text("Unlock the full potential\nof your collection")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, horizontalPadding)
                            Text("A digital twin. A virtual display.\nAlways with you.")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, horizontalPadding)
                        }
                        
                        // Features Carousel with same padding
                        TabView(selection: $currentPage) {
                            ForEach(0..<featureCards.count, id: \.self) { index in
                                FeatureCardView(feature: featureCards[index])
                                    .padding(.horizontal, horizontalPadding)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 220)
//                        .padding(.vertical, 20)
                        
                        // Page Indicators
                        HStack(spacing: 8) {
                            ForEach(0..<featureCards.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.appPrimary : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                    .animation(.spring(), value: currentPage)
                            }
                        }
                        .padding(.bottom, 10)
                        
                        // Action Buttons with same padding
                        VStack(spacing: 12) {
                            Button(action: continueAction) {
                                HStack {
                                    Text("Get Started")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPrimary)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, horizontalPadding)
                            
                            Button(action: continueAction) {
                                Text("Browse Collection")
                                    .font(.headline)
                                    .foregroundColor(.appPrimary)
                            }
                            .padding(.bottom, 20)
                            .padding(.horizontal, horizontalPadding)
                        }
                    }
//                    .padding(.bottom, 40)
                }
            }
        }
    }


// MARK: - Feature Card Models and Views

struct FeatureCard {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct FeatureCardView: View {
    let feature: FeatureCard
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 40))
                .foregroundColor(feature.color)
                .padding()
                .background(feature.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 8) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
