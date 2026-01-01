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
import CoreMedia

// Error codes
enum movieError {
    static let fileNotFound = -1.0
    static let noPermission  = -2.0
    static let invalidFormat = -3.0
    static let readVertex = -4.0
    static let movieCreate = -5.0
    static let addMovie = -6.0
}

//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// command to create a movie
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglMovieCreateCommand : mglCommand {

    private var movie: mglMovie? = nil
    var movieNumber: UInt32 = 0
    var movieCount: UInt32 = 0
    var movieFilename: String = ""
    var returnStatus: Double = 1.0

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
        // call super
        super.init()

        // Read the movie filename
        movieFilename = commandInterface.readString()
        logger.info(component: "mglMovie", details: "mglMovieCreateCommand: \(movieFilename)")
        
        // Read the vertex information for the movie
        guard let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: device, extraVals: 2) else {
            returnStatus = movieError.readVertex
            return
        }
        logger.info(component: "mglMovie", details: "mglMovieCreateCommand: Read \(vertexCount) vertices")
        
        guard FileManager.default.fileExists(atPath: movieFilename) else {
            logger.error(component: "mglMovie:", details: "Movie file not found at path \(movieFilename)")
            returnStatus = movieError.fileNotFound
            return
        }
        guard FileManager.default.isReadableFile(atPath: movieFilename) else {
            logger.error(component: "mglMovie:",
                          details: "No read permission for file at path \(movieFilename)")
            returnStatus = movieError.noPermission
            return
        }
        // create the movie class
        guard let movie = mglMovie(movieFilename: movieFilename, vertexCount: vertexCount, vertexBufferTexture: vertexBufferTexture, device: device, logger: logger) else {
            returnStatus = movieError.movieCreate
            return
        }
        self.movie = movie
    }
    
    // this gets called after initialization, instead of drawing, we
    // just log the loaded movie
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        // check if we have a movie initialize
        guard let movie = self.movie else {
            return true
        }
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
        
        // return an error if we have one
        if returnStatus < 0 {
            // write the error
            _ = commandInterface.writeDouble(data: returnStatus)
            return true
        }
           
        // return an error if movieNumber did not return a valid value
        if (movieNumber < 1) {
            // write the error
            _ = commandInterface.writeDouble(data: movieError.addMovie)
            return true
        }
        
        // Get the movie
        guard let movie = self.movie else {
            _ = commandInterface.writeDouble(data: movieError.movieCreate)
            return true
        }
        // if the movie is ready, then send back its info
        if movie.ready {
            // return success as 2.0, to indicate sending data
            _ = commandInterface.writeDouble(data: 2.0)
            // send movie data
            _ = commandInterface.writeDouble(data: Double(movie.frameRate ?? 0))
            _ = commandInterface.writeDouble(data: CMTimeGetSeconds(movie.duration ?? CMTime.zero))
            _ = commandInterface.writeUInt32(data: UInt32(movie.totalFrames ?? 0))
            _ = commandInterface.writeUInt32(data: UInt32(movie.width ?? 0))
            _ = commandInterface.writeUInt32(data: UInt32(movie.height ?? 0))

        }
        else {
            // return success
            _ = commandInterface.writeDouble(data: 1.0)
        }

        // Return movieNumber and movieCount
        _ = commandInterface.writeUInt32(data: movieNumber)
        _ = commandInterface.writeUInt32(data: movieCount)
        
        return true
    }

}
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// play command
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglMoviePlayCommand : mglCommand {
    var movieNumber: UInt32 = 0
    var movie: mglMovie? = nil
    var videoAtEnd: Bool = false
    var nFrames: Int = 0

    // arrays for hold ing timestamps. drawFrameTimes is the CPU time at which
    // draw is called. targetPresentationTimestamps is returned by CAMetalDisplayLink
    // as the target time for frame presentation and movieTimes is the time in
    // the video that is displayed each frame
    var drawFrameTimes: [Double] = []
    var targetPresentationTimestamps: [Double] = []
    var movieTimes: [Double] = []

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
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
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
            
            // preallocate space for timestamp buffers
            preallocateBuffers(view: view, logger: logger)
            
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
        targetPresentationTimestamp: CFTimeInterval?,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {

        // if video is finished playing, then just return
        if videoAtEnd == true {

            // check to make that we have valid timestamps
            if presentedTimes.indices.contains(nFrames-1) &&
                (presentedTimes[nFrames-1].presentedTime) != -1  {
                // we have the last presented times
                return true
            }
            // we do not yet have the last presetned time, so wait another frame
            self.framesRemaining += 1
            return true
        }

        // draw video frame
        var didDrawFrame = false
        if let movie = self.movie {
            let (frameDrawn, movieTime) = movie.drawFrame(
                logger: logger,
                view: view,
                colorRenderingState: colorRenderingState,
                targetPresentationTimestamp: targetPresentationTimestamp,
                renderEncoder: renderEncoder
            )
            // keep returned values
            didDrawFrame = frameDrawn
            movieTimes.append(movieTime.map { CMTimeGetSeconds($0) } ?? -1)
            targetPresentationTimestamps.append( targetPresentationTimestamp ?? -1)
            drawFrameTimes.append(CACurrentMediaTime())
        }
        
        if didDrawFrame {
            // frame drawn, so keep going
            self.framesRemaining += 1
            self.nFrames += 1
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
        let presentedTimesSeconds: [Double] = presentedTimes.map { $0.presentedTime }
        _ = commandInterface.writeDoubleArray(data: Array(presentedTimesSeconds.prefix(nFrames)))
        
        // return movieTimes
        _ = commandInterface.writeDoubleArray(data: Array(movieTimes.prefix(nFrames)))
        
        // return the targetPresentationTimes
        _ = commandInterface.writeDoubleArray(data: Array(targetPresentationTimestamps.prefix(nFrames)))
        
        // return the draw frame times
        _ = commandInterface.writeDoubleArray(data: Array(drawFrameTimes.prefix(nFrames)))


        return true
    }
    
    func preallocateBuffers(view: MTKView, logger: mglLogger?) {
        // preallocate buffer for keeping frame times, first we will
        // need to know the maximum frame rate. Default to 120 fps
        // for systems that do not report
        var fps: Int = 120
        if let screen = view.window?.screen {
            if #available(macOS 12.0, *) {
                fps = screen.maximumFramesPerSecond
            }
        }

        // now try to preallocate space in frameTimes gracefully
        // if anything returns nil then reserveCapacity will nto be set.
        if let duration = movie?.duration, duration.seconds.isFinite && duration.seconds > 0 && fps > 0 {
            // Compute expected frames
            let expectedFrameCount = Int(ceil(duration.seconds * Double(fps)))
            
            // Allocate 1.5x to be safe
            let reserveCount = Int(Double(expectedFrameCount) * 1.5)
            
            // reserve the capacity
            drawFrameTimes.reserveCapacity(reserveCount)
            targetPresentationTimestamps.reserveCapacity(reserveCount)
            presentedTimes.reserveCapacity(reserveCount)
            movieTimes.reserveCapacity(reserveCount)
            
            
            logger?.info(
                component: "mglMovie",
                details: "Preallocated \(reserveCount) 1.5x(duration=\(duration.seconds)s, fps=\(fps))"
            )
        }
        

    }

}

