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
    // Keep references to the AVPlayer and AVPlayerItem
    // which carry the player and the movie
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    // these are for rendering each frame from the AVPlayerItem
    private var videoOutput: AVPlayerItemVideoOutput
    private var textureCache: CVMetalTextureCache
    private var device: MTLDevice?
    
    // Keep around a pointer to the mglLogger for debugging info
    private var logger: mglLogger?
    
    private var samplerState: MTLSamplerState!

    // This is just used for testing with drawInLayer and is not used
    // for typical operation in which we grab frames from the AVPlayerItem
    // and render them with our metal pipeline.
    private var playerLayer: AVPlayerLayer?
    
    private var currentVideoFrame: MTLTexture?
    private let vertexBufferTexture: MTLBuffer
    private let vertexCount: Int
    private var phase: Float32 = 0.0

    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It should
    // initialize the movie and the display layer
    init?(commandInterface: mglCommandInterface, device: MTLDevice, logger: mglLogger) {
        logger.info(component: "mglMovieCommand", details: "mglMovieCommand: Reading Vertex Info")
        
        guard let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: device, extraVals: 2) else {
            return nil
        }
        logger.info(component: "mglMovieCommand", details: "mglMovieCommand: Read \(vertexCount) vertices")
        self.vertexBufferTexture = vertexBufferTexture
        self.vertexCount = vertexCount

        // Pixel format compatible with Metal
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        // Initialize videoOutput
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        self.videoOutput = videoOutput
        
        // create Metal Texture Cache
        var cache: CVMetalTextureCache? = nil
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        self.textureCache = cache!
        
        // store pointers for referencing them later
        self.device = device
        self.logger = logger
        
        // call super-class and tell it that the movie takes
        // 1 frame to draw. The 1 frame is just to tell
        // mglRenderer to start the video. The video then
        // plays asynchronous to the main metal loop
        super.init(framesRemaining: 15)
        
        // debugging information, can be removed once this code is working and tested
        self.logger?.info(component: "mglMovieCommand", details: "mglMovieCommand: Called")
        
        // load the video
        self.loadVideo()
        
        // add the videoOutput to the playerItem which should
        // now be allocated from loadVideo
        if let playerItem = self.playerItem {
            playerItem.add(videoOutput)
        }
        
        // create a samplerState for displaying the video frame textures
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .notMipmapped
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        let samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
        self.samplerState = samplerState
    }
    
    // draw: This will get called from mglRenderer when which
    // has access to the view
    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {
        // debugging information, can be removed once this code is working and tested
        logger.info(component: "mglMovieCommand", details: "Draw called")
        
        // This is used for testing layer drawing, can be removed if no longer needed:
        // jg 12/22/2025
        //drawInLayer(logger: logger, view: view)
        
        if let frame = getCurrentFrameAsTexture(hostTime: CACurrentMediaTime()) {
            currentVideoFrame = frame
            self.logger?.info(component: "mglMovieCommand:", details: "Got a new frame at time: \(CACurrentMediaTime())")
        }
        
        // display the frame
        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(currentVideoFrame, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        
        // Nothing for Metal to draw for this command
        return true
    }
    
    // load the video, creating an AVPlayerItem for the video and an AVPlayer which
    // manages playing of the video
    func loadVideo() {
        
        if player == nil {
            self.logger?.info(component: "mglMovieCommand", details: "loadVideo:Starting")
                
            // Locate the movie file in the app bundle
            // This is for test purposes
            guard let videoAsset = Bundle.main.url(
                forResource: "shibuya",
                withExtension: "mp4"
            ) else {
                self.logger?.error(component: "mglMovieCommand:", details: "Movie asset not found")
                return
            }
                
            // Create a player item from the file
            let playerItem = AVPlayerItem(url: videoAsset)
            self.playerItem = playerItem

            // print info about the movie
            self.info(asset: playerItem.asset, logger: self.logger)
                
            // Create the AVPlayer (handles video + audio)
            let player = AVPlayer(playerItem: playerItem)
            self.player = player
                
        }
    }
    
    // getCurrentFrameAsTexture: will extract a metal texture from
    // AVPlayerItem that corresponds to the current time (usually CACurrentMediaTime())
    // Note that this will return nil if there is no new texture
    func getCurrentFrameAsTexture(hostTime: CFTimeInterval) -> MTLTexture? {
        
        // get the itemTime corresponding to the current hostTime
        let itemTime = videoOutput.itemTime(
            forHostTime: hostTime
        )

        // Check for a new frame, return nil if there is nothing
        guard videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
              let pixelBuffer = videoOutput.copyPixelBuffer(
                    forItemTime: itemTime,
                    itemTimeForDisplay: nil
              )
        else {
            return nil
        }

        // get width and height of pixelBuffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // convert to texture
        var cvTexture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTexture
        )

        // if successful, return the texture
        guard status == kCVReturnSuccess,
              let metalTexture = CVMetalTextureGetTexture(cvTexture!)
        else {
            return nil
        }
        return metalTexture
    }

    // drawInLayer: This is test code which loads the test movie asset
    // used AVPlayer and AVPlayerLayer to display the movie. The AVPlayerLayer
    // is drawn above the metal layer. If needed, this could be expanded to
    // put the AVPlayerLayer below the metal layer, make the metal layer transaparent
    // so that it can draw above it, but instead we are building out code to
    // do the video drawing ourselves by extracting frames and directly rendering
    // in our metal pipeline. Leaving this code in here as it is working, but
    // likely will not be called later: jlg 12/22/2025
    func drawInLayer(logger: mglLogger, view: MTKView) {
        // Only set up the movie once
        if self.player != nil && self.playerLayer == nil {
            logger.info(component: "mglMovieCommand", details: "drawInLayer:Starting")
            
            // Ensure the Metal view is layer-backed
            view.wantsLayer = true
            
            // Create a layer that can render the video
            let playerLayer = AVPlayerLayer(player: self.player)
            self.playerLayer = playerLayer
            
            // Preserve aspect ratio, add black bars if needed
            playerLayer.videoGravity = .resizeAspect
            
            // Make the video fill the Metal view
            playerLayer.frame = view.bounds
            
            // Insert the video behind the Metal content
            //view.layer?.insertSublayer(playerLayer, at: 0)
            view.layer?.addSublayer(playerLayer)
            
            // Start playback
            player?.play()
        }
    }

    // info: Extracts information like frame rate, length, native pixel
    // dimensions from AV file.
    func info(asset: AVAsset, logger: mglLogger?) {
        // Frame rate
        if let track = asset.tracks(withMediaType: .video).first {
            let frameRate = track.nominalFrameRate
            logger?.info(component: "mglMovieCommand", details: "Frame rate: \(frameRate) fps")
            
            // Total frames
            let duration = track.timeRange.duration
            let totalFrames = Int(duration.seconds * Double(frameRate))
            logger?.info(component: "mglMovieCommand", details: "Total frames: \(totalFrames)")
        }
        
        // List all tracks
        for track in asset.tracks {
            // extract the track ID, media type, size and duration.
            logger?.info(component: "mglMovieCommand", details: "Track ID: \(track.trackID)")
            logger?.info(component: "mglMovieCommand", details: "Media type: \(track.mediaType.rawValue)")
            logger?.info(component: "mglMovieCommand", details: "Natural size: \(track.naturalSize)")
            logger?.info(component: "mglMovieCommand", details: "Duration: \(track.timeRange.duration.seconds) seconds")
            
            // gets the description of the track, this seems to carry a lot of
            // custom information and has a large print out, maybe not needed
            if let formatDescriptions = track.formatDescriptions as? [CMFormatDescription] {
                for desc in formatDescriptions {
                    //logger.info(component: "mglMovieCommand", details: "Format description: \(desc)")
                }
            }
        }
    }

    
}

