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

// command to create a movie 
class mglMovieCreateCommand : mglCommand {

    private let movie: mglMovie
    var movieNumber: UInt32 = 0
    var movieCount: UInt32 = 0

    // direct init called for debugging
    init(movie: mglMovie) {
        self.movie = movie
        super.init()
    }

    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It initializes
    // an instance of mglMovie and keeps it in mglColorRenderingConfig
    // it will return an integer number that can be used to reference
    // the movie for playback etc
    init?(commandInterface: mglCommandInterface, device: MTLDevice, logger: mglLogger) {
        
        // Read the vertex information for the movie
        logger.info(component: "mglMovie", details: "mglMovieCreateCommand: Reading Vertex Info")
        
        guard let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: device, extraVals: 2) else {
            return nil
        }
        logger.info(component: "mglMovie", details: "mglMovieCreateCommand: Read \(vertexCount) vertices")
        
        // create the movie class
        guard let movie = mglMovie(vertexCount: vertexCount, vertexBufferTexture: vertexBufferTexture, device: device, logger: logger) else { return nil }
        self.movie = movie
        
        // call super
        super.init()
    }
    
    // this gets called after initialization, instead of drawing, we
    // just log the loaded movie
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        // try to preload to get things going
        movie.preload(view: view)
        
        // store the movie in colorRenderingState
        movieNumber = colorRenderingState.addMovie(movie: movie)
        movieCount = colorRenderingState.getMovieCount()
        return true
    }

    
    // this is used to return the movie number to matlab/python
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        if (movieNumber < 1) {
            // A heads up that something went wrong.
            _ = commandInterface.writeDouble(data: -commandInterface.secs.get())
        }

        // A heads up that return data is on the way.
        _ = commandInterface.writeDouble(data: commandInterface.secs.get())

        // Specific return data for this command.
        _ = commandInterface.writeUInt32(data: movieNumber)
        _ = commandInterface.writeUInt32(data: movieCount)
        return true
    }

}

class mglMoviePlayCommand : mglCommand {
    var movieNumber: UInt32 = 0
    var movie: mglMovie? = nil
    var videoAtEnd: Bool = false
    var frameTimes: [Double] = []
    
    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It reads the
    // movieNumber and starts playback of the movie
    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        // Read the moveNumber
        guard let movieNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.movieNumber = movieNumber
        logger.info(component: "mglMovie", details: "mglMoviePlayCommand: Read movieNumber: \(movieNumber)")
        
        // call super,set framesRemaining to 1. In the draw function, we
        // will continue to reset this as long as there is more of the
        // video to play (so that the command will run for as long is needed
        // to display the full movie)
        super.init(framesRemaining: 1)
    }
    
    // this gets called after initialization, we get the movie from the movieNum
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        
        // get the movie indexed by movieNumber
        if self.movie == nil {
            guard let movie = colorRenderingState.getMovie(
                movieNumber: self.movieNumber
            ) else {
                
                logger.error(component: "mglMovie", details: "mglMoviePlay: Failed to get movie \(self.movieNumber)")
                return false
            }
            self.movie = movie
            
            // start the movie playing
            self.movie?.play()
            logger.info(component: "mglMovie", details: "mglMoviePlay: Got movie and started playing")
        }
        return true
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

        // if video is finished playing, then just return
        if videoAtEnd == true {
            return true
        }
        
        logger.info(component: "mglMovie", details: "mglMoviePlay: Draw")
        var didDrawFrame = false
        if let movie = self.movie {
            let (frameDrawn, frameTime) = movie.drawFrame(
                logger: logger,
                view: view,
                colorRenderingState: colorRenderingState,
                renderEncoder: renderEncoder
            )
            // keep returned values
            didDrawFrame = frameDrawn
            frameTimes.append(CMTimeGetSeconds(frameTime ?? CMTime.zero))
        }
        
        if didDrawFrame {
            // frame drawn, so keep going
            self.framesRemaining += 1
        } else {
            videoAtEnd = true
            self.framesRemaining += 1
        }
        
        return true
    }

    // this is used to return the movie number to matlab/python
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {

        // convert presentedTimes to seconds and return that
        let presentedTimesSeconds: [Double] = presentedTimes.map { $0.presentedTime ?? 0.0 }
        _ = commandInterface.writeDoubleArray(data: presentedTimesSeconds)
        
        // return frameTimes
        _ = commandInterface.writeDoubleArray(data: frameTimes)


        return true
    }

}