//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// draw frame command
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglMovieDrawFrameCommand : mglCommand {
    var movieNumber: UInt32 = 0
    var movie: mglMovie? = nil
    var movieTime: CMTime?
    var videoAtEnd: Bool = false

    init?(commandInterface: mglCommandInterface, logger: mglLogger) {
        // Read the moveNumber
        guard let movieNumber = commandInterface.readUInt32() else {
            return nil
        }
        self.movieNumber = movieNumber
        logger.info(component: "mglMovie", details: "mglMovieDrawFrameCommand: Read movieNumber: \(movieNumber)")
        
        // call super
        super.init(framesRemaining: 1)
    }
    
    // this gets called after initialization, we get the movie from the movieNum
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
    ) -> Bool {
        
        // retrieve movie
        guard let movie = colorRenderingState.getMovie(
            movieNumber: self.movieNumber
        ) else {
            logger.error(component: "mglMovie", details: "mglMovieDrawFrame: Failed to get movie \(self.movieNumber)")
            return false
        }
        
        // keep movie and start it playing
        self.movie = movie
        if let movie = self.movie, !movie.isPlaying() {
            movie.play()
            logger.error(component: "mglMovie", details: "mglMovieDrawFrame: Playing movie")
        }
        return true
    }
    
    // draw: This will get called from mglRenderer when it is ready to draw a frame of the movie
    override func draw(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?,
        renderEncoder: MTLRenderCommandEncoder
    ) -> Bool {

        logger.info(component: "mglMovie", details: "mglMovieDrawFrame: drawFrame")
        var didDrawFrame = false
        if let movie = self.movie {
            let (frameDrawn, movieTime) = movie.drawFrame(
                logger: logger,
                view: view,
                colorRenderingState: colorRenderingState,
                targetPresentationTimestamp: targetPresentationTimestamp,
                renderEncoder: renderEncoder
            )
            // keep returned values
            didDrawFrame = frameDrawn
            self.movieTime = movieTime
        }
        
        if !didDrawFrame {
            // video is over
            videoAtEnd = true
        }
        return true
    }
    
    // this is used to return the movieTime
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {

        // return frameTime or -1 if it does not exists (was not drawn)
        _ = commandInterface.writeDouble(data: movieTime.map { CMTimeGetSeconds($0) } ?? -1)

        return true
    }

}

