//
//  CollectibleNetworkDataProvider.swift
//  FunKollector
//
//  Created by Home on 10.04.2025.
//

import Foundation

class CollectibleNetworkDataProvider: CollectibleRemoteDataProvider {
    func fetchCollectibles(for uid: String) async throws -> [Collectible] {
        // Create base URL
        guard var urlComponents = URLComponents(string: "http://192.168.1.17:3000/user-collection") else {
            throw NetworkError.invalidURL
        }
        
        // Add uid query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "uid", value: uid)
        ]
        
        // Create final URL
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // Add authorization header
        do {
            try request.addAuthorizationHeader()
        } catch let error as AuthError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
        
        // Perform network request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status code
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 401, 403:
                    throw AuthError.invalidCredentials
                case 500...599:
                    throw NetworkError.serverError
                case 200...299:
                    break // Success
                default:
                    throw NetworkError.serverError
                }
            }
            
            // Parse response
            do {
                let items = try JSONDecoder().decode([Collectible].self, from: data)
                return items
            } catch {
                throw NetworkError.decodingFailed(error)
            }
            
        } catch let error as AuthError {
            throw error
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    // TODO: -
    //    private let apiClient: APIClientProtocol
    
    //    init(apiClient: APIClientProtocol = APIClient.shared) {
    //        self.apiClient = apiClient
    //    }
    
    //    func fetchCollectibles() async throws -> [Collectible] {
    //        try await refreshCollectibles()
    //    }
    //
    //    func refreshCollectibles() async throws -> [Collectible] {
    //        let response: [Collectible] = try await apiClient.get("/user-collection")
    //        return response
    //    }
}
