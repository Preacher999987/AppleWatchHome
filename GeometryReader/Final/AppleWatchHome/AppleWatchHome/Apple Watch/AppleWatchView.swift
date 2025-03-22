//
//  ContentView.swift
//  AppleWatchHome
//
//  Created by Pedro Rojas on 29/09/21.
//

import SwiftUI
import CoreML
import Vision

struct AppleWatchView: View {
    @Namespace private var animationNamespace // For matchedGeometryEffect
    @State private var selectedItem: Int? = nil // Track the selected grid item
    @State private var isFullScreen: Bool = false // Track full-screen state
    @State private var items: [Int] = Array(0..<12) // Track grid items
    @State private var nextItemId: Int = 12 // Track the next item ID
    
    private static let size: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    private static let spacingBetweenRows: CGFloat = 12
    private static let totalColumns: Int = 4

    var gridItems = Array(
        repeating: GridItem(
            .fixed(size),
            spacing: spacingBetweenColumns,
            alignment: .center
        ),
        count: totalColumns
    )

    var body: some View {
        // Full Screen View
        if !isFullScreen {
//        if true {
            ZStack {
                // Background Image
                Image("background-image-1") // Replace with your image name
                    .resizable() // Make the image resizable
                    .scaledToFill() // Fill the entire screen
                    .edgesIgnoringSafeArea([.all]) // Ignore safe area to cover the whole screen
                //            Color.black
                //                .edgesIgnoringSafeArea([.all])
                //            Axes()
                //                .edgesIgnoringSafeArea([.all])
                
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    LazyVGrid(
                        columns: gridItems,
                        alignment: .center,
                        spacing: Self.spacingBetweenRows
                    ) {
                        ForEach(items, id: \.self) { value in
                            GeometryReader { proxy in
                                ZStack { // Use ZStack to overlay the button on the image
                                    // Image
                                    Image(appName(value))
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(Self.size/8)
                                        .scaleEffect(
                                            scale(
                                                proxy: proxy,
                                                value: value
                                            )
                                        )
                                        .offset(
                                            x: offsetX(value),
                                            y: 0
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedItem = value
                                            }
                                        }
                                    // "Add" Button
                                    if selectedItem == value {
                                        if value < 9 {
                                            Button(action: {
                                                // Action for the button
                                                // Trigger full-screen animation
                                                withAnimation(.spring()) {
                                                    selectedItem = value
                                                    isFullScreen = true
                                                }
                                                
                                                print("Add button tapped for item \(value)")
                                            }) {
                                                Text("SHOP")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: Self.size / 2, height: 30) // Half width of grid item
                                                    .background(Color.blue).opacity(0.8)
                                                    .cornerRadius(15) // Rounded corners
                                            }
                                            .offset(
                                                x: offsetX(value),
                                                y: 0
                                            )
                                        } else {
                                            Button(action: {
                                                // Action for the button
                                                // Trigger full-screen animation
                                                withAnimation(.spring()) {
                                                    selectedItem = value
                                                    isFullScreen = true
                                                }
                                                
                                                print("Add button tapped for item \(value)")
                                            }) {
                                                Text("VIEW")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: Self.size / 2, height: 30) // Half width of grid item
                                                    .background(Color.green).opacity(0.8)
                                                    .cornerRadius(15) // Rounded corners
                                            }
                                            .offset(
                                                x: offsetX(value),
                                                y: 0
                                            )
                                        }
                                        // Round Remove Button
                                        Button(action: {
                                            // Remove the item from the grid
                                            withAnimation {
                                                items.removeAll { $0 == value }
                                                selectedItem = nil
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.red)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                        }
                                        .offset(
                                            x: offsetX(value) + Self.size / 2 - 10,
                                            y: -Self.size / 2 + 10) // Position in top-right corner
                                    }
                                }
                            }
                            // You need to add height
                            .frame(
                                height: Self.size
                            )
                            .onAppear {
                                //                            let image = removeBackground(from: UIImage(resource: .appStore)) { image in
                                //                                print(image)
                                //                            }
                            }
                        }
                    }
                }
                // "+" Button to Add New Grid Item (Top-Right Corner)
                VStack {
                    HStack {
                        // Back Button (Top-Left Corner)
                        Button(action: {
                            // Action for the back button
                            print("Back button tapped")
                            // Add your custom back action here
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.black).opacity(0.8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 40)

                        Spacer()
                        Button(action: {
                            // Add a new item to the grid
                            withAnimation {
                                items.append(nextItemId)
                                nextItemId += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.black).opacity(0.8)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 40)
                    }
                    Spacer()
                }
            }
//            .offset(
//                x: 0,
//                y: isFullScreen ? -100 : 0
//            )
        }
        
