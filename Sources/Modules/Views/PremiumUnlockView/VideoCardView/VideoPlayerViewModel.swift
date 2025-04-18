//
//  VideoPlayerViewModel.swift
//  FunKollector
//
//  Created by Home on 13.04.2025.
//


import AVKit
import Combine

class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var error: Error?
    var onVideoEnded: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    init(videoName: String, onVideoEnded: (() -> Void)? = nil) {
        self.onVideoEnded = onVideoEnded
        setupPlayer(videoName: videoName)
    }
    
//    private func loadVideo(named name: String) {
//        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
//            self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Video file not found"])
//            return
//        }
//        
//        let player = AVPlayer(url: url)
//        self.player = player
//        
//        // Add observer for when video ends
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(playerDidFinishPlaying),
//            name: .AVPlayerItemDidPlayToEndTime,
//            object: player.currentItem
//        )
//    }
//    
//    @objc private func playerDidFinishPlaying() {
//        onVideoEnded?() // Notify parent view
//    }
//    
    private func setupPlayer(videoName: String) {
        // Configure audio session first
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            self.error = error
            return
        }
        
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            self.error = NSError(domain: "Video not found", code: 404, userInfo: nil)
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true // Required for autoplay
        player?.actionAtItemEnd = .none
        
        // Set up loop
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            .sink { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
                self?.onVideoEnded?()
            }
            .store(in: &cancellables)
    }
    
    deinit {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
}
