//
//  AsyncImageLoader.swift
//  FunkoCollector
//
//  Created by Home on 24.03.2025.
//

import SwiftUI

struct AsyncImageLoader: View {
    let url: URL?
    let placeholder: Image
    let grayScale: Bool
    var requiresAuth: Bool = false

    @State private var uiImage: UIImage? = nil
    @State private var isLoading = false
    @State private var showPlaceholder = false
    @State private var delayedTask: Task<Void, Never>?
    @State private var isPulsating = false

    var body: some View {
        Group {
            if requiresAuth {
                if let image = uiImage {
                    animatedImage(Image(uiImage: image))
                } else {
                    placeholderView(animatedPlaceholder)
                }
            } else {
                if let url = url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderView(animatedPlaceholder)
                        case .success(let image):
                            animatedImage(image)
                        case .failure:
                            placeholderView(placeholder)
                        @unknown default:
                            placeholderView(placeholder)
                        }
                    }
                } else {
                    placeholderView(placeholder)
                }
            }
        }
        .onDisappear {
            delayedTask?.cancel()
            isPulsating = false
        }
    }

    private func animatedImage(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .saturation(grayScale ? 0 : 1)
            .withImageTransition()
    }

    private func placeholderView(_ placeholder: some View) -> some View {
        ZStack {
            if showPlaceholder {
                placeholder
                    .withImageTransition()
            } else {
                Color.clear
            }
        }
        .onAppear {
            if requiresAuth {
                loadImage()
            }
            startDelayTimer()
        }
    }

    private var animatedPlaceholder: some View {
        placeholder
            .resizable()
            .scaledToFit()
            .opacity(isPulsating ? 0.8 : 1.0)
            .scaleEffect(isPulsating ? 0.95 : 1.0)
            .onAppear {
                isPulsating = true
            }
            .onDisappear {
                isPulsating = false
            }
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsating
            )
    }

    private func loadImage() {
        guard !isLoading, let url = url else { return }
        isLoading = true

        var request = URLRequest(url: url)
        if requiresAuth {
            try? request.addAuthorizationHeader()
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            isLoading = false
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                }
            } else {
                print("Image load error:", error?.localizedDescription ?? "Unknown error")
            }
        }.resume()
    }

    private func startDelayTimer() {
        delayedTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if !Task.isCancelled {
                showPlaceholder = true
            }
        }
    }
}

extension View {
    func withImageTransition() -> some View {
        withAnimation {
            self
                .transition(.opacity.animation(.easeOut(duration: 0.5)))
        }
    }
}
