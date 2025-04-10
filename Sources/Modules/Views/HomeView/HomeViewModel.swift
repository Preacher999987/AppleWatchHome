//
//  HomeViewModel.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var totalBalance: String = CurrencyFormatUtility.none
    @Published var rateOfReturn: String = "0.0%"
    @Published var lifetimeSpendings: String = CurrencyFormatUtility.none
    @Published var lastMonthSpendings: String = CurrencyFormatUtility.none
    @Published var lifetimeEarnings: String = CurrencyFormatUtility.none
    @Published var lastMonthEarnings: String = CurrencyFormatUtility.none
    @MainActor
    @Published var isLoading = false
    @MainActor
    @Published var errorMessage: String?
    
    private let userRepository: UserProfileRepositoryProtocol
    private let collectibleRepository: CollectibleRepositoryProtocol
    
    init(userRepository: UserProfileRepositoryProtocol = UserProfileRepository(),
         collectibleRepository: CollectibleRepositoryProtocol = CollectibleRepository()) {
        self.userRepository = userRepository
        self.collectibleRepository = collectibleRepository
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func getUserProfile() throws -> UserProfile? {
        try? userRepository.getCurrentUserProfile()
    }
    
    func loadItems() async -> [Collectible]? {
        try? await collectibleRepository.getCollectibles()
    }
    
    @MainActor
    func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        Task { // Create a Task inside the DispatchQueue
            do {
                let collectibles = try await self.collectibleRepository.getCollectibles()
                DispatchQueue.main.async {
                    self.calculateMetrics(from: collectibles)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load collection: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    @MainActor
    private func calculateMetrics(from collectibles: [Collectible]) {
        // Filter out sold items
        let unsoldItems = collectibles.filter { !($0.customAttributes?.sales?.sold ?? false) }
        
        // Calculate total balance (only unsold items)
        let totalValue = unsoldItems
            .compactMap { $0.estimatedValueFloat }
            .reduce(0, +)
        totalBalance = CurrencyFormatUtility.displayPrice(totalValue)
        
        // Calculate lifetime spendings (all pricePaid)
        let lifetimeSpent = collectibles
            .compactMap { $0.customAttributes?.pricePaid }
            .reduce(0, +)
        lifetimeSpendings = CurrencyFormatUtility.displayPrice(lifetimeSpent)
        
        // Calculate last month spendings
        let lastMonthSpent = calculateLastMonthSpendings(from: collectibles)
        lastMonthSpendings = CurrencyFormatUtility.displayPrice(lastMonthSpent)
        
        // Calculate lifetime earnings (sum of all sold prices)
        let lifetimeEarned = collectibles
            .compactMap { $0.customAttributes?.sales?.soldPrice }
            .reduce(0, +)
        lifetimeEarnings = CurrencyFormatUtility.displayPrice(lifetimeEarned)
        
        // Calculate last month earnings
        let lastMonthEarned = calculateLastMonthEarnings(from: collectibles)
        lastMonthEarnings = CurrencyFormatUtility.displayPrice(lastMonthEarned)
        
        // Calculate rate of return
        let rate = calculateRateOfReturn(
            totalValue: totalValue,
            lifetimeSpent: lifetimeSpent,
            lifetimeEarned: lifetimeEarned
        )
        rateOfReturn = formatPercentage(rate)
    }
    
    private func calculateLastMonthSpendings(from collectibles: [Collectible]) -> Float {
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return 0
        }
        
        return collectibles.compactMap { item -> (price: Float, date: Date)? in
            guard let price = item.customAttributes?.pricePaid,
                  let date = item.customAttributes?.purchaseDate else {
                return nil
            }
            return (price, date)
        }
        .filter { $0.date >= thirtyDaysAgo }
        .map { $0.price }
        .reduce(0, +)
    }
    
    private func calculateLastMonthEarnings(from collectibles: [Collectible]) -> Float {
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) else {
            return 0
        }
        
        return collectibles.compactMap { item -> (price: Float, date: Date)? in
            guard let sale = item.customAttributes?.sales,
                  let price = sale.soldPrice,
                  let date = sale.soldDate else {
                return nil
            }
            return (price, date)
        }
        .filter { $0.date >= thirtyDaysAgo }
        .map { $0.price }
        .reduce(0, +)
    }
    
    private func calculateRateOfReturn(totalValue: Float, lifetimeSpent: Float, lifetimeEarned: Float) -> Float {
        let totalGain = totalValue + lifetimeEarned - lifetimeSpent
        guard lifetimeSpent > 0 else { return 0 }
        return (totalGain / lifetimeSpent) * 100
    }
    
    private func formatPercentage(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positivePrefix = value >= 0 ? "+" : ""
        return formatter.string(from: NSNumber(value: value / 100)) ?? "0.0%"
    }
}
