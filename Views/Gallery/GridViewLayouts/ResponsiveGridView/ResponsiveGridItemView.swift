//
//  ResponsiveGridItemView.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI

// MARK: - ResponsiveGridItemView
struct ResponsiveGridItemView: View {
    let layout: ResponsiveGridViewLayout
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
        ZStack {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    Spacer().frame(height: 0)
                    imageContainer
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1) // Give higher layout priority
                    itemDetailsView
                }
                .padding(8)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
                .contentShape(Rectangle()) // Maintain consistent tap area
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                if showMissingLabel {
                    GridItemOverlayMissingLabel()
                        .padding(8)
                }
                
                if showDeteleButton {
                    GridItemOverlayDeleteButton(showDeleteConfirmation: $showDeleteConfirmation,
                                             onDeleteAction: onDeleteAction,
                                                item: collectible)
                }
                
                GridItemOverlaySelectionIndicator(
                    isItemSelected: viewModel.isItemSelected(collectible.id),
                    inSelectionMode: inSelectionMode)
            }
            
            if isSelected {
                GridItemOverlayActionButton(onViewAction: onViewAction, inCollection: collectible.inCollection)
            }
        }
    }
    
    private var showMissingLabel: Bool {
        !collectible.inCollection && layout != .compact
    }
    
    private var showDeteleButton: Bool {
        isSelected && collectible.inCollection && !showAddToCollectionButton && layout != .compact
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
        }
    }
    
    private var itemDetailsView: some View {
        Group {
            switch layout {
            case .compact:
                EmptyView()
            case .regular:
                title(collectible.attributes.name)
                    .lineLimit(1)
                valueLabel(collectible.estimatedValueDisplay, layout: layout)
            case .large, .extraLarge:
                title(collectible.attributes.name)
                    .lineLimit(2)
                VStack(alignment: .leading, spacing: 4) {
                    valueLabel(collectible.estimatedValueDisplay, layout: layout)
                    subjectLabel(value: collectible.querySubject)
                }
            }
        }
    }
    
    private func title(_ value: String) -> some View {
        Text(value)
            .font(.headline)
    }
    
    private func valueLabel(_ value: String?, layout: ResponsiveGridViewLayout) -> some View {
        Text("\(layout == .regular ? "" : "Value: ")\(value ?? "N/A")")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private func subjectLabel (value: String?) -> some View {
        Text(value ?? "N/A")
            .font(.subheadline)
            .foregroundColor(.appPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(4)
            .lineLimit(2)
    }
}