        // Full Screen View
        if let selectedItem = selectedItem {
            ZStack {
                if isFullScreen {
                    // Background Image
                    Image("background-image-1") // Replace with your image name
                        .resizable() // Make the image resizable
                        .scaledToFill() // Fill the entire screen
                        .edgesIgnoringSafeArea([.all]) // Ignore safe area to cover
                        .onTapGesture {
                            withAnimation(.spring()) {
                                isFullScreen = false
                                self.selectedItem = nil
                            }
                        }
                }
                VStack(spacing: 20) {
                    ZStack {
                        // Full Screen Image
                        Image(appName(selectedItem))
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: selectedItem, in: animationNamespace) // Hero effect
                            .gesture(
                                DragGesture()
                                    .onEnded { gesture in
                                        if gesture.translation.height > 100 {
                                            withAnimation(.spring()) {
                                                isFullScreen = false
                                                self.selectedItem = nil
                                            }
                                        }
                                    }
                            )
                            .gesture(
                                TapGesture()
                                    .onEnded{
                                        // Action for the button
                                        // Trigger full-screen animation
                                        withAnimation(.spring()) {
                                            isFullScreen = true
                                        }
                                    }
                            )
                            .cornerRadius(20)
                        if isFullScreen {
                            // Left Chevron Button
                            HStack {
                                Button(action: {
                                    // Navigate to the previous image
                                    if selectedItem > 0 {
                                        withAnimation(.spring()) {
                                            self.selectedItem = selectedItem - 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black).opacity(0.9)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(.leading, 20)
                                
                                Spacer()
                                
                                // Right Chevron Button
                                Button(action: {
                                    // Navigate to the next image
                                    if selectedItem < items.count - 1 {
                                        withAnimation(.spring()) {
                                            self.selectedItem = selectedItem + 1
                                        }
                                    }
                                }) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.black).opacity(0.9)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 20)
                            }
                        }
                    }
                    if isFullScreen {
                        // Vertical Stack View with Multiple Rows
                        VStack(spacing: 10) {
                            // Row 1
                            HStack {
                                Text("TYPE:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Pop!")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            
                            // Row 2
                            HStack {
                                Text("RELEASE:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("2024")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            
                            // Row 3
                            HStack {
                                Text("STATUS:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Vaulted")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            // Row 4
                            HStack {
                                Text("ITEM #:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1604")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                            // Row 5
                            HStack {
                                Text("SERIES:")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Arcane - League of Legends")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 20)
                             // Row 6
                             HStack {
                                 Text("ESTIMATED PRICE")
                                     .font(.headline)
                                     .foregroundColor(.white)
                                 Spacer()
                                 Text("£35")
                                     .font(.subheadline)
                                     .foregroundColor(.white)
                             }
                             .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .background(Color.gray.opacity(0.4))
                        .cornerRadius(20)
                        .padding(.horizontal, 0)
                    }
                }
            }
            .transition(.opacity) // Smooth transition
            .zIndex(1) // Ensure the full-screen view is on top
        }
    }
    
    // Function to remove background from an image asynchronously
    func removeBackground(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        // Load the Core ML model
        guard let model = try? VNCoreMLModel(for: DeepLabV3().model) else {
            print("Failed to load Core ML model")
            completion(nil)
            return
        }

        // Create a Vision request
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Vision request error: \(error)")
                completion(nil)
                return
            }

            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let segmentationMap = results.first?.featureValue.multiArrayValue else {
                print("Failed to get segmentation map")
                completion(nil)
                return
            }

            // Process the segmentation map to create a mask
            let mask = createMask(from: segmentationMap, size: image.size)

            // Apply the mask to the original image
            let finalImage = applyMask(to: image, mask: mask)
            completion(finalImage)
        }

        // Perform the request
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform Vision request: \(error)")
                completion(nil)
            }
        }
    }

    // Helper function to create a mask from the segmentation map
    func createMask(from segmentationMap: MLMultiArray, size: CGSize) -> UIImage {
        print("Segmentation Map Shape: \(segmentationMap.shape)")
        // Get the dimensions of the segmentation map
        let height = segmentationMap.shape[0].intValue
        let width = segmentationMap.shape[1].intValue

        // Create a bitmap context to draw the mask
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        guard let context = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: width,
                                     space: colorSpace,
                                     bitmapInfo: bitmapInfo.rawValue) else {
            return UIImage()
        }

        // Draw the mask
        for y in 0..<height {
            for x in 0..<width {
                // Get the pixel value from the segmentation map
                let pixelValue = segmentationMap[y * width + x].intValue
                // Set the pixel color (white for foreground, black for background)
                let color = (pixelValue == 1) ? UInt8(255) : UInt8(0)
                context.setFillColor(gray: CGFloat(color) / 255.0, alpha: 1.0)
                context.fill(CGRect(x: x, y: y, width: 1, height: 1))
            }
        }

        // Create a CGImage from the context
        guard let cgImage = context.makeImage() else {
            return UIImage()
        }

        // Convert the CGImage to UIImage
        return UIImage(cgImage: cgImage)
    }

    // Helper function to apply the mask to the original image
    func applyMask(to image: UIImage, mask: UIImage) -> UIImage {
        // Ensure the mask and image are the same size
        let size = image.size
        let rect = CGRect(origin: .zero, size: size)

        // Create a bitmap context
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }

        // Draw the original image
        image.draw(in: rect)

        // Clip the context using the mask
        if let cgMask = mask.cgImage {
            context.clip(to: rect, mask: cgMask)
        }

        // Draw the original image again (only the clipped region will be visible)
        image.draw(in: rect)

        // Get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? image
    }

