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
    @StateObject private var viewModel: VideoPlayerViewModel
    
    init(videoName: String, title: String, description: String) {
        self.videoName = videoName
        self.title = title
        self.description = description
        self._viewModel = StateObject(wrappedValue: VideoPlayerViewModel(videoName: videoName))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            videoContainer
                .frame(maxHeight: .infinity)
                .aspectRatio(9/18, contentMode: .fit)
//                .padding(.horizontal, 32)
                .background(Color(.clear))
                .cornerRadius(28)
            
//            VStack(spacing: 8) {
//                Text(title)
//                    .font(.headline.weight(.semibold))
//                
//                Text(description)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.horizontal, 16)
//            .padding(.bottom, 24)
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
