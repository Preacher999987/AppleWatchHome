//
//  HoneycombGridView.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//

import SwiftUI

struct HoneycombGridView: View {
    private static let gridItemSize: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    private static let spacingBetweenRows: CGFloat = 12
    private static let totalColumns: Int = 4
    
    let gridItems = Array(
        repeating: GridItem(
            .fixed(gridItemSize),
            spacing: spacingBetweenColumns,
            alignment: .center
        ),
        count: totalColumns
    )
    
    @Binding var selectedItem: Int?
    @Binding var isFullScreen: Bool
    @Binding var showSafariView: Bool
    @Binding var showAddToCollectionButton: Bool
    @Binding var items: [Collectible]
    
    var onCollectibleDeletion: (Int) -> Void
    
    var searchResultsSelectionModeOn: Bool
    
    let parentViewModel: GridGalleryViewModel
    
    @StateObject var viewModel: BaseGridViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                LazyVGrid(
                    columns: gridItems,
                    alignment: .center,
                    spacing: Self.spacingBetweenRows
                ) {
                    ForEach(viewModel.filteredItems.indices, id: \.self) { index in
                        gridItemView(for: index)
                    }
                }
                .padding(.trailing, Self.gridItemSize/2 + 20)
                .padding(.top, Self.gridItemSize/2 + 20)
                .padding(.bottom, Self.gridItemSize/2 + 40)
                .padding(.leading, 20)
            }
            .contentShape(Rectangle())
            
            ToolbarView(viewModel: viewModel, columnLayoutActive: false)
        }
        .onChange(of: items, initial: true) { oldValue, newValue in
            viewModel.onItemsUpdate(newValue)
        }
    }
    
    private func gridItemView(for index: Int) -> some View {
        GeometryReader { proxy in
            ZStack {
                // TODO: Safety check: Prevents out-of-bounds crash when:
                // 1. Dismissing this view via Home button (app backgrounding)
                // 2. Returning from search results/gallery view after data changes
                // 3. During async data updates while view is transitioning
                if !viewModel.filteredItems.indices.contains(index) {
                    EmptyView()
                } else {
                    HoneycombGridItemView(
                        collectible: viewModel.filteredItems[index],
                        isSelected: selectedItem != nil ? viewModel.items[selectedItem!].id == viewModel.filteredItems[index].id : false,
                        inSelectionMode: searchResultsSelectionModeOn,
                        viewModel: parentViewModel,
                        proxy: proxy,
                        index: index,
                        gridItems: gridItems,
                        showAddToCollectionButton: showAddToCollectionButton,
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
        .frame(height: Self.gridItemSize)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity).combined(with: .move(edge: .trailing))
        ))
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
}
