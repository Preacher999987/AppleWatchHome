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
    @Published var isLoading = false
    private let baseUrl = "http://192.168.1.17:3000"
    func getGridItemUrl(from item: Collectible) -> URL? {
        let stringUrl = !item.searchImageNoBgUrl.isEmpty
        ? baseUrl + item.searchImageNoBgUrl
        : item.searchImageUrl
        
        return URL(string: stringUrl)
    }
    
    func getRelated(for itemId: String, completion: @escaping ([Collectible]) -> Void) {
        isLoading = true
        
        guard let relatedSubject = try? CollectiblesRepository.item(by: itemId),
              let encodedQuery = relatedSubject.querySubject?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            isLoading = false
            completion([]) // Return empty array on failure
            return
        }
        
        let url = URL(string: "http://192.168.1.17:3000/related/\(encodedQuery)")!
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            guard let data = data else {
                completion([]) // Return empty array on failure
                return
            }
            
            do {
                let items = try JSONDecoder().decode([Collectible].self, from: data)
                completion(items) // Return decoded items
            } catch {
                completion([]) // Return empty array on failure
            }
        }.resume()
    }
    
    func getGalleryImages(for id: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        isLoading = true
        
        // Construct URL with path parameter
        guard let apiUrl = URL(string: "http://192.168.1.17:3000/gallery/\(id)") else {
            completion(.failure(NSError(domain: "InvalidURL", code: -3, userInfo: nil)))
            isLoading = false
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Changed to Accept header
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
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
}

