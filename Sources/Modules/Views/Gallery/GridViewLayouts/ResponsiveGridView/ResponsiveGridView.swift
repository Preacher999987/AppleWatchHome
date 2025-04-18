//
//  ResponsiveGridView.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//

import SwiftUI

struct ResponsiveGridView: View {
    // Required bindings and properties
    @Binding var selectedItem: Int?
    @Binding var isFullScreen: Bool
    @Binding var showSafariView: Bool
    @Binding var showAddToCollectionButton: Bool
    @Binding var items: [Collectible]
    var onCollectibleDeletion: (Int) -> Void
    var searchResultsSelectionModeOn: Bool
    var parentViewModel: GridGalleryViewModel
    
    @StateObject var viewModel: BaseGridViewModel
    
    // Responsive grid properties
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = 1.0
    
    // Section related properties
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            gridContentView
            ToolbarView(viewModel: viewModel)
        }
        .onChange(of: items, initial: true) { oldValue, newValue in
            viewModel.onItemsUpdate(newValue)
        }
        .onAppear {
            // Expand all sections when view appears
            expandAllSections()
        }
    }
    
    @ViewBuilder
    private var gridContentView: some View {
        if viewModel.showSections {
            sectionedGridView
        } else {
            plainGridView
        }
    }
    
    private func expandAllSections() {
        expandedSections = Set(groupedItems.keys)
    }
    
    private var plainGridView: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16),
                                     count: viewModel.columnCount),
                      spacing: 16) {
                ForEach(viewModel.filteredItems.indices, id: \.self) { index in
                    gridItemView(for: index)
                        .transition(.scale.combined(with: .opacity))
                        .aspectRatio(ResponsiveGridViewLayout
                            .layout(for: viewModel.columnCount) == .compact ? 1 : 0.75,
                                     contentMode: .fill)
                }
            }
                      .padding(.top, 72)
                      .padding(.bottom, 140)
        }
        .padding(.horizontal, 16)
        .gesture(magnificationGesture)
    }
    
    private var sectionedGridView: some View {
        ScrollView(.vertical) {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                ForEach(groupedItems.keys.sorted(), id: \.self) { section in
                    Section(header: sectionHeader(for: section)) {
                        if expandedSections.contains(section) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16),
                                                     count: viewModel.columnCount),
                                      spacing: 16) {
                                ForEach(groupedItems[section] ?? [], id: \.self) { index in
                                    gridItemView(for: index)
                                        .transition(.scale.combined(with: .opacity))
                                        .aspectRatio(ResponsiveGridViewLayout
                                            .layout(for: viewModel.columnCount) == .compact ? 1 : 0.75,
                                                     contentMode: .fill)
                                }
                            }
                                      .padding(.bottom, 16)
                        }
                    }
                }
            }
            .padding(.top, 72)
            .padding(.bottom, 140)
        }
        .padding(.horizontal, 16)
        .gesture(magnificationGesture)
    }
    
    private func sectionHeader(for section: String) -> some View {
        HStack {
            Text(section)
                .font(.headline)
                .foregroundColor(.appPrimary)
            
            Spacer()
            
            Image(systemName: expandedSections.contains(section) ? "chevron.down" : "chevron.right")
                .foregroundColor(.appPrimary)
        }
        .padding(.vertical, 12) // Reduced vertical padding
        .padding(.horizontal, 12)
        .blurredBackgroundRounded() // Your custom modifier
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                if expandedSections.contains(section) {
                    expandedSections.remove(section)
                } else {
                    expandedSections.insert(section)
                }
            }
        }
    }
    
    private var groupedItems: [String: [Int]] {
        var groups = [String: [Int]]()
        
        for (index, item) in viewModel.filteredItems.enumerated() {
            let section = viewModel.sectionHeaderTitle(for: item, searchResultsMode: showAddToCollectionButton)
            
            if groups[section] == nil {
                groups[section] = []
            }
            groups[section]?.append(index)
        }
        
        return groups
    }
    
    private func gridItemView(for index: Int) -> some View {
        ZStack {
            if !viewModel.filteredItems.indices.contains(index) {
                EmptyView()
            } else {
                ResponsiveGridItemView(
                    layout: ResponsiveGridViewLayout
                        .layout(for: viewModel.columnCount),
                    collectible: viewModel.filteredItems[index],
                    isSelected: selectedItem != nil ? viewModel.items[selectedItem!].id == viewModel.filteredItems[index].id : false,
                    inSelectionMode: searchResultsSelectionModeOn,
                    showAddToCollectionButton: showAddToCollectionButton,
                    viewModel: parentViewModel,
                    index: index,
                    onViewAction: {
                        handleViewAction(for: index)
                    },
                    onDeleteAction: {
                        handleDeleteAction(for: index)
                    }
                )
                .onTapGesture {
                    handleItemTap(for: index)
                }
            }
        }
    }
    
    // MARK: - Gestures and Animations
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value
            }
            .onChanged { value in
                scale = value
            }
            .onEnded { value in
                handleMagnificationEnd(value)
            }
    }
    
    // MARK: - Action Handlers
    
    private func handleViewAction(for index: Int) {
        withAnimation(.spring()) {
            if viewModel.filteredItems[index].inCollection {
                selectedItem = viewModel.correspondingIndexInItems(for: index)
                isFullScreen = true
            } else {
                showSafariView = true
            }
        }
    }
    
    private func handleItemTap(for index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if searchResultsSelectionModeOn {
                ViewHelpers.hapticFeedback()
                parentViewModel.toggleItemSelection(viewModel.filteredItems[index])
            }
            
            selectedItem = viewModel.correspondingIndexInItems(for: index)
        }
    }
    
    private func handleDeleteAction(for index: Int) {
        if let correspondingIndex = viewModel.correspondingIndexInItems(for: index) {
            onCollectibleDeletion(correspondingIndex)
        }
    }
    
    private func handleMagnificationEnd(_ value: CGFloat) {
        if value < 1 {
            viewModel.increaseColumns()
        } else if value > 1 {
            viewModel.decreaseColumns()
        }
        scale = 1.0
    }
}

enum ResponsiveGridViewLayout {
    case compact     // Best for 4 columns (smallest items)
    case regular     // Best for 3 columns (balanced size)
    case large      // Best for 2 columns (bigger items)
    case extraLarge // Best for 1 column (full-width)
    
    static func layout(for columns: Int) -> ResponsiveGridViewLayout {
        var pad = UIDevice.isIpad
        
        switch columns {
        case 1:
            return .extraLarge
        case 2:
            return .large
        case 3:
            return pad ? .large : .regular
        case 4:
            return .compact
        default:
            return .regular
        }
    }
}

// MARK: - Preview
struct ResponsiveGridView_Previews: PreviewProvider {
    static var previews: some View {
        ResponsiveGridView(
            selectedItem: .constant(nil),
            isFullScreen: .constant(false),
            showSafariView: .constant(false),
            showAddToCollectionButton: .constant(false),
            items: .constant([Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock()]),
            onCollectibleDeletion: {_ in},
            searchResultsSelectionModeOn: false,
            parentViewModel: GridGalleryViewModel(),
            viewModel: BaseGridViewModel(isHoneycombGridViewLayoutActive: .constant(false), appState: AppState())
        )
    }
}
