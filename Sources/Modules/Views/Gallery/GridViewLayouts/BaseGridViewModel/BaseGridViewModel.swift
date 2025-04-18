//
//  BaseGridViewModel.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI

// MARK: - ViewModel
import SwiftUI
import Combine

// MARK: - ViewModel
class BaseGridViewModel: GridViewToolbarProtocol {
    private let appState: AppState
    let minColumns = 1
    let maxColumns = UIDevice.isIpad ? 6 : 4
    
    @Published private(set) var items: [Collectible] = []
    
    @Published var filteredItems: [Collectible] = []
    @Binding var isHoneycombGridViewLayoutActive: Bool
    
    @Published var columnCount: Int = AppState.defaultGridViewColumnCount {
        didSet {
            appState.gridViewColumnCount = columnCount
            
            // Ensure column count stays within bounds
            if columnCount < minColumns {
                columnCount = minColumns
            } else if columnCount > maxColumns {
                columnCount = maxColumns
            }
        }
    }
    
    @Published var selectedSortOption: SortOption = .series {
        didSet {
            appState.gridViewSortOption = selectedSortOption
            applySortAndFilter()
        }
    }
    
    @Published var selectedFilter: String? {
        didSet {
            appState.gridViewFilter = selectedFilter
            applySortAndFilter()
        }
    }
    
    @Published var showSections: Bool = false {
        didSet {
            appState.gridViewShowSections = showSections
        }
    }
    
    private var allSubjects: [String] {
        Array(Set(items.map { $0.querySubject }.compactMap{ $0 })).sorted()
    }
    
    init(isHoneycombGridViewLayoutActive: Binding<Bool>, appState: AppState) {
        self._isHoneycombGridViewLayoutActive = isHoneycombGridViewLayoutActive
        self.appState = appState
        
        self.restoreSortAndFilter()
        self.applySortAndFilter()
    }
    
    func onItemsUpdate(_ newItems: [Collectible]) {
        items = newItems
        withAnimation {
            showSections = appState.gridViewShowSections
            applySortAndFilter()
            print("Items updated externally!")
        }
    }

    func toggleHoneycombGridLayout() {
        isHoneycombGridViewLayoutActive.toggle()
        // Add any layout change logic here
    }
    
    func correspondingIndexInItems(for filteredItemIndex: Int) -> Int? {
        let filteredItemId = filteredItems[filteredItemIndex].id
        
        return items.firstIndex(where: { $0.id == filteredItemId })
    }
    
    func sectionHeaderTitle(for item: Collectible, searchResultsMode: Bool) -> String {
        (searchResultsMode ? item.searchQuery : item.querySubject) ?? "Uncategorized"
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
            result = result.filter { $0.querySubject == selectedFilter }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .series:
            result.sort { $0.querySubject ?? "" > $1.querySubject ?? "" }
        case .nameAZ:
            result.sort { $0.attributes.name < $1.attributes.name }
        case .nameZA:
            result.sort { $0.attributes.name > $1.attributes.name }
        case .priceLowHigh:
            result.sort { ($0.estimatedValueFloat ?? 0) < ($1.estimatedValueFloat ?? 0) }
        case .priceHighLow:
            result.sort { ($0.estimatedValueFloat ?? 0) > ($1.estimatedValueFloat ?? 0) }
        case .dateNewest:
            result.sort { dateFromString($0.attributes.dateFrom ?? "") > dateFromString($1.attributes.dateFrom ?? "") }
        case .dateOldest:
            result.sort { dateFromString($0.attributes.dateFrom ?? "") < dateFromString($1.attributes.dateFrom ?? "") }
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
    
    private func dateFromString(_ dateString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        return dateFormatter.date(from: dateString) ?? Date.distantPast
    }
    
    private func restoreSortAndFilter() {
        selectedFilter = appState.gridViewFilter
        selectedSortOption = appState.gridViewSortOption
        columnCount = appState.gridViewColumnCount
        showSections = appState.gridViewShowSections
    }
}
