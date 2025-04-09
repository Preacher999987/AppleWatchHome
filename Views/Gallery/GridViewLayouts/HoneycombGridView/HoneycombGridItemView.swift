//
//  HoneycombGridItemView.swift
//  FunKollector
//
//  Created by Home on 07.04.2025.
//

import SwiftUI

struct HoneycombGridItemView: View {
    let collectible: Collectible
    let isSelected: Bool
    let inSelectionMode: Bool
    let viewModel: GridGalleryViewModel
    let proxy: GeometryProxy
    let index: Int
    let gridItems: [GridItem]
    
    var showAddToCollectionButton: Bool
    var onViewAction: (() -> Void)
    var onDeleteAction: (() -> Void)
    
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
            .overlay(
                GridItemOverlaySelectionIndicator(
                    isItemSelected: viewModel.isItemSelected(collectible.id),
                    inSelectionMode: inSelectionMode)
                .offset(x: offsetX + Self.gridItemSize / 2 - 22, y: Self.gridItemSize / 2 - 22)
            )
            
            if !collectible.inCollection {
                GridItemOverlayMissingLabel()
                .offset(x: offsetX + Self.gridItemSize / 4 - 10, y: -Self.gridItemSize / 2 + 10)
            }
            
            if isSelected {
                GridItemOverlayActionButton(
                    onViewAction: onViewAction,
                    inCollection: collectible.inCollection)
                .offset(x: offsetX, y: 0)
            }
            
            if isSelected && collectible.inCollection && !showAddToCollectionButton {
                GridItemOverlayDeleteButton(
                    showDeleteConfirmation: $showDeleteConfirmation,
                    onDeleteAction: onDeleteAction,
                    item: collectible
                )
                .offset(x: offsetX + Self.gridItemSize / 2 - 10, y: -Self.gridItemSize / 2 + 10)
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
