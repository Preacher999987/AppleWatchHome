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
    private var cancellables = Set<AnyCancellable>()
    
    init(videoName: String) {
        setupPlayer(videoName: videoName)
    }
    
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
            }
            .store(in: &cancellables)
    }
    
    deinit {
        player?.pause()
        player = nil
    }
}
