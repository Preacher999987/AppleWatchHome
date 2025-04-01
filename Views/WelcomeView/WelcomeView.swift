//
//  WelcomeView.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    //TODO: Add Testimonials Carousel later
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
                title: "Smart Scanning",
                description: "Our AI instantly identifies Funko Pops from photos - just snap and catalog!",
                color: .blue
            ),
            FeatureCard(
                icon: "photo.stack",
                title: "Bulk Import",
                description: "Photograph your entire collection at once and we'll add everything automatically",
                color: .green
            ),
            FeatureCard(
                icon: "checklist.unchecked",
                title: "Collection Gaps",
                description: "See which Pops you're missing from your favorite series",
                color: .orange
            ),
            FeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Value Tracking",
                description: "Get real-time estimates of your collection's market value",
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
                            Image("logo-white")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
//                                .frame(height: 80)
                                .padding(.horizontal, horizontalPadding)
                                .colorInvertIfLight()
                            
                            Text("The smart way to catalog and manage your Pop! collection")
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
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.appPrimary)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, horizontalPadding)
                            
                            Button(action: continueAction) {
                                Text("Browse Collection")
                                    .font(.subheadline)
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
