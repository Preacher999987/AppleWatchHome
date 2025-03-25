struct AsyncImageLoader: View {
        let url: URL?
        let placeholder: Image
        @State private var showPlaceholder = false
        @State private var delayedTask: Task<Void, Never>?
        
        var body: some View {
            Group {
                if let url = url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            if showPlaceholder {
                                placeholder
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Color.clear
                                    .onAppear(perform: startDelayTimer)
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .transition(.opacity.animation(.easeOut(duration: 0.5)))
                        case .failure:
                            placeholder
                                .resizable()
                                .scaledToFit()
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
                }
            }
            .onDisappear {
                delayedTask?.cancel()
            }
        }
        
        private func startDelayTimer() {
            delayedTask = Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                if !Task.isCancelled {
                    showPlaceholder = true
                }
            }
        }
    }