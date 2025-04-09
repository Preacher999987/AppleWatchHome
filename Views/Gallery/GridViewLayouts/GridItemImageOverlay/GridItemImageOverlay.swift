//
//  GridItemOverlay.swift
//  FunKollector
//
//  Created by Home on 08.04.2025.
//

import SwiftUI
// MARK: - Grid Item Image Container Components
    
struct GridItemOverlayDeleteButton: View {
    @Binding var showDeleteConfirmation: Bool
    let onDeleteAction: () -> Void
    let item: Collectible
    
    var body: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.black.opacity(0.8))
                .background(.red)
                .clipShape(Circle())
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .alert(
            "Delete \(item.attributes.name)?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = false
                onDeleteAction()
            }
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
        } message: {
            Text("This will permanently remove the item from your collection.")
        }
    }
}
   
struct GridItemOverlayMissingLabel: View {
    var body: some View {
        Text("MISSING")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(width: .infinity, height: 24)
            .background(.red)
            .cornerRadius(12)
    }
}

struct GridItemOverlayActionButton: View {
    let onViewAction: () -> Void
    let inCollection: Bool
    
    var body: some View {
        Group {
            if !inCollection {
                Button(action: {
                    ViewHelpers.hapticFeedback()
                    onViewAction()
                }) {
                    Text("Shop")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.5))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.appPrimary, lineWidth: 2)
                        )
                }
            } else {
                Button(action: {
                    ViewHelpers.hapticFeedback()
                    onViewAction()
                }) {
                    Text("View")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(.green, lineWidth: 2)
                        )
                }
            }
        }
    }
}
    
struct GridItemOverlaySelectionIndicator: View {
    let isItemSelected: Bool
    let inSelectionMode: Bool
    
    var body: some View {
        Group {
            if inSelectionMode {
                Image(systemName: isItemSelected ? "checkmark.circle" : "circle")
                .symbolEffect(.bounce, value: isItemSelected)
                .font(.system(size: 22))
                .foregroundColor(isItemSelected ? .black : Color(.systemGray3))
                .background(isItemSelected ? Color.appPrimary : .clear)
                .clipShape(Circle())
                .frame(width: 44, height: 44)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