class mglMovieStatusCommand : mglCommand {
    var movieNumber: UInt32 = 0
    var movie: mglMovie? = nil
    
    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It reads the
    // movieNumber and starts playback of the movie
    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        // Read the moveNumber
        guard let movieNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.movieNumber = movieNumber
        logger.info(component: "mglMovie", details: "mglMovieStatusCommand: Read movieNumber: \(movieNumber)")
        
        // call super
        super.init()
    }
    
    // this gets called after initialization, we get the movie from the movieNum
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4
    ) -> Bool {
        
        if self.movie == nil {
            guard let movie = colorRenderingState.getMovie(
                movieNumber: self.movieNumber
            ) else {
                logger.error(component: "mglMovie", details: "mglMovieStatus: Failed to get movie \(self.movieNumber)")
                return false
            }
            
            self.movie = movie
        }
        return true
    }
    
    // this is used to return the status to matlab/python
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {

        guard let movie = self.movie else {
            // state 0 is error
            _ = commandInterface.writeUInt32(data: 0)
            return true
        }

        // Specific return data for this command.
        _ = commandInterface.writeUInt32(data: 1)
        return true
    }

}



// class that holds the movie, AVPlayer and all the stuff needed
// to make the movie run
class mglMovie {
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
    
    // variables used for blting the texture
    private let vertexBufferTexture: MTLBuffer
    private let vertexCount: Int
    private var phase: Float32 = 0.0
    
    // sets whether the video has been played to the end
    var videoAtEnd: Bool = false
    
    // these will be extracted when info is called
    var frameRate: Float?
    var duration: CMTime?
    var totalFrames: Int?
    var width: Int?
    var height: Int?
    
    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It should
    // initialize the movie and the display layer
    init?(vertexCount: Int, vertexBufferTexture: MTLBuffer, device: MTLDevice, logger: mglLogger) {
        
        logger.info(component: "mglMovie", details: "mglMovie: Initializing an mglMovie")
        
        // keep the vertices that are used for blting the textures from the movie
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
        
        // set a notification for when the video ends
        NotificationCenter.default.addObserver(
             self,
             selector: #selector(movieDidEnd),
             name: .AVPlayerItemDidPlayToEndTime,
             object: playerItem
         )
        
    }
    
    
    
    // remember to remove observer if this variable is removed
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // function which gets called if the movie ends
    @objc private func movieDidEnd() {
        videoAtEnd = true
        // seek video to beginning (so it can be replayed)
        self.player?.seek(to: .zero)
    }

    
    // try to preload video and preallocate buffers for faster start
    func preload(view: MTKView) {
        // preallocate buffer for keeping frame times, first we will
        // need to know the maximum frame rate. Default to 120 fps
        // for systems that do not report
        let fps: Int
        if let screen = view.window?.screen {
            if #available(macOS 12.0, *) {
                fps = screen.maximumFramesPerSecond
            } else {
                fps = 120   // fallback for older macOS
            }
        } else {
            fps = 120       // conservative default if no screen yet
        }
        logger?.info(component: "mglMovie", details: "mglMovie.preAllocateBuffers: fps=\(fps)")

        // now try to preallocate space in frameTimes gracefully
        // if anything returns nil then reserveCapacity will nto be set.
        if let duration = self.duration, duration.seconds.isFinite && duration.seconds > 0 && fps > 0 {
            // Compute expected frames
            let expectedFrameCount = Int(ceil(duration.seconds * Double(fps)))
            
            // Allocate 1.5x to be safe
            let reserveCount = Int(Double(expectedFrameCount) * 1.5)
            //frameTimes.reserveCapacity(reserveCount)
            
            logger?.info(
                component: "mglMovieCommand",
                details: "Preallocated \(reserveCount) frameTimes 1.5x(duration=\(duration.seconds)s, fps=\(fps))"
            )
        }
        
