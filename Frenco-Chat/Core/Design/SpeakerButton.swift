//
//  SpeakerButton.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI

struct SpeakerButton: View {
    let audioUrl: String?
    var size: CGFloat = 24
    
    @ObservedObject private var audioService = AudioService.shared
    
    var body: some View {
        if let url = audioUrl, !url.isEmpty {
            Button(action: {
                audioService.play(url: url)
            }) {
                ZStack {
                    Circle()
                        .fill(Color.matcha.opacity(0.15))
                        .frame(width: size + 16, height: size + 16)
                    
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(.matcha)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

#Preview {
    SpeakerButton(audioUrl: "https://example.com/audio.mp3")
}
