//
//  PremiumPlanCard.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

struct FeatureCarouselCard: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: .infinity)
                .cornerRadius(12)
                .shadow(radius: 4)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

struct PremiumPlanCard: View {
    let plan: PremiumPlan
    let isSelected: Bool
    let action: () -> Void
    
    // Constants for consistent sizing
    private let cardHeight: CGFloat = 140
    private let badgeHeight: CGFloat = 24
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 0) {
                // Top section (savings or empty space)
                Group {
                    if let savings = plan.savings {
                        Text(savings)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(height: badgeHeight)
                            .background(Color.appPrimary)
                            .cornerRadius(4)
                    } else {
                        Spacer()
                            .frame(height: badgeHeight)
                    }
                }
                .padding(.top, 12)
                
                // Plan type label
                Text(plan.title.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                // Main price
                Text(plan.price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                
                // Monthly equivalent
                if !plan.monthlyEquivalent.isEmpty {
                    Text(plan.monthlyEquivalent)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    Spacer()
                        .frame(height: 20) // Maintain spacing when empty
                }
                
                // Most popular badge
                Group {
                    if plan.isMostPopular {
                        Text("MOST POPULAR")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(4)
                    } else {
                        Spacer()
                    }
                }
                .frame(height: 20)
                .padding(.bottom, 12)
                
                Spacer() // Push all content up
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight) // Fixed height for all cards
            .background(isSelected ? Color.appPrimary.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appPrimary : Color.gray.opacity(0.2), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}
