//
//  AppScreenshot.swift
//  FunKollector
//
//  Created by Home on 17.04.2025.
//

import StoreKit

struct AppScreenshot: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
}

struct PremiumPlan: Identifiable {
    let id = UUID()
    let product: Product // StoreKit product
    let monthlyEquivalent: String
    let savings: String?
    let isMostPopular: Bool
    
    // Computed properties
    var title: String {
        product.displayName
    }
    
    var price: String {
        product.displayPrice
    }
}

enum SubscriptionStatus {
    case unknown
    case active
    case expired
    case neverPurchased
}

extension PremiumPlan {
    static func mock() -> [PremiumPlan] {
        //         Mock premium plans
        return [
//            PremiumPlan(
//                product: Product()),
//                title: "Annual",
//                price: "$23.99",
//                monthlyEquivalent: "$2.00/month",
//                savings: "Save 33%",
//                isMostPopular: true
//            ),
//            PremiumPlan(
//                product: Product(),
//                title: "Semi-annual",
//                price: "$13.49",
//                monthlyEquivalent: "$2.25/month",
//                savings: nil,
//                isMostPopular: false
//            ),
//            PremiumPlan(
//                product: Product(),
//                title: "Monthly",
//                price: "$2.99",
//                monthlyEquivalent: "",
//                savings: nil,
//                isMostPopular: false
//            )
        ]
    }
}

extension Product.SubscriptionPeriod {
    var localizedDescription: String {
        switch self.unit {
        case .day:
            return value == 1 ? "day" : "\(value) days"
        case .week:
            return value == 1 ? "week" : "\(value) weeks"
        case .month:
            return value == 1 ? "month" : "\(value) months"
        case .year:
            return value == 1 ? "year" : "\(value) years"
        @unknown default:
            return "term"
        }
    }
}
