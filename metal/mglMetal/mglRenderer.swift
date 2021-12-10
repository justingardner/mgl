//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglRenderer.swift
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
import Foundation
import MetalKit
import AppKit

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// mglRenderer: Class does most of the work
// handles initializing of the GPU, pipeline states etc
// handles the frame updates and drawing as well as resizing
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class mglRenderer: NSObject {
    // GPU Device
    static var device : MTLDevice!
    // commandQueue which tells the device what to do
    static var commandQueue: MTLCommandQueue!
    // Mesh contains the models - i.e. vertices / triangles that will be drawn
    var mesh: MTKMesh!
    // Conversion of mesh into metal vertices
    var vertexBuffer: MTLBuffer!
    // pipeline contains the shaders and other information
    // that define the pipeline of the GPU renderer
    var pipelineState: MTLRenderPipelineState!
    
    // Pipeline states for rendering different things
    var pipelineStateDots: MTLRenderPipelineState!
    var pipelineStateVertexWithColor: MTLRenderPipelineState!
    var pipelineStateTextures: MTLRenderPipelineState!

    // variable to hold mglCommunicator which
    // communicates with matlab
    var commandInterface : mglCommandInterface
    
    // sets whether to send a flush confirm back to matlab
    var acknowledgeFlush = false

    // sets whether to wait each flush for commands from matlab
    var blocking = false

    // keeps coordinate xform
    var deg2metal = matrix_identity_float4x4
    
    var texture : MTLTexture!
    
    // Set to not provide profiling information
    var profile = false
    var secs = mglSecs()
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // init
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    init(metalView: MTKView) {
        // init mglCommunicator
        commandInterface = mglCommandInterface()
        
        // Initialize the GPU device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("GPU not available")
        }
        // tell the view aand renderer about the device
        metalView.device = device
        mglRenderer.device = device

        // initialize the command queue
        mglRenderer.commandQueue = device.makeCommandQueue()!
        
        // create a cube - for testing
        let mdlMesh = mglPrimitive.cube(device: device, size: 1.0)
        mesh = try! MTKMesh(mesh: mdlMesh, device: device)
        vertexBuffer = mesh.vertexBuffers[0].buffer
        
        // create a library for storing the shaders
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        // create the pripeline descriptor which describes
        // the shaders and other things necessary for defining
        // the drawing state of the GPU
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        // This describes how the vertices should be interpreted by the GPU
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        // this describes the pixel format that will be used
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        // Turn on alpha blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled             = true;
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation           = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation         = MTLBlendOperation.add;
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor        = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor      = MTLBlendFactor.sourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor   = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        
        // Ok. Now tell the GPU about this to make a pipeline state
        // which can be used for rendering
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        // Set up a pipelineState for rendering dots
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_dots")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_dots")
        // Setup the pipeline with the device
        do {
            pipelineStateDots = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // Set up a pipelineState for rendering textures
        // add attribute for texture coordinates
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 5 * MemoryLayout<Float>.size

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_textures")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_textures")
        // Setup the pipeline with the device
        do {
            pipelineStateTextures = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // add attribute for color
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 3 * MemoryLayout<Float>.size
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = 6 * MemoryLayout<Float>.size

        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_with_color")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_with_color")
        // Setup the pipeline with the device
        do {
            pipelineStateVertexWithColor = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        // init the super class
        super.init()
        
        // Set the clear color for the view
        metalView.clearColor = MTLClearColor(red: 0.5, green: 0.5,
                                             blue: 0.5, alpha: 1)
        // Tell the view that this class will be used as the
        // delegate - this makes it so that the view will call
        // the draw function each frame update and the resize function
        metalView.delegate = self
        
        // Done. Print out that we did something.
        print("(mglMetal:mglRenderer) Init mglRenderer")
    }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// mtkViewDelegate: adds functionality to take care of
// resizing screen or frame updates
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
extension mglRenderer: MTKViewDelegate {
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // mtkView delegate function that runs when drawable size changes
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("(mglMetal:mglRenderer) drawableSizeWillChange \(size)")

    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // darw delegate which does all the work! Run every frame buffer update
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func draw(in view: MTKView) {
        // Check if a client connection is already accepted, or try to accept a new one.
        let clientIsConnected = commandInterface.acceptClientConnection()
        if !clientIsConnected {
            // Nothing to do if client isn't connected.  We'll try again on the next draw.
            return
        }

        if acknowledgeFlush {
            // send flush acknowledge
            _ = commandInterface.writeDouble(data:0)
            acknowledgeFlush = false
            print("(mglRenderer:draw) Sending flush acknowledge")
        }
        
        // Get the commandBuffer and renderEncoder
        guard let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                  return
              }
        
