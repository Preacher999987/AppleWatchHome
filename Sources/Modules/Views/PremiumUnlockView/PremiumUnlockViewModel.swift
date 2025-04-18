//
//  PremiumUnlockViewModel.swift
//  Fun Kollector
//
//  Created by Home on 01.04.2025.
//

import SwiftUI
import StoreKit
import Combine

@MainActor
class PremiumUnlockViewModel: ObservableObject {
    @Published var appScreenshots: [AppScreenshot] = [
        AppScreenshot(
            imageName: "premium-feature1",
            title: "Unlimited Scanning",
            description: "Scan as many collectibles as you want without restrictions"
        ),
        AppScreenshot(
            imageName: "premium-feature2",
            title: "Collection Analytics",
            description: "Track your collection's growth and value over time"
        ),
        AppScreenshot(
            imageName: "premium-feature3",
            title: "Your Collection, Reimagined",
            description: "Create a sleek digital showcase. Explore, share, and admire—right from your phone"
        ),
        AppScreenshot(
            imageName: "premium-feature4",
            title: "A Digital Twin for Every Piece",
            description: "Cloud-synced and exportable for lifelong safekeeping"
        )
    ]
    
    @Published var showExitConfirmation = false
    @Published var purchaseSuccess = false
    @Published var premiumPlans: [PremiumPlan] = []
    @Published var isLoading = false
    @Published var purchaseError: Error?
    @Published var selectedPlanIndex: Int = 0
    
    private let storeKitService = StoreKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupStoreKitListeners()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    private func setupStoreKitListeners() {
        isLoading = true
        storeKitService.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.updatePremiumPlans(with: products)
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    private func updatePremiumPlans(with products: [Product]) {
        premiumPlans = products.map { product in
            let isAnnual = product.id.contains(".annual")
            let isSemiAnnual = product.id.contains(".semiannual")
            
            return PremiumPlan(
                product: product,
                monthlyEquivalent: calculateMonthlyEquivalent(for: product),
                savings: isAnnual ? "Save 30%" : (isSemiAnnual ? "Save 28%" : nil),
                isMostPopular: isAnnual
            )
        }.sorted {
            // Sort by price (ascending)
            $0.product.price > $1.product.price
        }
    }
    
    private func calculateMonthlyEquivalent(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        
        let price = product.price
        let (value, unit) = (subscription.subscriptionPeriod.value, subscription.subscriptionPeriod.unit)
        
        // Calculate monthly equivalent price
        let monthlyPrice: Decimal
        switch (value, unit) {
        case (1, .month):
            return "" // Already monthly
        case (6, .month): // Semi-annual
            monthlyPrice = price / 6
        case (12, .month), (1, .year): // Annual
            monthlyPrice = price / 12
        default:
            return "" // Unknown interval
        }
        
        // Use the product's native currency formatting
        let formattedPrice = product.priceFormatStyle
            .format(monthlyPrice)
        
        return "\(formattedPrice)/month"
    }
    
    func subscriptionDescription(for planIndex: Int?) -> String? {
        guard let index = planIndex,
              premiumPlans.indices.contains(index) else {
            return nil
        }
        
        let plan = premiumPlans[index]
        let periodString = plan.product.subscription?.subscriptionPeriod.localizedDescription ?? "term"
        return "7 days free, then \(plan.price) per \(periodString)"
    }
    
    func startFreeTrial() {
        guard premiumPlans.indices.contains(selectedPlanIndex) else { return }
        let selectedPlan = premiumPlans[selectedPlanIndex]
        
        Task {
            isLoading = true
            do {
                let success = try await storeKitService.purchase(selectedPlan.product)
                if success {
                    print("Free trial started successfully")
                    purchaseSuccess = true
                }
            } catch {
                purchaseError = error
            }
            isLoading = false
        }
    }
    
    func restorePurchasesButtonTapped() {
        Task {
            do {
                try await storeKitService.restorePurchases()
            } catch {
                purchaseError = error
            }
        }
    }
}

