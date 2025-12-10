//
//  AudioService.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI
import AVFoundation
import Combine

class AudioService: ObservableObject {
    static let shared = AudioService()
    
    private var player: AVPlayer?
    @Published var isPlaying: Bool = false
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Log.debug("❌ AudioService: Failed to setup audio session - \(error)")
        }
    }
    
    func play(url: String) {
        guard let audioURL = URL(string: url) else {
            Log.debug("❌ AudioService: Invalid URL - \(url)")
            return
        }
        
        // Stop any current playback
        player?.pause()
        player = nil
        
        Log.debug("🔊 AudioService: Playing \(url)")
        
        let playerItem = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Reset isPlaying when audio finishes
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
        }
        
        isPlaying = true
        player?.play()
    }
}
