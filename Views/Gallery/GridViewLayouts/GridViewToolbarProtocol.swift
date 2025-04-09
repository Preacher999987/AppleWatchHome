//
//  GridViewToolbarProtocol.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI

protocol GridViewToolbarProtocol: ObservableObject {
    var columnCount: Int { get set }
    var isHoneycombGridViewLayoutActive: Bool { get set }
    var selectedFilter: String? { get set }
    var selectedSortOption: SortOption { get set }
    
    func setColumnCount(_ columns: Int)
    func toggleHoneycombGridLayout()
    func filterOptions() -> [String]
    func sortOptions() -> [SortOption]
    
    // Add any other required properties/methods
}

enum SortOption: String, CaseIterable {
    case series = "Series (A-Z)"
    case nameAZ = "Name (A-Z)"
    case nameZA = "Name (Z-A)"
    case priceLowHigh = "Price (Low to High)"
    case priceHighLow = "Price (High to Low)"
    case dateNewest = "Added (Newest)"
    case dateOldest = "Added (Oldest)"
}
