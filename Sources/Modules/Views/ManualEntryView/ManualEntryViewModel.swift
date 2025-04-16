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
    @Published var type = "Funko Pop"
    @Published var refNumber = ""
    @Published var series = ""
    @Published var barcode = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Collectible] = []
    
    // MARK: - Dependencies
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Search Functionality
    func performSearch() async {
        guard canSearch else { return }
        
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
            
            await MainActor.run {
                searchResults = results
                if results.isEmpty {
                    errorMessage = NetworkError.noSearchResults("").userFacingMessage
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func lookupItem(
        name: String,
        type: String,
        refNumber: String,
        series: String,
        barcode: String
    ) async throws -> [Collectible] {
        var queryItems = [
            URLQueryItem(name: "type", value: type)
        ]
        
        if !name.isEmpty {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        if !refNumber.isEmpty {
            queryItems.append(URLQueryItem(name: "ref_number", value: refNumber))
        }
        if !series.isEmpty {
            queryItems.append(URLQueryItem(name: "series", value: series))
        }
        if !barcode.isEmpty {
            queryItems.append(URLQueryItem(name: "upc", value: barcode))
        }
        
        return try await apiClient.get(
            path: .lookup,
            queryItems: queryItems
        )
    }
    
    // MARK: - Validation
    var canSearch: Bool {
        !name.isEmpty || !barcode.isEmpty
    }
    
    // MARK: - Reset
    func reset() {
        name = ""
        type = "Funko Pop"
        refNumber = ""
        series = ""
        barcode = ""
        searchResults = []
        errorMessage = nil
    }
}
