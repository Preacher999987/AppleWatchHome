//
//  FullScreenCarouselView.swift
//  FunKollector
//
//  Created by Home on 05.04.2025.
//

import SwiftUI

// MARK: - FullScreenCarouselView
struct FullScreenCarouselView: View {
    @Environment(\.dismiss) private var dismiss
    let galleryImages: [ImageData]
    let initialIndex: Int
    @Binding var currentIndex: Int
    let itemDetails: Collectible
    
    private let apiClient: APIClientProtocol
    
    @State private var localIndex: Int
    @State private var showDetails = false
    @State private var currentScale: CGFloat = 1.0
    
    init(galleryImages: [ImageData], initialIndex: Int, currentIndex: Binding<Int>, itemDetails: Collectible, apiClient: APIClientProtocol = APIClient.shared) {
        self.galleryImages = galleryImages
        self.initialIndex = initialIndex
        self._currentIndex = currentIndex
        self.itemDetails = itemDetails
        self._localIndex = State(initialValue: initialIndex)
        self.apiClient = apiClient
    }
    
    var body: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
            
            // Main Carousel with TabView
            TabView(selection: $localIndex) {
                ForEach(Array(galleryImages.enumerated()), id: \.offset) { index, imageData in
                    ZoomableImage(
                        url: apiClient.imageURL(from: imageData),
                        placeholder: Image(.gridItemPlaceholder),
                        currentScale: $currentScale,
                        onDismiss: { dismiss() }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always)) // Hide default page indicator
            .onChange(of: localIndex) { newValue in
                currentIndex = newValue
                currentScale = 1.0 // Reset zoom when changing images
            }
            
            // Navigation Arrows
            if galleryImages.count > 1 && currentScale == 1.0 {
                HStack {
                    navigationButton(direction: .left)
                    Spacer()
                    navigationButton(direction: .right)
                }
                .padding(.horizontal, 20)
            }
            
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    private func navigationButton(direction: Direction) -> some View {
        Button {
            withAnimation {
                let count = galleryImages.count
                localIndex = direction == .left ?
                    (localIndex - 1 + count) % count :
                    (localIndex + 1) % count
            }
        } label: {
            Image(systemName: direction == .left ? "chevron.left.circle.fill" : "chevron.right.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .opacity(0.8)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    private enum Direction { case left, right }
}

struct ZoomableImage: View {
    let url: URL?
    let placeholder: Image
    @Binding var currentScale: CGFloat
    let onDismiss: () -> Void

    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AsyncImageLoader(
                    url: url,
                    placeholder: placeholder,
                    grayScale: false
                )
                .scaledToFit()
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .scaleEffect(currentScale)
            .offset(offset)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / self.lastScale
                        self.currentScale *= delta
                        self.lastScale = value
                    }
                    .onEnded { _ in
                        self.lastScale = 1.0
                        if currentScale < 1.0 {
                            withAnimation {
                                self.currentScale = 1.0
                                self.offset = .zero
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { gesture in
                        if currentScale > 1.0 {
                            self.offset = CGSize(
                                width: self.lastOffset.width + gesture.translation.width,
                                height: self.lastOffset.height + gesture.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        self.lastOffset = self.offset
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation {
                            if self.currentScale > 1.0 {
                                self.currentScale = 1.0
                                self.offset = .zero
                                self.lastOffset = .zero
                            } else {
                                self.currentScale = 3.0
                            }
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}
