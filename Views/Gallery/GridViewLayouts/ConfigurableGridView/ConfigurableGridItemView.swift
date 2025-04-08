//
//  ConfigurableGridItemView.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI

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
            Spacer()
            imageContainer
                .frame(maxWidth: .infinity)
            itemDetailsView
        }
        .padding(8)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
        .contentShape(Rectangle()) // Maintain consistent tap area
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
                            .font(.subheadline)
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(4)
                            .lineLimit(2)
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
