//
//  ConfigurableGridViewModel.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//


import SwiftUI

// MARK: - ViewModel
class ConfigurableGridViewModel: ObservableObject {
    @Binding var items: [Collectible]
    @Binding var filteredItems: [Collectible]
    @Published private(set) var columnCount: Int = 2 {
            didSet {
                // Ensure column count stays within bounds
                if columnCount < minColumns {
                    columnCount = minColumns
                } else if columnCount > maxColumns {
                    columnCount = maxColumns
                }
            }
        }
    
    @Published var selectedSortOption: SortOption = .nameAZ {
        didSet {
            applySortAndFilter()
        }
    }
    
    @Published var selectedFilter: String? {
        didSet {
            applySortAndFilter()
        }
    }
    
    let minColumns = 1
    let maxColumns = 4
    
    private var allSubjects: [String] {
        Array(Set(items.map { $0.subject })).sorted()
    }
    
    enum SortOption: String, CaseIterable {
        case nameAZ = "Name (A-Z)"
        case nameZA = "Name (Z-A)"
        case priceLowHigh = "Price (Low to High)"
        case priceHighLow = "Price (High to Low)"
        case dateNewest = "Added (Newest)"
        case dateOldest = "Added (Oldest)"
    }
    
    init(items: Binding<[Collectible]>) {
        self._items = items
        self._filteredItems = items
        self.applySortAndFilter()
    }
    
    func increaseColumns() {
        withAnimation(.spring()) {
            columnCount = min(columnCount + 1, maxColumns)
        }
    }
    
    func decreaseColumns() {
        withAnimation(.spring()) {
            columnCount = max(columnCount - 1, minColumns)
        }
    }
    
    func applySortAndFilter() {
        var result = items
        
        // Apply filter if selected
        if let selectedFilter = selectedFilter {
            result = result.filter { $0.subject == selectedFilter }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .nameAZ:
            result.sort { $0.attributes.name < $1.attributes.name }
        case .nameZA:
            result.sort { $0.attributes.name > $1.attributes.name }
        case .priceLowHigh:
            result.sort { Int($0.estimatedValueDisplay ?? "") ?? 0 < Int($1.estimatedValueDisplay ?? "") ?? 0 }
        case .priceHighLow:
            result.sort { Int($0.estimatedValueDisplay ?? "") ?? 0 > Int($1.estimatedValueDisplay ?? "") ?? 0 }
        case .dateNewest:
            // TODO: Fix to dateFrom
            result.sort { $0.attributes.dateFrom ?? "" > $1.attributes.dateFrom ?? "" }
        case .dateOldest:
            result.sort { $0.attributes.dateFrom ?? "" < $1.attributes.dateFrom ?? "" }
        }
        
        filteredItems = result
    }
    
    func filterOptions() -> [String] {
        allSubjects
    }
    
    func sortOptions() -> [SortOption] {
        SortOption.allCases
    }
    
    func setColumnCount(_ count: Int) {
        withAnimation(.spring()) {
            let newCount = min(max(count, minColumns), maxColumns)
            if newCount != columnCount {
                columnCount = newCount
            }
        }
    }
}
