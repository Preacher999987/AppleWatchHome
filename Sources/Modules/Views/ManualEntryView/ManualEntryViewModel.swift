//
//  ManualEntryViewModel.swift
//  FunKollector
//
//  Created by Home on 06.04.2025.
//

import Foundation
import Combine

class ManualEntryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name = ""
    @Published var type = "Funko Pop" // Default value
    @Published var refNumber = ""
    @Published var series = ""
    @Published var barcode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Collectible] = []
    
    // MARK: - Network Service
    private let baseURL = "http://192.168.1.17:3000"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Search Functionality
    func performSearch() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await lookupItem(
                name: name,
                type: type,
                refNumber: refNumber,
                series: series,
                barcode: barcode
            )
            
            DispatchQueue.main.async {
                if results.isEmpty {
                    self.errorMessage = NetworkError.noSearchResults("").userFacingMessage
                } else {
                    self.searchResults = results
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func lookupItem(name: String, type: String, refNumber: String, series: String, barcode: String) async throws -> [Collectible] {
        // Create query parameters
        var components = URLComponents(string: "\(baseURL)/lookup")
        var queryItems = [URLQueryItem]()
        
        if !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        queryItems.append(URLQueryItem(name: "type", value: type))
        if !refNumber.isEmpty {
            queryItems.append(URLQueryItem(name: "ref_number", value: refNumber))
        }
        if !series.isEmpty {
            queryItems.append(URLQueryItem(name: "series", value: series))
        }
        if !barcode.isEmpty {
            queryItems.append(URLQueryItem(name: "upc", value: barcode))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Collectible].self, from: data)
    }
    
    // MARK: - Validation
    var canSearch: Bool {
        !name.isEmpty || !barcode.isEmpty
    }
    
    // MARK: - Reset
    func reset() {
        name = ""
        type = "Funko Pop" // Reset to default
        refNumber = ""
        series = ""
        barcode = ""
        searchResults = []
        errorMessage = nil
    }
}
