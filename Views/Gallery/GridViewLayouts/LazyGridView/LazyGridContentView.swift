//
//  LazyGridContentView.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//

import SwiftUI

struct LazyGridContentView: View {
    @Binding var payload: [Collectible]
    @Binding var selectedItem: Int?
    @Binding var isFullScreen: Bool
    @Binding var showSafariView: Bool
    @Binding var showAddToCollectionButton: Bool
    
    var onItemTap: (Int) -> Void
    var confirmCollectibleDeletion: (Int) -> Void
    
    var searchResultsSelectionModeOn: Bool
    let gridItems: [GridItem]
    let viewModel: GridGalleryViewModel
    
    private static let gridItemSize: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    private static let spacingBetweenRows: CGFloat = 12
    
    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            LazyVGrid(
                columns: gridItems,
                alignment: .center,
                spacing: Self.spacingBetweenRows
            ) {
                ForEach(payload.indices, id: \.self) { index in
                    gridItem(for: index)
                }
            }
            .padding(.trailing, Self.gridItemSize/2 + 20)
            .padding(.top, Self.gridItemSize/2 + 20)
            .padding(.bottom, Self.gridItemSize/2 + 40)
            .padding(.leading, 20)
        }
        .contentShape(Rectangle())
    }
    
    private func gridItem(for index: Int) -> some View {
        GeometryReader { proxy in
            ZStack {
                // TODO: Safety check: Prevents out-of-bounds crash when:
                // 1. Dismissing this view via Home button (app backgrounding)
                // 2. Returning from search results/gallery view after data changes
                // 3. During async data updates while view is transitioning
                if !payload.indices.contains(index) {
                    EmptyView()
                } else {
                    LazyGridItemView(
                        collectible: payload[index],
                        isSelected: selectedItem == index,
                        inSelectionMode: searchResultsSelectionModeOn,
                        viewModel: viewModel,
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
                        onItemTap(index)
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
    
    private func handleViewAction(for index: Int) {
        withAnimation(.spring()) {
            if payload[index].inCollection {
                selectedItem = index
                isFullScreen = true
            } else {
                showSafariView = true
            }
        }
    }

    private func handleDeleteAction(for index: Int) {
        // Store the index temporarily if needed
        // Then show confirmation or call deletion directly
        confirmCollectibleDeletion(index)
    }

    private func handleItemTap(for index: Int) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if searchResultsSelectionModeOn {
                ViewHelpers.hapticFeedback()
                viewModel.toggleItemSelection(payload[index])
            }
            selectedItem = index
        }
    }
}
