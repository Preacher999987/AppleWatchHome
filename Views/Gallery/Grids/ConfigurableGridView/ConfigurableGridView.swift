//
//  Item.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//


import SwiftUI

// MARK: - Model
struct Item: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let subject: String
    let dateAdded: Date
    
    static var sampleData: [Item] {
        [
            Item(name: "Apple", price: 1.99, subject: "Fruit", dateAdded: Date().addingTimeInterval(-86400)),
            Item(name: "Banana", price: 0.99, subject: "Fruit", dateAdded: Date().addingTimeInterval(-172800)),
            Item(name: "Orange", price: 2.49, subject: "Fruit", dateAdded: Date().addingTimeInterval(-259200)),
            Item(name: "Milk", price: 3.99, subject: "Dairy", dateAdded: Date().addingTimeInterval(-345600)),
            Item(name: "Bread", price: 2.99, subject: "Bakery", dateAdded: Date().addingTimeInterval(-432000)),
            Item(name: "Eggs", price: 4.49, subject: "Dairy", dateAdded: Date().addingTimeInterval(-518400)),
            Item(name: "Cheese", price: 5.99, subject: "Dairy", dateAdded: Date().addingTimeInterval(-604800)),
            Item(name: "Chicken", price: 7.99, subject: "Meat", dateAdded: Date().addingTimeInterval(-691200)),
            Item(name: "Beef", price: 9.99, subject: "Meat", dateAdded: Date().addingTimeInterval(-777600)),
            Item(name: "Fish", price: 12.99, subject: "Seafood", dateAdded: Date().addingTimeInterval(-864000)),
            Item(name: "Rice", price: 4.99, subject: "Grains", dateAdded: Date().addingTimeInterval(-950400)),
            Item(name: "Pasta", price: 1.49, subject: "Grains", dateAdded: Date().addingTimeInterval(-1036800))
        ]
    }
}

// MARK: - ViewModel
class ConfigurableGridViewModel: ObservableObject {
    @Published var items: [Item]
    @Published var filteredItems: [Item]
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
    
    init(items: [Item] = Item.sampleData) {
        self.items = items
        self.filteredItems = items
        applySortAndFilter()
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
            result.sort { $0.name < $1.name }
        case .nameZA:
            result.sort { $0.name > $1.name }
        case .priceLowHigh:
            result.sort { $0.price < $1.price }
        case .priceHighLow:
            result.sort { $0.price > $1.price }
        case .dateNewest:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .dateOldest:
            result.sort { $0.dateAdded < $1.dateAdded }
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
        let newCount = min(max(count, minColumns), maxColumns)
        if newCount != columnCount {
            columnCount = newCount
        }
    }
}

// MARK: - View
struct ConfigurableGridView: View {
    @StateObject private var viewModel = ConfigurableGridViewModel()
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with filter and sort buttons
            HStack {
                // Column count selection
                Menu {
                    ForEach(2...4, id: \.self) { columns in
                        Button(action: {
                            viewModel.setColumnCount(columns)
                        }) {
                            Text("\(columns) Columns")
                            if viewModel.columnCount == columns {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    Label("Columns", systemImage: "square.grid.2x2")
                }
                
                Spacer()
                
                // Filter button
                Menu {
                    Button("All Subjects") {
                        viewModel.selectedFilter = nil
                    }
                    
                    if viewModel.selectedFilter == nil {
                        Image(systemName: "checkmark")
                    }
                    
                    Divider()
                    
                    ForEach(viewModel.filterOptions(), id: \.self) { subject in
                        Button(subject) {
                            viewModel.selectedFilter = subject
                        }
                        
                        if viewModel.selectedFilter == subject {
                            Image(systemName: "checkmark")
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                
                // Sort button
                Menu {
                    ForEach(viewModel.sortOptions(), id: \.self) { option in
                        Button(option.rawValue) {
                            viewModel.selectedSortOption = option
                        }
                        
                        if viewModel.selectedSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // The grid view
            ScrollView(.vertical) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: viewModel.columnCount), spacing: 16) {
                    ForEach(viewModel.filteredItems) { item in
                        GridItemView(item: item, layout: viewModel.columnCount < 4 ? .regular : .compact)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .scaleEffect(magnifyBy)
            .gesture(
                MagnificationGesture()
                    .updating($magnifyBy) { value, state, _ in
                        state = value
                    }
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { value in
                        if scale < 1 {
                            viewModel.increaseColumns()
                        } else if scale > 1 {
                            viewModel.decreaseColumns()
                        }
                        scale = 1.0
                    }
            )
        }
    }
}

enum GridItemViewLayout {
    case compact, regular
}

// MARK: - Grid Item View
struct GridItemView: View {
    let item: Item
    let layout: GridItemViewLayout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Color(.systemGray5)
                    .aspectRatio(1, contentMode: .fill)
                    .cornerRadius(12)
                
                Text(item.name.prefix(1))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
            
            if layout == .regular {
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(item.subject)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
//            Text(item.dateAdded, style: .date)
//                .font(.caption2)
//                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
struct ConfigurableGridView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurableGridView()
    }
}
