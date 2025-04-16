//
//  CollectibleNetworkDataProvider.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

class CollectibleNetworkDataProvider: CollectibleRemoteDataProvider {
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    func fetchCollectibles(for uid: String) async throws -> [Collectible] {
        let queryItems = [URLQueryItem(name: "uid", value: uid)]
        return try await apiClient.get(path: .userCollection, queryItems: queryItems)
    }
    
}
