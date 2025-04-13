//
//  PremiumUnlockViewModel.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI

class PremiumUnlockViewModel: ObservableObject {
    @Published var premiumPlans: [PremiumPlan] = []
    @Published var appScreenshots: [AppScreenshot] = []
    @Published var currentScreenshotIndex: Int = 0 {
           didSet {
               // You can add any additional logic when index changes
           }
       }
    @Published var showExitConfirmation = false
    
    struct PremiumPlan: Identifiable {
        let id = UUID()
        let title: String
        let price: String
        let monthlyEquivalent: String
        let savings: String?
        let isMostPopular: Bool
    }
    
    struct AppScreenshot: Identifiable {
        let id = UUID()
        let imageName: String
        let title: String
        let description: String
    }
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Mock premium plans
        premiumPlans = [
            PremiumPlan(
                title: "Annual",
                price: "$23.99",
                monthlyEquivalent: "$2.00/month",
                savings: "Save 33%",
                isMostPopular: true
            ),
            PremiumPlan(
                title: "Semi-annual",
                price: "$13.49",
                monthlyEquivalent: "$2.25/month",
                savings: nil,
                isMostPopular: false
            ),
            PremiumPlan(
                title: "Monthly",
                price: "$2.99",
                monthlyEquivalent: "",
                savings: nil,
                isMostPopular: false
            )
        ]
        
        // Mock app screenshots
        appScreenshots = [
            AppScreenshot(
                imageName: "premium_feature1",
                title: "Unlimited Scanning",
                description: "Scan as many collectibles as you want without restrictions"
            ),
            AppScreenshot(
                imageName: "premium_feature2",
                title: "Collection Analytics",
                description: "Track your collection's growth and value over time"
            ),
            AppScreenshot(
                imageName: "premium_feature3",
                title: "Your Collection, Reimagined",
                description: "Create a sleek digital showcase. Explore, share, and admire—right from your phone"
            ),
            AppScreenshot(
                imageName: "premium_feature4",
                title: "A Digital Twin for Every Piece",
                description: "Cloud-synced and exportable for lifelong safekeeping"
            )
        ]
    }
    
    func startFreeTrial() {
        // In a real app, this would call backend to start trial
        print("Starting 7-day free trial")
    }
}
