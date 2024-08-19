//
//  VideoView.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import AVKit
import SwiftUI

struct VideoView: View {
    var videoUrl: URL
    
    @State var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear{
                  if player.currentItem == nil {
                        let item = AVPlayerItem(url: videoUrl)
                        player.replaceCurrentItem(with: item)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        player.play()
                    })
                }
    }
}
