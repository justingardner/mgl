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

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Enum of command codes
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
enum mglCommands : UInt16 {
    case ping = 0
    case clearScreen = 1
    case dots = 2
    case flush = 3
    case test = 4
}
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
    var pipelineStateTextures: MTLRenderPipelineState!

    // variable to hold mglCommunicator which
    // communicates with matlab
    var commandInterface : mglCommandInterface
    
    // sets whether to send a flush confirm back to matlab
    var acknowledgeFlush = false
    
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
        
        if acknowledgeFlush {
            // send flush acknowledge
            commandInterface.writeDouble(data:0)
            acknowledgeFlush = false
            print("(mglRenderer:draw) Sending flush acknowledge")
        }
        
        // Get the commandBuffer and renderEncoder
        guard let descriptor = view.currentRenderPassDescriptor,
        let commandBuffer = mglRenderer.commandQueue.makeCommandBuffer(),
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        // check matlab command queue
        var readCommands = true
        while readCommands {
            if commandInterface.dataWaiting() {
                let command = commandInterface.readCommand()
                switch command {
                    case mglCommands.ping: print("ping")
                    case mglCommands.clearScreen: clearScreen(view : view)
                    case mglCommands.dots: dots(view: view, renderEncoder: renderEncoder)
                    case mglCommands.test: test(view: view, renderEncoder: renderEncoder)
                    case mglCommands.flush:
                        readCommands = false
                        acknowledgeFlush = true
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
    func clearScreen(view: MTKView) {
        // Set the clear color for the view
        view.clearColor = MTLClearColor(red: 0.5, green: 0.4,
                                              blue: 0.8, alpha: 1)

    }
    
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // dots
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func dots(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        // Set the clear color for the view
        view.clearColor = MTLClearColor(red: 0.8, green: 0.4, blue: 0.9, alpha: 1)
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateDots)
        // read the vertices
        let (vertexBufferDots, vertexCount) = commandInterface.readVertices(device: mglRenderer.device)
        print("VertexCount: \(vertexCount)")
        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferDots, offset: 0, index: 0)
        // and draw them as points
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // test
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    func test(view: MTKView, renderEncoder: MTLRenderCommandEncoder) {
        print("Testing")
        // set the pipeline state
        renderEncoder.setRenderPipelineState(pipelineStateTextures)

        // set up sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        let samplerState = mglRenderer.device.makeSamplerState(descriptor:samplerDescriptor)
    
        // add the sampler to the renderEncoder
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)

        // read the vertices
        let (vertexBufferTexture, vertexCount) = commandInterface.readVerticesWithTextureCoordinates(device: mglRenderer.device)
        print("VertexCount: \(vertexCount)")
        // set the vertices in the renderEncoder
        renderEncoder.setVertexBuffer(vertexBufferTexture, offset: 0, index: 0)
        
        // read in the texture and set it into the renderEncoder
        let texture = commandInterface.readTexture(device: mglRenderer.device)
        renderEncoder.setFragmentTexture(texture, index:0)
        // and draw them as a triangle
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)

        if commandInterface.dataWaiting() {
            print("(mglRendere:test) Uhoh data waiting")
        }
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
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        let textureLoader = MTKTextureLoader(device: mglRenderer.device)
        let baseColorTexture = try? textureLoader.newTexture(name: "texture", scaleFactor: 1.0, bundle: nil, options: options)
        print(baseColorTexture!)
        renderEncoder.setFragmentTexture(baseColorTexture, index:2)
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
