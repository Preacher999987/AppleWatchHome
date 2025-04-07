//
//  LazyGridItemView.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//

import SwiftUI

struct LazyGridItemView: View {
    let collectible: Collectible
    let isSelected: Bool
    let inSelectionMode: Bool
    let viewModel: GridGalleryViewModel
    let proxy: GeometryProxy
    let index: Int
    let gridItems: [GridItem]
    
    var showAddToCollectionButton: Bool
    var onViewAction: (() -> Void)?
    var onDeleteAction: (() -> Void)?
    
    @State private var showDeleteConfirmation = false
    
    private static let gridItemSize: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    
    var body: some View {
        ZStack {
            AsyncImageLoader(
                url: viewModel.getGridItemUrl(from: collectible),
                placeholder: Image(.gridItemPlaceholder),
                grayScale: !collectible.inCollection
            )
            .scaledToFit()
            .cornerRadius(Self.gridItemSize/8)
            .scaleEffect(scale)
            .offset(x: offsetX, y: 0)
            .overlay(selectionIndicator)
            
            if !collectible.inCollection {
                missingLabel
            }
            
            if isSelected {
                actionButton
            }
            
            if isSelected && collectible.inCollection && !showAddToCollectionButton {
                deleteButton
            }
        }
    }
    
    // MARK: - Delete Button Components
    
    private var deleteButton: some View {
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
        .offset(x: offsetX + Self.gridItemSize / 2 - 10, y: -Self.gridItemSize / 2 + 10)
        .alert(
            "Delete \(collectible.attributes.name)?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = false
                onDeleteAction?()
            }
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
        } message: {
            Text("This will permanently remove the item from your collection.")
        }
    }
    
    private var missingLabel: some View {
        Text("MISSING")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .frame(width: .infinity, height: 24)
            .background(.red)
            .cornerRadius(12)
            .offset(x: offsetX + Self.gridItemSize / 4 - 10, y: -Self.gridItemSize / 2 + 10)
    }
    
    private var actionButton: some View {
        Group {
            if !collectible.inCollection {
                Button(action: {
                    ViewHelpers.hapticFeedback()
                    onViewAction?()
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
                    onViewAction?()
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
        .offset(x: offsetX, y: 0)
    }
    
    private var selectionIndicator: some View {
        Group {
            if inSelectionMode {
                Image(systemName: viewModel.isItemSelected(collectible.id) ?
                      "checkmark.circle" : "circle")
                .symbolEffect(.bounce, value: viewModel.isItemSelected(collectible.id))
                .font(.system(size: 22))
                .foregroundColor(viewModel.isItemSelected(collectible.id) ?
                               Color(.black) : Color(.systemGray3))
                .background(viewModel.isItemSelected(collectible.id) ?
                          Color.appPrimary : Color(.clear))
                .clipShape(Circle())
                .frame(width: 44, height: 44)
                .offset(x: offsetX + Self.gridItemSize / 2 - 22, y: Self.gridItemSize / 2 - 22)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var offsetX: CGFloat {
        let rowNumber = index / gridItems.count
        return rowNumber % 2 == 0 ? Self.gridItemSize/2 + Self.spacingBetweenColumns/2 : 0
    }
    
    // This was my hardcoded approach... really bad for the future!
    //    var deviceCornerAngle: CGFloat {
    //        if UIDevice.current.userInterfaceIdiom == .pad {
    //            return (UIDevice.current.orientation == .portrait) ? 55 : 35
    //        } else {
    //            return (UIDevice.current.orientation == .portrait) ? 65 : 25
    //        }
    //    }
    private var scale: CGFloat {
        let rowNumber = index / gridItems.count
        let x = (rowNumber % 2 == 0)
            ? proxy.frame(in: .global).midX + proxy.size.width/2
            : proxy.frame(in: .global).midX
        
        let y = proxy.frame(in: .global).midY
        let maxDistanceToCenter = getDistanceFromEdgeToCenter(x: x, y: y)
        
        let currentPoint = CGPoint(x: x, y: y)
        let distanceFromCurrentPointToCenter = distanceBetweenPoints(p1: center, p2: currentPoint)
        
        let distanceDelta = min(
            abs(distanceFromCurrentPointToCenter - maxDistanceToCenter),
            maxDistanceToCenter * 0.3
        )
        
        let scalingFactor = 3.3
        return distanceDelta/(maxDistanceToCenter) * scalingFactor
    }
    
    private var center: CGPoint {
        CGPoint(
            x: UIScreen.main.bounds.size.width * 0.5,
            y: UIScreen.main.bounds.size.height * 0.5
        )
    }
    
    private func getDistanceFromEdgeToCenter(x: CGFloat, y: CGFloat) -> CGFloat {
        let m = slope(p1: CGPoint(x: x, y: y), p2: center)
        let currentAngle = angle(slope: m)
        
        let edgeSlope = slope(p1: .zero, p2: center)
        let deviceCornerAngle = angle(slope: edgeSlope)
        
        if currentAngle > deviceCornerAngle {
            let yEdge = (y > center.y) ? center.y * 2 : 0
            let xEdge = (yEdge - y)/m + x
            let edgePoint = CGPoint(x: xEdge, y: yEdge)
            
            return distanceBetweenPoints(p1: center, p2: edgePoint)
        } else {
            let xEdge = (x > center.x) ? center.x * 2 : 0
            let yEdge = m * (xEdge - x) + y
            let edgePoint = CGPoint(x: xEdge, y: yEdge)
            
            return distanceBetweenPoints(p1: center, p2: edgePoint)
        }
    }
    
    private func distanceBetweenPoints(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let xDistance = abs(p2.x - p1.x)
        let yDistance = abs(p2.y - p1.y)
        return CGFloat(sqrt(pow(xDistance, 2) + pow(yDistance, 2)))
    }
    
    private func slope(p1: CGPoint, p2: CGPoint) -> CGFloat {
        return (p2.y - p1.y)/(p2.x - p1.x)
    }
    
    private func angle(slope: CGFloat) -> CGFloat {
        return abs(atan(slope) * 180 / .pi)
    }
}
