//
//  StoreKitService.swift
//  FunKollector
//
//  Created by Home on 17.04.2025.
//

import StoreKit
import Combine

@MainActor
class StoreKitService: ObservableObject {
    // Subscription product IDs from App Store Connect
    private let productIDs = [
        "com.swipeless.FunKollector.monthly",
        "com.swipeless.FunKollector.semiannual",
        "com.swipeless.FunKollector.annual"
    ]
    
    static let shared = StoreKitService()
    
    // Publishers
    let transactionUpdates = PassthroughSubject<[StoreKit.Transaction], Never>()
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    
    private var updatesTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTransactionListener()
        setupStatusMonitoring()
        Task { await loadProducts() }
    }
    
    deinit {
        updatesTask?.cancel()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Setup
    private func setupTransactionListener() {
        updatesTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }
    
    private func setupStatusMonitoring() {
        transactionUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    try await self?.checkSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
            try await checkSubscriptionStatus()
            error = nil
        } catch {
            self.error = error
            print("Failed to load products: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    // MARK: - Purchase Handling
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            purchasedProductIDs.insert(transaction.productID)
            return true
            
        case .pending:
            error = PurchaseError.pending
            return false
            
        case .userCancelled:
            error = PurchaseError.cancelled
            return false
            
        @unknown default:
            error = PurchaseError.unknown
            return false
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            try await checkSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
            throw error
        }
    }
    
    // MARK: - Subscription Status
    func checkSubscriptionStatus() async throws -> (status: SubscriptionStatus, product: Product.SubscriptionInfo?) {
            var activeProductInfo: Product.SubscriptionInfo? = nil
            
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.revocationDate == nil {
                        if let expirationDate = transaction.expirationDate {
                            guard expirationDate > Date() else { continue }
                        }
                        
                        // Get the matching product's subscription info
                        if let product = products.first(where: { $0.id == transaction.productID }) {
                            activeProductInfo = product.subscription
                        }
                        return (.active, activeProductInfo)
                    }
                case .unverified:
                    continue
                }
            }
            
            if await hasPreviousPurchase() {
                return (.expired, nil)
            } else {
                return (.neverPurchased, nil)
            }
        }
    
    private func hasPreviousPurchase() async -> Bool {
        for await result in Transaction.all {
            if case .verified = result {
                return true
            }
        }
        return false
    }
    
    // MARK: - Trial Eligibility
    func isEligibleForTrial() async -> Bool {
        guard let product = products.first else { return false }
        return product.subscription?.introductoryOffer != nil
    }
    
    // MARK: - Helpers
    private func handle(transactionResult: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = transactionResult else {
            print("Transaction verification failed")
            return
        }
        print("[StoreKitService]: handle(transactionResult triggered with .verified(\(transaction)). Sending transaction to transactionUpdates")

        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }
        
        transactionUpdates.send([transaction])
        await transaction.finish()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, let error):
            throw error
        }
    }
}

// MARK: - Error Handling
enum PurchaseError: LocalizedError {
    case pending
    case cancelled
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .pending: return "Purchase is pending approval"
        case .cancelled: return "Purchase was cancelled"
        case .unknown: return "Unknown error occurred"
        }
    }
}
