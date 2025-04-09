//
//  Item.swift
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
    var gridItems: [GridItem]
    var parentViewModel: GridGalleryViewModel
    
    @StateObject var viewModel: BaseGridViewModel
    
    // Responsive grid properties
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            gridContentView
            ToolbarView(viewModel: viewModel)
        }
        .onChange(of: items, initial: true) { oldValue, newValue in
            viewModel.onItemsUpdate(newValue)
        }
    }
    
    private var gridContentView: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16),
                                     count: viewModel.columnCount),
                      spacing: 16) {
                ForEach(viewModel.filteredItems.indices, id: \.self) { index in
                    gridItemView(for: index)
                        .transition(.scale.combined(with: .opacity))
                        .aspectRatio(ResponsiveGridViewLayout
                            .layout(for: viewModel.columnCount) == .compact ? 1 : 0.75,
                                     contentMode: .fill) // Make items rectangle
                }
            }
                      .padding(.top, 72)
                      .padding(.bottom, 110)
        }
        .padding(.horizontal, 16)
        //        .scaleEffect(magnifyBy)
        .gesture(magnificationGesture)
    }
    
    private func gridItemView(for index: Int) -> some View {
        ZStack {
            // TODO: Safety check: Prevents out-of-bounds crash when:
            // 1. Dismissing this view via Home button (app backgrounding)
            // 2. Returning from search results/gallery view after data changes
            // 3. During async data updates while view is transitioning
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
                //        .transition(gridItemTransition)
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
    
    //    private var gridItemTransition: AnyTransition {
    //        .asymmetric(
    //            insertion: .scale.combined(with: .opacity),
    //            removal: .scale.combined(with: .opacity).combined(with: .move(edge: .trailing))
    //        )
    //    }
    
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
        // Store the index temporarily if needed
        // Then show confirmation or call deletion directly
        if let correspondingIndex = viewModel.correspondingIndexInItems(for: index) {
            onCollectibleDeletion(correspondingIndex)
        }
//        viewModel.filteredItems.remove(at: index)
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
    
    /// Returns a layout based on the column count (1 to 4).
    static func layout(for columns: Int) -> ResponsiveGridViewLayout {
        switch columns {
        case 1:
            return .extraLarge
        case 2:
            return .large
        case 3:
            return .regular
        case 4:
            return .compact
        default:
            // Fallback to a reasonable default (e.g., regular)
            return .regular
        }
    }
}

// MARK: - Preview
struct ResponsiveGridView_Previews: PreviewProvider {
    static var previews: some View {
        ResponsiveGridView(selectedItem: .constant(nil), isFullScreen: .constant(false), showSafariView: .constant(false), showAddToCollectionButton: .constant(false), items: .constant([Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock()]), onCollectibleDeletion: {_ in}, searchResultsSelectionModeOn: false, gridItems: [], parentViewModel: GridGalleryViewModel(), viewModel: BaseGridViewModel(isHoneycombGridViewLayoutActive: .constant(false), appState: AppState()))
    }
}
