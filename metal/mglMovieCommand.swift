//
//  mglMovie.swift
//  mglMetal
//
//  Created by Justin Gardner on 12/20/25.
//  Copyright © 2025 GRU. All rights reserved.
//

import Foundation
import MetalKit
import AVFoundation
import AppKit

class mglMovieCommand : mglCommand {
    // Keep references to the AVPlayer and layer
    // so that they continue to play
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It should
    // initialize the movie and the display layer
    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        
        // call super-class and tell it that the movie takes
        // 1 frame to draw. The 1 frame is just to tell
        // mglRenderer to start the video. The video then
        // plays asynchronous to the main metal loop
        super.init(framesRemaining: 1)
        logger.info(component: "mglMovieCommand", details: "mglMovieCommand: Called")
    }
    
    // This will get called from mglRenderer when which
    // has access to the view
    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        logger.info(component: "mglMovieCommand", details: "Draw called")
        // Only set up the movie once
         if player == nil {
             logger.info(component: "mglMovieCommand", details: "Starting")

             // Ensure the Metal view is layer-backed
             view.wantsLayer = true

             // Locate the movie file in the app bundle
             // Change name and extension as needed
             guard let videoURL = Bundle.main.url(
                 forResource: "shibuya",
                 withExtension: "mp4"
             ) else {
                 logger.error(component: "mglMovieCommand:", details: "movie file not found")
                 return true
             }

             // Create a player item from the file
             let playerItem = AVPlayerItem(url: videoURL)

             // Create the AVPlayer (handles video + audio)
             let player = AVPlayer(playerItem: playerItem)
             self.player = player

             // Create a layer that can render the video
             let playerLayer = AVPlayerLayer(player: player)
             self.playerLayer = playerLayer

             // Preserve aspect ratio, add black bars if needed
             playerLayer.videoGravity = .resizeAspect

             // Make the video fill the Metal view
             playerLayer.frame = view.bounds

             // Insert the video behind the Metal content
             //view.layer?.insertSublayer(playerLayer, at: 0)
             view.layer?.addSublayer(playerLayer)

             // Start playback
             player.play()
         }

         // Nothing for Metal to draw for this command
         return true
     }
}