        // set deg2metal in renderEncoder
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)

        // check matlab command queue
        var readCommands = true
        while readCommands {
            if commandInterface.dataWaiting() {
                let command = commandInterface.readCommand()
                switch command {
                case mglPing: print("ping")
                case mglClearScreen: clearScreen(view : view, renderEncoder: renderEncoder)
                case mglDots: dots(view: view, renderEncoder: renderEncoder)
                case mglCreateTexture: createTexture(view: view, renderEncoder: renderEncoder)
                case mglBltTexture: bltTexture(view: view, renderEncoder: renderEncoder)
                case mglSetXform: setXform(renderEncoder: renderEncoder)
                case mglLine: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .line)
                case mglQuad: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangle)
                case mglPolygon: drawVerticesWithColor(view: view, renderEncoder: renderEncoder, primitiveType: .triangleStrip)
                case mglFullscreen:
                    fullscreen(view: view, renderEncoder: renderEncoder)
                    readCommands = false
                case mglWindowed:
                    windowed(view: view, renderEncoder: renderEncoder)
                    readCommands = false
                case mglTest: test(view: view, renderEncoder: renderEncoder)
                case mglBlocking:
                    blocking = true
                    print("(mglRenderer) Blocking")
                case mglNonblocking:
                    blocking = false
                    print("(mglRenderer) Non-blocking")
                case mglProfileon:
                    profile = true
                case mglProfileoff:
                    profile = false
                case mglFlush:
                    readCommands = false
                    acknowledgeFlush = true
                case mglGetSecs:
                    _ = commandInterface.writeDouble(data: secs.get())
                default:
                    print("(mglRenderer) Unknown command code: \(command)")
                }
                // if we have received any command then kick into blocking wait mode
                blocking = true;
                // if we are in profile mode, then return profiling time
                if profile && (command != mglFlush) {
                    // write current time in mglSecs
                    _ = commandInterface.writeDouble(data: secs.get())
                }
            }
            else {
                if !blocking {
                    // check for important events
                    guard let window = view.window else {return}
                    // if an event is pending, then drop out of this loop
                    //let nextEvent = window.nextEvent(matching: [.mouseEntered, .keyDown, .keyUp, .leftMouseDown, .leftMouseDragged, .leftMouseUp, .appKitDefined, .systemDefined, .applicationDefined])
                    let nextEvent = window.nextEvent(matching: .any)
                    if !(nextEvent == nil) {
                        //print("(mglRenderer) Processing OS events")
                        readCommands = false
                    }
                }
            }
        }

        // end encoding
        renderEncoder.endEncoding()

        // set the drawable, present and commit - should draw after this
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // clearScreen
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func clearScreen(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // get the color
        let color = commandInterface.readColor()
        print(color)
        print(color[0])
        print(color[1])
        print(color[2])
        // Set the clear color for the view
        view.clearColor = MTLClearColor(red: Double(color[0]), green: Double(color[1]), blue: Double(color[2]), alpha: 1)
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dots
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func dots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateDots)

        // Set the point size to use for all vertices.
        var pointSize = commandInterface.readFloat();
        renderEncoder.setVertexBytes(&pointSize, length: MemoryLayout<Float>.size, index: 2);

        // Set the color to use for all dots.
        var color = commandInterface.readColor();
        renderEncoder.setFragmentBytes(&color, length: MemoryLayout<simd_float3>.stride, index: 0)

        // Set the shape to use for all dots.
        var isRound = commandInterface.readUInt32();
        renderEncoder.setFragmentBytes(&isRound, length: MemoryLayout<UInt32>.size, index: 1);

        // read the vertices
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device)
        print("VertexCount: \(vertexCount)")
        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        // and draw them as points
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // bltTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func bltTexture(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateTextures)

        // set up texture sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.repeat
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.repeat
        samplerDescriptor.rAddressMode = MTLSamplerAddressMode.repeat
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)
        
        // add the sampler to the renderEncoder
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        // read the vertices with 2 extra vals for the texture coordinates
        let (vertexBufferTexture, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 2)

        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)

        // send the texture to the renderEncoder
        renderEncoder.setFragmentTexture(texture, index:0)

        // set phase
        var phase = commandInterface.readFloat()
        print("Read phase: \(phase)")
        renderEncoder.setFragmentBytes(&phase, length: MemoryLayout<Float>.stride, index: 2)

        // and draw them as a triangle
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // createTexture
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func createTexture(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateTextures)

        // read in the texture
        texture = commandInterface.readTexture(device: mglRenderer.device)
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // setXform
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func setXform(renderEncoder: MTLRenderCommandEncoder) {

        // read the new xform
        deg2metal = commandInterface.readXform();
        print(deg2metal)
        
        // set deg2metal in renderEncoder
        renderEncoder.setVertexBytes(&deg2metal, length: MemoryLayout<float4x4>.stride, index: 1)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // drawVerticesWithColor
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func drawVerticesWithColor(view: MTKView, renderEncoder: MTLRenderCommandEncoder, primitiveType: MTLPrimitiveType) {
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateVertexWithColor)
        // read the vertices with 3 extra values for color
        let (vertexBufferWithColors, vertexCount) = commandInterface.readVertices(device: mglRenderer.device, extraVals: 3)
        print("VertexCount: \(vertexCount)")
        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferWithColors, offset: 0, index: 0)
        // and draw them as triangles
        renderEncoder.drawPrimitives(type: primitiveType, vertexStart: 0, vertexCount: vertexCount)

    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // windowed
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func windowed(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        print("windowed")
        // get window variable (if available)
        guard let window = view.window else {
            print("(mglRenderer:windowed) Could not retrieve window")
            return
        }
        // check if already full screen
        if !window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:windowed) Is already windowed")
        }
        else {
            // toggle to windowed
            window.toggleFullScreen(nil)
            var windowFrame = window.frame
            print(windowFrame)
            windowFrame.size = NSMakeSize(400, 400)
            window.setFrame(windowFrame, display: true)
            // unhide curser
            NSCursor.unhide()
        }
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // fullscreen
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func fullscreen(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // get window variable (if available)
        guard let window = view.window else {
            print("(mglRenderer:fullscreen) Could not retrieve window")
            return
        }
        // check if already full screen
        if window.styleMask.contains(.fullScreen) {
            print("(mglRenderer:fullscreen) Is already full screen")
        }
        else {
            // toggle to full screen
            window.toggleFullScreen(nil)
            NSCursor.hide()
        }
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // test
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func test(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        print("Testing")

        if commandInterface.dataWaiting() {
            print("(mglRendere:test) Uhoh data waiting")
        }
        
        guard let window = view.window else {return}
        print(window.styleMask.contains(.fullScreen))
        if window.styleMask.contains(.fullScreen) {
            print("Is full screen")
        }else {
            print("Is not full screen")
        }
        view.window?.toggleFullScreen(nil)
        if window.styleMask.contains(.fullScreen) {
            print("Is full screen")
        }else {
            print("Is not full screen")
        }

        //view.window?.toggleFullScreen(nil)
        //view.window?.alphaValue(0.5)
        //view.window?.isOpage(false)
        /*
         var diffuseTexture : MTLTexture!
         let fileLocation = "file://Users/justin/Library/Containers/gru.mglMetal/Data/texture.png"
         if let textureUrl = NSURL(string: fileLocation) {
         let textureLoader = MTKTextureLoader(device: mglRenderer.device)
         do {
         diffuseTexture =
         try textureLoader.newTexture(
         URL: textureUrl as URL,
         options: nil)
         } catch _ {
         print("diffuseTexture assignment failed")
         }
         }
         renderEncoder.setFragmentTexture(diffuseTexture, index:1)
         print(diffuseTexture)
         */
        /*
         let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
         let textureLoader = MTKTextureLoader(device: mglRenderer.device)
         let baseColorTexture = try? textureLoader.newTexture(name: "texture", scaleFactor: 1.0, bundle: nil, options: options)
         print(baseColorTexture!)
         renderEncoder.setFragmentTexture(baseColorTexture, index:2)
         */
        /*
         struct SkySettings {
         var turbidity: Float = 0.28
         var sunElevation: Float = 0.6
         var upperAtmosphereScattering: Float = 0.1
         var groundAlbedo: Float = 4
         }
         var skySettings = SkySettings()
         var theskytexture: MTLTexture?
         var dimensions = [256, 256]
         let skyTexture = MDLSkyCubeTexture(name: "sky",channelEncoding: .uInt8, textureDimensions: [256, 256], turbidity: skySettings.turbidity, sunElevation: skySettings.sunElevation, upperAtmosphereScattering:skySettings.upperAtmosphereScattering, groundAlbedo: skySettings.groundAlbedo)
         do {
         let textureLoader =
         MTKTextureLoader(device: mglRenderer.device)
         theskytexture = try textureLoader.newTexture(texture: skyTexture, options: nil)

         }
         catch {
         print(error.localizedDescription)
         }
         print(theskytexture)
         */
        /*              // TODO: Setup vertex and fragment shaders
         renderEncoder.setFragmentTexture(theskytexture, index:1)
         */
        // set the renderEncoder pipeline state
        //renderEncoder.setRenderPipelineState(pipelineState)

        // Give it our vertices
        //renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        //for submesh in mesh.submeshes {renderEncoder.drawIndexedPrimitives(type: .triangle,indexCount: submesh.indexCount,indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
        //}
        // done
        //renderEncoder.endEncoding()
        // print vertices out (for debugging)
        //do {
        //    let rawPointer = vertexBufferDots.contents()
        //    let typedPointer = rawPointer.bindMemory(to: Float.self, capacity: vertexCount * 3)
        //    let bufferPointer = UnsafeBufferPointer<Float>(start: typedPointer, count: vertexCount * 3)
        //    for (index, value) in bufferPointer.enumerated() {
        //        print("Vertex value: \(index): \(value)")
        //   }
        //}

    }

}