    func offsetX(_ value: Int) -> CGFloat {
        let rowNumber = value / gridItems.count

        if rowNumber % 2 == 0 {
            return Self.size/2 + Self.spacingBetweenColumns/2
        }

        return 0
    }

    func appName(_ value: Int) -> String {
        apps[value%apps.count]
    }

    var center: CGPoint {
        CGPoint(
            x: UIScreen.main.bounds.size.width*0.5,
            y: UIScreen.main.bounds.size.height*0.5
        )
    }

    // This was my hardcoded approach... really bad for the future!
//    var deviceCornerAngle: CGFloat {
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            return (UIDevice.current.orientation == .portrait) ? 55 : 35
//        } else {
//            return (UIDevice.current.orientation == .portrait) ? 65 : 25
//        }
//    }

    func scale(proxy: GeometryProxy, value: Int) -> CGFloat {
        let rowNumber = value / gridItems.count

        // We need to consider the offset for even rows!
        let x = (rowNumber % 2 == 0)
        ? proxy.frame(in: .global).midX + proxy.size.width/2
        : proxy.frame(in: .global).midX

        let y = proxy.frame(in: .global).midY
        let maxDistanceToCenter = getDistanceFromEdgeToCenter(x: x, y: y)

        let currentPoint = CGPoint(x: x, y: y)
        let distanceFromCurrentPointToCenter = distanceBetweenPoints(p1: center, p2: currentPoint)

        // This creates a threshold for not just the pure center could get
        // the max scaleValue.
        let distanceDelta = min(
            abs(distanceFromCurrentPointToCenter - maxDistanceToCenter),
            maxDistanceToCenter*0.3
        )

        // Helps to get closer to scale 1.0 after the threshold.
        let scalingFactor = 3.3
        let scaleValue = distanceDelta/(maxDistanceToCenter) * scalingFactor

        return scaleValue
    }

    func getDistanceFromEdgeToCenter(x: CGFloat, y: CGFloat) -> CGFloat {
        let m = slope(p1: CGPoint(x: x, y: y), p2: center)
        let currentAngle = angle(slope: m)

        let edgeSlope = slope(p1: .zero, p2: center)
        let deviceCornerAngle = angle(slope: edgeSlope)

        if currentAngle > deviceCornerAngle {
            let yEdge = (y > center.y) ? center.y*2 : 0
            let xEdge = (yEdge - y)/m + x
            let edgePoint = CGPoint(x: xEdge, y: yEdge)

            return distanceBetweenPoints(p1: center, p2: edgePoint)
        } else {
            let xEdge = (x > center.x) ? center.x*2 : 0
            let yEdge = m * (xEdge - x) + y
            let edgePoint = CGPoint(x: xEdge, y: yEdge)

            return distanceBetweenPoints(p1: center, p2: edgePoint)
        }
    }

    func distanceBetweenPoints(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let xDistance = abs(p2.x - p1.x)
        let yDistance = abs(p2.y - p1.y)

        return CGFloat(
            sqrt(
                pow(xDistance, 2) + pow(yDistance, 2)
            )
        )
    }

    func slope(p1: CGPoint, p2: CGPoint) -> CGFloat {
        return (p2.y - p1.y)/(p2.x - p1.x)
    }

    func angle(slope: CGFloat) -> CGFloat {
        return abs(atan(slope) * 180 / .pi)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppleWatchView()
    }
}

struct Axes: View {
    var body: some View {

        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: geometry.frame(in: .global).maxX, y: geometry.frame(in: .global).midY))
                path.addLine(to: CGPoint(x: 0, y: geometry.frame(in: .global).midY))
                path.move(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).midY))
                path.addLine(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).maxY))

                path.addLine(to: CGPoint(x: geometry.frame(in: .global).midX, y: geometry.frame(in: .global).minY - 60))
            }
            .stroke(Color.blue, lineWidth: 3)
        }
    }
}
