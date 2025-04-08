//
//  Item.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//


import SwiftUI

struct ConfigurableGridView: View {
    // Required bindings and properties
    @Binding var selectedItem: Int?
    @Binding var isFullScreen: Bool
    @Binding var showSafariView: Bool
    @Binding var showAddToCollectionButton: Bool
    var onItemTap: (Int) -> Void
    var confirmCollectibleDeletion: (Int) -> Void
    var searchResultsSelectionModeOn: Bool
    var gridItems: [GridItem]
    var parentViewModel: GridGalleryViewModel
    
    @StateObject var viewModel: ConfigurableGridViewModel
    
    // Configurable grid properties
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = 1.0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            gridContentView
            toolbarView
        }
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        Group {
            if viewModel.columnCount > 0 {
                HStack {
                    columnCountMenu
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
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.5))
                                    .shadow(radius: 2)
                            )
                            .clipShape(Circle())
                            .foregroundColor(.appPrimary)
//                            .overlay(
//                                Capsule()
//                                    .stroke(Color.appPrimary, lineWidth: 2)
//                            )
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
                        Image(systemName: "arrow.up.arrow.down")
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(.black.opacity(0.5))
                                    .shadow(radius: 2)
                            )
                            .clipShape(Circle())
                            .foregroundColor(.appPrimary)
                    }
                }
                .padding()
                .padding(.bottom, 40)
                //                .background(Color(.systemBackground))
            }
        }
    }
    
    private var columnCountMenu: some View {
        Menu {
            ForEach(1...4, id: \.self) { columns in
                Button(action: { viewModel.setColumnCount(columns) }) {
                    HStack {
                        Text("\(columns) Columns")
                        if viewModel.columnCount == columns {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName:"square.grid.2x2")
                .padding(8)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.5))
                        .shadow(radius: 2)
                )
                .clipShape(Circle())
                .foregroundColor(.appPrimary)
        }
    }
    
    private var gridContentView: some View {
        //            ScrollView([.vertical]) {
        //                LazyVGrid(
        //                    columns: gridItems,
        //                    alignment: .center,
        //                    spacing: ConfigurableGridViewModel().minColumns == 1 ? 8 : 16
        //                ) {
        //                    ForEach(payload.indices, id: \.self) { index in
        //                        gridItemView(for: index)
        //                    }
        //                }
        //                .gridContentPadding()
        //            }
        
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16),
                                     count: viewModel.columnCount),
                      spacing: 16) {
                ForEach(viewModel.filteredItems.indices, id: \.self) { index in
                    gridItemView(for: index)
                        .transition(.scale.combined(with: .opacity))
                        .aspectRatio(GridItemViewLayout
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
        return ConfigurableGridItemView(
            layout: GridItemViewLayout
                .layout(for: viewModel.columnCount),
            collectible: viewModel.filteredItems[index],
            isSelected: selectedItem == index,
            inSelectionMode: searchResultsSelectionModeOn,
            showAddToCollectionButton: showAddToCollectionButton,
            viewModel: parentViewModel,
            index: index,
            onViewAction: {
                handleViewAction(for: index)
            },
            onDeleteAction: {
                confirmCollectibleDeletion(index)
            }
        )
        .onTapGesture {
            handleItemTap(for: index)
        }
        //        .transition(gridItemTransition)
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
                selectedItem = index
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
            onItemTap(index)
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

enum GridItemViewLayout {
    case compact     // Best for 4 columns (smallest items)
    case regular     // Best for 3 columns (balanced size)
    case large      // Best for 2 columns (bigger items)
    case extraLarge // Best for 1 column (full-width)
    
    /// Returns a layout based on the column count (1 to 4).
    static func layout(for columns: Int) -> GridItemViewLayout {
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
struct ConfigurableGridView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurableGridView(selectedItem: .constant(nil), isFullScreen: .constant(false), showSafariView: .constant(false), showAddToCollectionButton: .constant(false), onItemTap: {_ in}, confirmCollectibleDeletion: {_ in}, searchResultsSelectionModeOn: false, gridItems: [], parentViewModel: GridGalleryViewModel(), viewModel: ConfigurableGridViewModel(items: .constant([Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock(), Collectible.mock()])))
    }
}