//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// movie status command
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
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
        self.movieNumber = movieNumber

        // call super
        super.init()
    }
    
    // this gets called after initialization, we get the movie from the movieNum
    override func doNondrawingWork(
        logger: mglLogger,
        view: MTKView,
        depthStencilState: mglDepthStencilState,
        colorRenderingState: mglColorRenderingState,
        renderer: mglRenderer2,
        deg2metal: inout simd_float4x4,
        targetPresentationTimestamp: CFTimeInterval?
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

        // get movie
        guard let movie = self.movie else {
            // no movie is an error
            _ = commandInterface.writeDouble(data: -1)
            return true
        }
        
        if movie.ready {
            // return succes
            _ = commandInterface.writeDouble(data: 1.0)
            // IF we are ready, return info about video
            _ = commandInterface.writeDouble(data: Double(movie.frameRate ?? 0))
            _ = commandInterface.writeDouble(data: CMTimeGetSeconds(movie.duration ?? CMTime.zero))
            _ = commandInterface.writeUInt32(data: UInt32(movie.totalFrames ?? 0))
            _ = commandInterface.writeUInt32(data: UInt32(movie.width ?? 0))
            _ = commandInterface.writeUInt32(data: UInt32(movie.height ?? 0))
        }
        else {
            // return not ready
            _ = commandInterface.writeDouble(data: 0.0)
        }

        return true
    }

}


//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
// class that holds the movie, AVPlayer and all the stuff needed
// to make the movie run
//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++//++
class mglMovie : NSObject {
    // this will be set to true when the movie is ready for playback
    var ready = false
    
    // Keep references to the AVPlayer and AVPlayerItem
    // which carry the player and the movie
    private var player: AVPlayer?
    var playerItem: AVPlayerItem?
    
    // these are for rendering each frame from the AVPlayerItem
    private var videoOutput: AVPlayerItemVideoOutput
    private var textureCache: CVMetalTextureCache
    private var device: MTLDevice?
    
    // Keep around a pointer to the mglLogger for debugging info
    private var logger: mglLogger?
    
    // sampler state for displaying
    private var samplerState: MTLSamplerState!

    // texture representing the current video frame that is displaying
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
    
    // whether the movie is valid or not
    var validMovie: Bool?
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // init. This will be called by mglCommandInterface when
    // it receives a command from python/matlab. It should
    // initialize the movie and the display layer
    //..//..//..//..//..//..//..//..//..//..//..//..//
    init?(movieFilename: String, vertexCount: Int, vertexBufferTexture: MTLBuffer, device: MTLDevice, logger: mglLogger) {
        
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
        
        // init super
        super.init()

        // load the video
        self.validMovie = self.load(movieFilename: movieFilename)
        if validMovie == nil {
            return nil
        }

        // add the videoOutput to the playerItem which should
        // now be allocated from load
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
    
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // remember to remove observer if this variable is removed
    //..//..//..//..//..//..//..//..//..//..//..//..//
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    //..//..//..//..//..//..//..//..//..//..//..//..//
    // function which gets called if the movie ends
    //..//..//..//..//..//..//..//..//..//..//..//..//
    @objc private func movieDidEnd() {
        videoAtEnd = true
        // seek video to beginning (so it can be replayed)
        self.player?.seek(to: .zero)
    }

    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // try to preload video and preallocate buffers for faster start
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func preload(view: MTKView) {
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
        }
    }
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // load the video, creating an AVPlayerItem for the video and an AVPlayer which
    // manages playing of the video
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func load(movieFilename: String) -> Bool {
        
        if player == nil {
            
            // get the videoAsset from the filename
            let movieURL = URL(fileURLWithPath: movieFilename)
            let videoAsset = AVURLAsset(url: movieURL)
                
            // Create a player item from the file
            let playerItem = AVPlayerItem(asset: videoAsset)
            self.playerItem = playerItem

            // Now, we are going to check for tracks and duration asynchronously
            let keys = ["tracks", "duration"]
            videoAsset.loadValuesAsynchronously(forKeys: keys) {
                // check the keys
                var error: NSError?
                for key in keys {
                    let status = videoAsset.statusOfValue(forKey: key, error: &error)
                    if status != .loaded {
                        self.logger?.error(component: "mglMovie", details: "Failed to load \(key): \(error?.localizedDescription ?? "unknown")")
                        return
                    }
                }
                
                // Extract info
                self.info(asset: videoAsset, logger: self.logger)
                
                // All keys and info should be loaded now, so return true
                self.ready = true
            }

            // Create the AVPlayer (handles video + audio)
            let player = AVPlayer(playerItem: playerItem)
            self.player = player
            
        }
        return true
    }
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // check if playing
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func isPlaying() -> Bool {
        if self.player?.timeControlStatus == .playing {
            return true
        }
        return false
    }

