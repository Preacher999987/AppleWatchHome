//
//  LazyGridViewModel.swift
//  FunkoCollector
//
//  Created by Home on 25.03.2025.
//

import SwiftUI
import Foundation

// LazyGridViewModel.swift
class LazyGridViewModel: ObservableObject {
    @Published var showLoadingIndicator = false
    @Published var errorMessage: String?
    
    private let baseUrl = "http://192.168.1.17:3000"
    
    func getGridItemUrl(from item: Collectible) -> URL? {
        let stringUrl = !item.searchImageNoBgUrl.isEmpty
        ? baseUrl + item.searchImageNoBgUrl
        : item.searchImageUrl
        
        return URL(string: stringUrl)
    }
    
    func getRelated(for itemId: String, completion: @escaping ([Collectible]) -> Void) {
        showLoadingIndicator = true
        
        // Validate inputs
        guard let querySubject = try? CollectiblesRepository.item(by: itemId)?.querySubject,
              let encodedQuery = querySubject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            showLoadingIndicator = false
            errorMessage = NetworkError.invalidQuery.userFacingMessage
            return
        }
        
        // Create request
        guard let url = URL(string: "http://192.168.1.17:3000/related/\(encodedQuery)") else {
            showLoadingIndicator = false
            errorMessage = NetworkError.invalidURL.userFacingMessage
            return
        }
        
        var request = URLRequest(url: url)
        
        // Add authorization header
        do {
            try request.addAuthorizationHeader()
        } catch {
            showLoadingIndicator = false
            errorMessage = (error as? AuthError)?.localizedDescription
            return
        }
        
        // Perform network request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.showLoadingIndicator = false
                
                // Handle network errors
                if let error = error {
                    self?.errorMessage = NetworkError.requestFailed(error).userFacingMessage
                    return
                }
                
                // Validate data exists
                guard let data = data else {
                    self?.errorMessage = NetworkError.noData.userFacingMessage
                    return
                }
                
                // Parse response
                do {
                    let items = try JSONDecoder().decode([Collectible].self, from: data)
                    guard !items.isEmpty else {
                        self?.errorMessage = NetworkError.noRelatedPopsFound(querySubject).userFacingMessage
                        return
                    }
                    
                    completion(items) // Return decoded items
                } catch {
                    self?.errorMessage = NetworkError.decodingFailed(error).userFacingMessage
                }
            }
        }.resume()
    }
    
    func getGalleryImages(for id: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        showLoadingIndicator = true
        
        // Construct URL with path parameter
        guard let apiUrl = URL(string: "http://192.168.1.17:3000/gallery/\(id)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -3, userInfo: nil)))
            showLoadingIndicator = false
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Changed to Accept header
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.showLoadingIndicator = false
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: -2, userInfo: nil)))
                return
            }
            
            do {
                // Decode array of ImageData directly
                let images = try JSONDecoder().decode([ImageData].self, from: data)
                completion(.success(images))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func manageCollection(itemIds: [String], method: ManageCollectionMethod, collectible: Collectible? = nil, completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        showLoadingIndicator = true
        
        // Construct the request URL
        guard let url = URL(string: "\(baseUrl)/manage-collection") else {
            showLoadingIndicator = false
            errorMessage = NetworkError.invalidURL.userFacingMessage
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        do {
            try request.addAuthorizationHeader()
        } catch {
            showLoadingIndicator = false
            errorMessage = (error as? AuthError)?.localizedDescription
            completion(.failure(error))
            return
        }
        
        let uid = (try? UserProfileRepository.getCurrentUserProfile()?.uid) ?? ""
        // Prepare request body
        var body: [String: Any] = [
            "method": method.rawValue,
            "itemIds": itemIds,
            "uid": uid
        ]
        if method == .update,
           let itemToUpdate = collectible?.toDictionary() {
            body["itemToUpdate"] = collectible?.toDictionary()
        }
        
        // Add JSON body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            showLoadingIndicator = false
            errorMessage = "Error creating request"
            completion(.failure(error))
            return
        }
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.showLoadingIndicator = false
                
                // Handle errors
                if let error = error {
                    self?.errorMessage = NetworkError.requestFailed(error).userFacingMessage
                    completion(.failure(error))
                    return
                }
                
                // Check for successful response
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self?.errorMessage = NetworkError.serverError.userFacingMessage
                    completion(.failure(NetworkError.serverError))
                    return
                }
                
                // Parse successful response
                completion(.success(true))
            }
        }.resume()
    }
    
    func loadMyCollection() -> [Collectible] {
        (try? CollectiblesRepository.loadItems()) ?? []
    }
    
    func addToCollection(_ items: [Collectible]) {
        // Add all current payload items to Collection
        try? CollectiblesRepository.addItems(items)
    }
    
    func deleteItem(for id: String) {
        try? CollectiblesRepository.deleteItem(for: id)
    }
    
    func updateItem(_ item: Collectible) {
        try? CollectiblesRepository.updateItem(item)
    }
    
    func updateGallery(by itemId: String, galleryImages: [ImageData]) throws {
        try CollectiblesRepository.updateGallery(by: itemId, galleryImages: galleryImages)
        if let itemToUpdate = try? CollectiblesRepository.item(by: itemId) {
            manageCollection(itemIds: [itemId], method: .update, collectible: itemToUpdate) { _ in }
        }
    }
    
    func purchasePriceUpdated(_ price: Float, for item: Collectible) {
        var itemToUpdate = item
        itemToUpdate.pricePaid = price
        
        try? CollectiblesRepository.updateItem(itemToUpdate)
        manageCollection(itemIds: [item.id], method: .update, collectible: itemToUpdate) { _ in }
    }
}
