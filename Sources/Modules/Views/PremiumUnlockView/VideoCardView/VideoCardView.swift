//
//  VideoCardView.swift
//  FunKollector
//
//  Created by Home on 13.04.2025.
//

import SwiftUI
import AVKit

struct VideoCardView: View {
    let videoName: String
    let title: String
    let description: String
    var onVideoEnded: (() -> Void)?
    @StateObject private var viewModel: VideoPlayerViewModel
    
    init(videoName: String, title: String, description: String, onVideoEnded: (() -> Void)? = nil) {
        self.videoName = videoName
        self.title = title
        self.description = description
        self.onVideoEnded = onVideoEnded
        self._viewModel = StateObject(
            wrappedValue: VideoPlayerViewModel(
                videoName: videoName,
                onVideoEnded: onVideoEnded
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 16) {
            videoContainer
                .frame(maxHeight: .infinity)
                .aspectRatio(9/18, contentMode: .fit)
                .background(Color(.clear))
                .cornerRadius(UIDevice.isIpad ? 52 : 32)
        }
    }
    
    @ViewBuilder
    private var videoContainer: some View {
        if let error = viewModel.error {
            errorStateView(error: error)
        } else if let player = viewModel.player {
            CustomVideoPlayer(player: player)
                .onAppear { player.play() }
                .onDisappear { player.pause() }
        } else {
            ProgressView()
                .frame(height: 200)
        }
    }
    
    private func errorStateView(error: Error) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("Video unavailable")
                .font(.subheadline)
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundColor(.red)
        .padding()
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed
    }
}