        // various things that should get video decoding
        if let playerItem = self.playerItem {
            // also, try to buffer some video for quick startup
            playerItem.preferredForwardBufferDuration = 1.0
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            // try to decode one frame to trigger startup
            _ = videoOutput.hasNewPixelBuffer(forItemTime: .zero)
            // seek to beginning of video
            player?.pause()
            player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            logger?.info(
                component: "mglMovieCommand",
                details: "preloading video for quick startup"
            )
        }

    }
    

    // draw:Frame This will get called every frame (by way of the
    // mglMoviePlay function
    func drawFrame(
        logger: mglLogger,
        view: MTKView,
        colorRenderingState: mglColorRenderingState,
        renderEncoder: MTLRenderCommandEncoder
    ) -> (didDrawFrame: Bool, frameTime: CMTime?) {

        // check if video has ended
        if videoAtEnd {
            logger.info(component: "mglMovieCommand", details: "Video is over")
            return (false, nil)
        }
        
        // get frame and frameTime
        let (frame, frameTime) = getCurrentFrameAsTexture(hostTime: CACurrentMediaTime())
        
        // if it is a new frame, then update the currentVideoFrame which is displaying
        if frame != nil  {
            currentVideoFrame = frame
            let displayTime = CMTimeGetSeconds(frameTime ?? CMTime.zero) * 1000
            self.logger?.info(component: "mglMovieCommand:", details: "Got a new frame at time: \(displayTime)")
        }
        
        // display the frame
        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(currentVideoFrame, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        // Nothing for Metal to draw for this command
        return (true, frameTime)
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
            
            // wait for the tracks and duration to load up
            //await playerItem.asset.load(.tracks)
            //await playerItem.asset.load(.duration)
                
            // Create the AVPlayer (handles video + audio)
            let player = AVPlayer(playerItem: playerItem)
            self.player = player
                
        }
    }
    
    // play the video
    func play() {
        // play, clear flag for videoAtEnd
        videoAtEnd = false
        self.player?.play()
    }
    
    // getCurrentFrameAsTexture: will extract a metal texture from
    // AVPlayerItem that corresponds to the current time (usually CACurrentMediaTime())
    // Note that this will return nil if there is no new texture
    func getCurrentFrameAsTexture(hostTime: CFTimeInterval) -> (texture: MTLTexture?, timestamp: CMTime?) {
        
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
            return (nil, nil)
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
            return (nil, nil)
        }
        return (metalTexture, itemTime)
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
        // Extract values from the first video track
        if let track = asset.tracks(withMediaType: .video).first {
            // Frame rate
            let trackFrameRate = track.nominalFrameRate
            self.frameRate = trackFrameRate
            logger?.info(component: "mglMovieCommand", details: "Frame rate: \(trackFrameRate) fps")
            
            // Duration
            let trackDuration = track.timeRange.duration
            self.duration = trackDuration
            logger?.info(component: "mglMovieCommand", details: "Track duration: \(trackDuration.seconds) seconds")
            
            // Total frames
            let frames = Int(trackDuration.seconds * Double(trackFrameRate))
            self.totalFrames = frames
            logger?.info(component: "mglMovieCommand", details: "Total frames: \(frames)")
            
            // Width and height
            let trackSize = track.naturalSize.applying(track.preferredTransform)
            self.width = Int(abs(trackSize.width))
            self.height = Int(abs(trackSize.height))
            logger?.info(component: "mglMovieCommand", details: "Width: \(self.width!), Height: \(self.height!)")
        } else {
            logger?.info(component: "mglMovieCommand", details: "No video track found")
            
            // Clear properties if no track
            self.frameRate = nil
            self.duration = nil
            self.totalFrames = nil
            self.width = nil
            self.height = nil
        }
        
        // List all tracks in one line each
        for track in asset.tracks {
            logger?.info(
                component: "mglMovieCommand",
                details: "Track ID: \(track.trackID), Media type: \(track.mediaType.rawValue), Natural size: \(track.naturalSize.width)x\(track.naturalSize.height), Duration: \(track.timeRange.duration.seconds) seconds"
            )
        }    }
}


