//
//  ContentView.swift
//  FunkoCollector
//
//  Created by Pedro Rojas on 29/09/21.
//

import SwiftUI
import CoreML
import Vision
import PhotosUI // Import PhotosUI for PHPickerViewController

struct LazyGridGalleryView: View {
    @Namespace private var animationNamespace // For matchedGeometryEffect
    @State private var selectedItem: Int? = nil // Track the selected grid item
    @State private var isFullScreen: Bool = false // Track full-screen state
    @State private var items: [Int] = Array(0..<12) // Track grid items
    @State private var nextItemId: Int = 12 // Track the next item ID
    @State private var selectedBackgroundImage: UIImage? = nil // Store the selected background image
    @State private var isShowingImagePicker: Bool = false // Control the image picker presentation
    
    private static let size: CGFloat = 150
    private static let spacingBetweenColumns: CGFloat = 12
    private static let spacingBetweenRows: CGFloat = 12
    private static let totalColumns: Int = 2
    
    
    let payload: AnalysisResult?

    var gridItems = Array(
        repeating: GridItem(
            .fixed(size),
            spacing: spacingBetweenColumns,
            alignment: .center
        ),
        count: totalColumns
    )

    var body: some View {
        ZStack {
            // Background Image
            if let backgroundImage = selectedBackgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea([.all])
            } else {
                Image("background-image-1") // Default background image
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea([.all])
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
                    .padding(.trailing, 0)
                    .padding(.top, 40)
                    
                    Button(action: {
                        // Show the image picker
                        isShowingImagePicker = true
                    }) {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black).opacity(0.8)
                            .background(Color.gray)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 40)
                }
                Spacer()
            }
            .zIndex(2)
            
            VStack {
                // Full Screen View
                if !isFullScreen {
                    //        if true {
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
                    
                    // Image Picker
                    .sheet(isPresented: $isShowingImagePicker) {
                        ImagePicker(selectedImage: $selectedBackgroundImage)
                    }
                }
                
                // Full Screen View
                if let selectedItem = selectedItem {
                    VStack(spacing: 20) {
                        ZStack {
                            Image(appName(selectedItem))
                                .resizable()
                                .applyConditionalScaling(isScaledToFit: isFullScreen)
                                .offset(
                                    y: !isFullScreen ? 150 : 0
                                )
                                .frame(height: !isFullScreen ? 300 : .infinity)
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
                        .layoutPriority(0)
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
                            .layoutPriority(1)
                            .padding(.vertical, 20)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(20)
                            .padding(.bottom, 60)
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity) // Smooth transition
                }
            }
        }
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

// Image Picker using PHPickerViewController
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // Allow only images to be selected
        configuration.selectionLimit = 1 // Allow only one image to be selected

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let result = results.first else { return }

            // Load the selected image
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image // Set the selected image as the background
                    }
                }
            }
        }
    }
}

// Custom View Modifier for Conditional Scaling
extension View {
    @ViewBuilder
    func applyConditionalScaling(isScaledToFit: Bool) -> some View {
        if isScaledToFit {
            self.scaledToFit() // Apply .scaledToFit() if condition is true
        } else {
            self.scaledToFill() // Apply .scaledToFill() if condition is false
        }
    }
}