    //..//..//..//..//..//..//..//..//..//..//..//..//
    // play the video
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func play() {
        // play, clear flag for videoAtEnd
        videoAtEnd = false
        // and play
        self.player?.play()
    }
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // draw:Frame This will get called every frame (by way of the
    // mglMoviePlay function
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func drawFrame(
        logger: mglLogger,
        view: MTKView,
        colorRenderingState: mglColorRenderingState,
        targetPresentationTimestamp: CFTimeInterval?,
        renderEncoder: MTLRenderCommandEncoder
    ) -> (didDrawFrame: Bool, movieTime: CMTime?) {

        // check if video has ended
        if videoAtEnd {
            return (false, nil)
        }
        
        // Use targetPresentationTimestamp if it is avaialable. This is what CAMetalDIsplayLink
        // gives us as the target time at which the frame will display, which is more accurate.
        // If that does not exist, fall back to CACUrrentMediaTime()
        let hostTime = targetPresentationTimestamp ?? CACurrentMediaTime()
        
        // get frame and movieTime
        let (frame, movieTime) = getCurrentFrameAsTexture(hostTime: hostTime)
        
        // if it is a new frame, then update the currentVideoFrame which is displaying
        if frame != nil  {
            currentVideoFrame = frame
        }
        
        // display the frame
        renderEncoder.setRenderPipelineState(colorRenderingState.getTexturePipelineState())
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)
        renderEncoder.setFragmentTexture(currentVideoFrame, index:0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        // Nothing for Metal to draw for this command
        return (true, movieTime)
    }
    
    //..//..//..//..//..//..//..//..//..//..//..//..//
    // getCurrentFrameAsTexture: will extract a metal texture from
    // AVPlayerItem that corresponds to the current time (usually CACurrentMediaTime())
    // Note that this will return nil if there is no new texture
    //..//..//..//..//..//..//..//..//..//..//..//..//
    func getCurrentFrameAsTexture(hostTime: CFTimeInterval) -> (texture: MTLTexture?, timestamp: CMTime?) {
        
        // get the itemTime corresponding to the current hostTime
        let itemTime = videoOutput.itemTime(forHostTime: hostTime)

        // Check for a new frame, return nil if there is nothing
        // itemTimeForDisplay is what videoOutput gives us back as
        // the time the frame should be displayed at (rather that
        // what we asked for which is itemTime
        var itemTimeForDisplay = CMTime.invalid
        guard videoOutput.hasNewPixelBuffer(forItemTime: itemTime),
              let pixelBuffer = videoOutput.copyPixelBuffer(
                    forItemTime: itemTime,
                    itemTimeForDisplay: &itemTimeForDisplay
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

        // if successful, return the texture and itemTimeForDisplay
        guard status == kCVReturnSuccess,
              let metalTexture = CVMetalTextureGetTexture(cvTexture!)
        else {
            return (nil, nil)
        }
        return (metalTexture, itemTimeForDisplay)
    }

    //..//..//..//..//..//..//..//..//..//..//..//..//
    // info: Extracts information like frame rate, length, native pixel
    // dimensions from AV file.
    //..//..//..//..//..//..//..//..//..//..//..//..//
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
        }
    }
}


