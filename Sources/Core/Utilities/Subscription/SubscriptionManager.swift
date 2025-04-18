//
//  SubscriptionManager.swift
//  FunKollector
//
//  Created by Home on 17.04.2025.
//

import StoreKit
import Combine

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var lastVerifiedDate: Date?
    
    private let storeKitService = StoreKitService.shared
    private var cancellables = Set<AnyCancellable>()
    private var verificationTask: Task<Void, Never>?
    
    init() {
        setupListeners()
        startPeriodicVerification()
    }
    
    deinit {
        verificationTask?.cancel()
    }
    
    // MARK: - Public Interface
    
    func verifySubscriptions() async {
        do {
            let (status, _) = try await storeKitService.checkSubscriptionStatus()
            
            switch status {
            case .active:
                subscriptionStatus = .active
                isPremium = true
            case .expired:
                subscriptionStatus = .expired
                isPremium = false
            case .neverPurchased:
                subscriptionStatus = .neverPurchased
                isPremium = false
            case .unknown:
                isPremium = false
            }
            
            lastVerifiedDate = Date()
        } catch {
            subscriptionStatus = .unknown
            isPremium = false
        }
    }
    
    func checkOnAppLaunch() async {
        // Only verify if last check was more than 1 hour ago
        guard lastVerifiedDate == nil ||
              lastVerifiedDate!.addingTimeInterval(3600) < Date() else {
            return
        }
        await verifySubscriptions()
    }
    
    // MARK: - Private Methods
    
    private func setupListeners() {
        // React to transaction updates
        storeKitService.transactionUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.verifySubscriptions()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicVerification() {
        verificationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(12*60*60)) // Verify every 12 hours
                await verifySubscriptions()
            }
        }
    }
}
