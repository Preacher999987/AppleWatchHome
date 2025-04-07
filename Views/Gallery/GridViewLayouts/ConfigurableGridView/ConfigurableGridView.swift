//
//  Item.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//


import SwiftUI

struct ConfigurableGridView: View {
    // Required bindings and properties
    @Binding var payload: [Collectible]
    @Binding var selectedItem: Int?
    @Binding var isFullScreen: Bool
    @Binding var showSafariView: Bool
    @Binding var showAddToCollectionButton: Bool
    var onItemTap: (Int) -> Void
    var confirmCollectibleDeletion: (Int) -> Void
    var searchResultsSelectionModeOn: Bool
    var gridItems: [GridItem]
    var viewModel: GridGalleryViewModel
    
    // Configurable grid properties
    @StateObject var configViewModel: ConfigurableGridViewModel
    
    
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyBy = 1.0
    
    //    var body: some View {
    //        VStack(spacing: 0) {
    //            // Toolbar with filter and sort buttons (optional)
    //            if configViewModel.columnCount > 1 {
    //                HStack {
    //                    // Column count selection
    //                    Menu {
    //                        ForEach(1...4, id: \.self) { columns in
    //                            Button(action: {
    //                                configViewModel.setColumnCount(columns)
    //                            }) {
    //                                Text("\(columns) Columns")
    //                                if configViewModel.columnCount == columns {
    //                                    Image(systemName: "checkmark")
    //                                }
    //                            }
    //                        }
    //                    } label: {
    //                        Label("Layout", systemImage: "square.grid.2x2")
    //                    }
    //
    //                    Spacer()
    //                }
    //                .padding()
    //                .background(Color(.systemBackground))
    //            }
    //
    //            // The main grid content
    //            ScrollView([.horizontal, .vertical], showsIndicators: false) {
    //                LazyVGrid(
    //                    columns: gridItems,
    //                    alignment: .center,
    //                    spacing: ConfigurableGridViewModel().minColumns == 1 ? 8 : 16
    //                ) {
    //                    ForEach(payload.indices, id: \.self) { index in
    //                        GeometryReader { proxy in
    //                            ConfigurableGridItemView(
    //                                collectible: payload[index],
    //                                isSelected: selectedItem == index,
    //                                inSelectionMode: searchResultsSelectionModeOn,
    //                                showAddToCollectionButton: showAddToCollectionButton,
    //                                viewModel: viewModel,
    //                                proxy: proxy,
    //                                index: index,
    //                                gridItems: gridItems,
    //                                onViewAction: {
    //                                    withAnimation(.spring()) {
    //                                        if payload[index].inCollection {
    //                                            selectedItem = index
    //                                            isFullScreen = true
    //                                        } else {
    //                                            showSafariView = true
    //                                        }
    //                                    }
    //                                },
    //                                onDeleteAction: {
    //                                    confirmCollectibleDeletion(index)
    //                                }
    //                            )
    //                            .onTapGesture {
    //                                withAnimation(.easeInOut(duration: 0.15)) {
    //                                    if searchResultsSelectionModeOn {
    //                                        ViewHelpers.hapticFeedback()
    //                                        viewModel.toggleItemSelection(payload[index])
    //                                    }
    //                                    onItemTap(index)
    //                                }
    //                            }
    //                        }
    //                        .frame(height: Self.gridItemSize)
    //                        .transition(.asymmetric(
    //                            insertion: .scale.combined(with: .opacity),
    //                            removal: .scale.combined(with: .opacity).combined(with: .move(edge: .trailing))
    //                        ))
    //                    }
    //                }
    //                .padding(.trailing, Self.gridItemSize/2 + 20)
    //                .padding(.top, Self.gridItemSize/2 + 20)
    //                .padding(.bottom, Self.gridItemSize/2 + 40)
    //                .padding(.leading, 20)
    //            }
    //            .contentShape(Rectangle())
    //            .scaleEffect(magnifyBy)
    //            .gesture(
    //                MagnificationGesture()
    //                    .updating($magnifyBy) { value, state, _ in
    //                        state = value
    //                    }
    //                    .onChanged { value in
    //                        scale = value
    //                    }
    //                    .onEnded { value in
    //                        if scale < 1 {
    //                            configViewModel.increaseColumns()
    //                        } else if scale > 1 {
    //                            configViewModel.decreaseColumns()
    //                        }
    //                        scale = 1.0
    //                    }
    //            )
    //        }
    //    }
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            gridContentView
        }
    }
    
    // MARK: - Subviews
    
    private var toolbarView: some View {
        Group {
            if configViewModel.columnCount > 1 {
                HStack {
                    columnCountMenu
                    Spacer()
                    
                    // Filter button
                    Menu {
                        Button("All Subjects") {
                            configViewModel.selectedFilter = nil
                        }
                        
                        if configViewModel.selectedFilter == nil {
                            Image(systemName: "checkmark")
                        }
                        
                        Divider()
                        
                        ForEach(configViewModel.filterOptions(), id: \.self) { subject in
                            Button(subject) {
                                configViewModel.selectedFilter = subject
                            }
                            
                            if configViewModel.selectedFilter == subject {
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
                        ForEach(configViewModel.sortOptions(), id: \.self) { option in
                            Button(option.rawValue) {
                                configViewModel.selectedSortOption = option
                            }
                            
                            if configViewModel.selectedSortOption == option {
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
                //                .background(Color(.systemBackground))
            }
        }
    }
    
    private var columnCountMenu: some View {
        Menu {
            ForEach(1...4, id: \.self) { columns in
                Button(action: { configViewModel.setColumnCount(columns) }) {
                    HStack {
                        Text("\(columns) Columns")
                        if configViewModel.columnCount == columns {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Layout", systemImage: "square.grid.2x2")
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
                                     count: configViewModel.columnCount),
                      spacing: 16) {
                ForEach(configViewModel.filteredItems.indices, id: \.self) { index in
                    gridItemView(for: index)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            //                      .gridContentPadding()
                      .padding()
        }
        //        .background(Color(.systemGroupedBackground))
        //        .contentShape(Rectangle())
//        .scaleEffect(magnifyBy)
        .gesture(magnificationGesture)
    }
    
    private func gridItemView(for index: Int) -> some View {
        ConfigurableGridItemView(
            layout: configViewModel.columnCount < 4 ? .regular : .compact,
            collectible: configViewModel.filteredItems[index],
            isSelected: selectedItem == index,
            inSelectionMode: searchResultsSelectionModeOn,
            showAddToCollectionButton: showAddToCollectionButton,
            viewModel: viewModel,
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
            if configViewModel.filteredItems[index].inCollection {
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
                viewModel.toggleItemSelection(configViewModel.filteredItems[index])
            }
            onItemTap(index)
        }
    }
    
    private func handleMagnificationEnd(_ value: CGFloat) {
        if value < 1 {
            configViewModel.increaseColumns()
        } else if value > 1 {
            configViewModel.decreaseColumns()
        }
        scale = 1.0
    }
}


enum GridItemViewLayout {
    case compact, regular
}

// MARK: - View Modifiers
//private extension View {
//    func gridContentPadding() -> some View {
//        self.padding(.trailing, ConfigurableContentView.gridItemSize/2 + 20)
//            .padding(.top, ConfigurableContentView.gridItemSize/2 + 20)
//            .padding(.bottom, ConfigurableContentView.gridItemSize/2 + 40)
//            .padding(.leading, 20)
//    }
//}

// MARK: - ConfigurableGridItemView
struct ConfigurableGridItemView: View {
    let layout: GridItemViewLayout
    let collectible: Collectible
    let isSelected: Bool
    let inSelectionMode: Bool
    let showAddToCollectionButton: Bool
    let viewModel: GridGalleryViewModel
    let index: Int
    var onViewAction: () -> Void
    var onDeleteAction: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            imageContainer
            itemDetailsView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var imageContainer: some View {
        ZStack {
            AsyncImageLoader(
                url: viewModel.getGridItemUrl(from: collectible),
                placeholder: Image(.gridItemPlaceholder),
                grayScale: !collectible.inCollection
            )
            .scaledToFit()
            .cornerRadius(12)
            
            if !collectible.inCollection {
                missingLabel
            }
            
            if isSelected {
                actionButton
                
                if collectible.inCollection && !showAddToCollectionButton {
                    deleteButton
                }
            }
        }
    }
    
    private var itemDetailsView: some View {
        Group {
            Text(collectible.attributes.name)
                .font(.headline)
                .lineLimit(1)
            
            if layout == .regular {
                VStack(alignment: .leading, spacing: 4) {
                    if let value = collectible.estimatedValue {
                        Text("Value: \(value)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(collectible.subject)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    private var missingLabel: some View {
        Text("MISSING")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.red)
            .cornerRadius(12)
    }
    
    private var actionButton: some View {
        Button(action: onViewAction) {
            Text(collectible.inCollection ? "View" : "Shop")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(collectible.inCollection ? .green : .appPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(collectible.inCollection ? .green : .appPrimary, lineWidth: 2)
                )
        }
    }
    
    private var deleteButton: some View {
        Button(action: { showDeleteConfirmation = true }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.black.opacity(0.8))
                .background(.red)
                .clipShape(Circle())
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete \(collectible.attributes.name)?"),
                message: Text("This will permanently remove the item from your collection."),
                primaryButton: .destructive(Text("Delete"), action: onDeleteAction),
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Preview
//struct ConfigurableGridView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConfigurableContentView()
//    }
//}
