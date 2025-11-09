//
//  ReusableVideoPlayer.swift
//  temp
//
//  Created by Norbert on 08/11/2025.
//


import SwiftUI
import AVKit

struct ReusableVideoPlayer: View {
    let url: URL
    var autoPlay: Bool = true
    var loop: Bool = true
    var height: CGFloat = 600

    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .frame(height: .infinity)
            .cornerRadius(10)
            .onAppear {
                let avPlayer = AVPlayer(url: url)
                player = avPlayer

                if autoPlay {
                    avPlayer.play()
                }

                if loop {
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: avPlayer.currentItem,
                        queue: .main
                    ) { _ in
                        avPlayer.seek(to: .zero)
                        avPlayer.play()
                    }
                }
            }
    }
}
