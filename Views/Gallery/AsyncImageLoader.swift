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
    @State private var showPlaceholder = false
    @State private var delayedTask: Task<Void, Never>?
    @State private var isPulsating = false
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            if showPlaceholder {
                                placeholder
                                    .resizable()
                                    .scaledToFit()
                                    .opacity(isPulsating ? 0.8 : 1.0) // Opacity pulse
                                    .scaleEffect(isPulsating ? 0.95 : 1.0) // Scale pulse
                            } else {
                                Color.clear
                            }
                        }
                        .onAppear {
                            startDelayTimer()
                            isPulsating = true
                        }
                        .onDisappear {
                            isPulsating = false
                        }
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isPulsating
                        )
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .saturation(grayScale ? 0 : 1)
                            .transition(.opacity.animation(.easeOut(duration: 0.5)))
                        
                    case .failure:
                        placeholder
                            .resizable()
                            .scaledToFit()
                            .opacity(isPulsating ? 0.8 : 1.0)
                            .scaleEffect(isPulsating ? 0.95 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                                value: isPulsating
                            )
                            .onAppear { isPulsating = true }
                            .onDisappear { isPulsating = false }
                        
                    @unknown default:
                        placeholder
                            .resizable()
                            .scaledToFit()
                    }
                }
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
                    .opacity(isPulsating ? 0.8 : 1.0)
                    .scaleEffect(isPulsating ? 0.95 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: isPulsating
                    )
                    .onAppear { isPulsating = true }
                    .onDisappear { isPulsating = false }
            }
        }
        .onDisappear {
            delayedTask?.cancel()
            isPulsating = false
        }
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

#Preview {
    AsyncImageLoader(url: nil, placeholder: Image(.gridItemPlaceholder), grayScale: false)
}
