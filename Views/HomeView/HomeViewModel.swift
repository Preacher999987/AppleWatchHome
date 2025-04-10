//
//  HomeViewModel.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//


import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var totalBalance: String = "£0.00"
    @Published var rateOfReturn: String = "0.0%"
    @Published var lifetimeSpendings: String = "£0.00"
    @Published var lastMonthSpendings: String = "£0.00"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    func loadDashboardData() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let collectibles = try CollectiblesRepository.loadItems()
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
    
    private func calculateMetrics(from collectibles: [Collectible]) {
        // Total Balance (sum of estimated values)
        let totalValue = collectibles
            .compactMap { $0.estimatedValueFloat }
            .reduce(0, +)
        totalBalance = formatCurrency(totalValue)
        
        // Lifetime Spendings (sum of all pricePaid)
        let lifetimeSpent = collectibles
            .compactMap { $0.customAttributes?.pricePaid }
            .reduce(0, +)
        lifetimeSpendings = formatCurrency(lifetimeSpent)
        
        // Last Month Spendings
        let lastMonthSpent = calculateLastMonthSpendings(from: collectibles)
        lastMonthSpendings = formatCurrency(lastMonthSpent)
        
        // Rate of Return ((totalValue - lifetimeSpent) / lifetimeSpent) * 100
        let rate = lifetimeSpent > 0 ? ((totalValue - lifetimeSpent) / lifetimeSpent) * 100 : 0
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
    
    private func formatCurrency(_ value: Float) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
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
