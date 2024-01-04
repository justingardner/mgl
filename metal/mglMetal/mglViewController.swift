//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  ViewController.swift
//  mglMetal
//
//  Created by justin gardner on 12/28/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
import Cocoa
import MetalKit

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// ViewController
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
class ViewController: NSViewController {
    // A common logging interface for app components to share.
    let logger = getMglLogger()

    // holds our renderer class which does the main work, initialized during viewDidLoad()
    var renderer: mglRenderer2?

    // Open a connection to the client (eg Matlab)
    // based on a default connection address or an address passed as a command line option:
    //   mglMetal ... -mglConnectionAddress my-address
    func commandInterfaceFromCliArgs() -> mglCommandInterface {
        // Get the connection address to use from the command line
        let arguments = CommandLine.arguments
        let optionIndex = arguments.firstIndex(of: "-mglConnectionAddress") ?? -2
        if optionIndex < 0 {
            logger.info(component: "ViewController", details: "No command line option passed for -mglConnectionAddress, using a default address.")
        }
        let address = arguments.indices.contains(optionIndex + 1) ? arguments[optionIndex + 1] : "mglMetal.socket"
        logger.info(component: "ViewController", details: "Using connection addresss \(address)")

        // In the future we might inspect the address to decide what kind of server to create,
        // like local socket vs internet socket, vs shared memory, etc.
        // For now, we always interpret the address as a file system path for a local socket.
        let server = mglLocalServer(logger: logger, pathToBind: address)
        return mglCommandInterface(logger: logger, server: server)
    }

    // This is called normally from viewDidLoad(), or during testing.
    func setUpRenderer(view: MTKView, commandInterface: mglCommandInterface) {
        renderer = mglRenderer2(logger: logger, metalView: view, commandInterface: commandInterface)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // viewDidLoad
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    override func viewDidLoad() {
        // init metalView
        guard let metalView = view as? MTKView else {
            fatalError("(mglMetal:ViewController:viewDidLoad) Unable to initialize metalView")
        }
        // run the super class function
        super.viewDidLoad()

        // Initialize our renderer - this is the function
        // that handles drawing and where all the action is.
        let commandInterface = commandInterfaceFromCliArgs()
        setUpRenderer(view: metalView, commandInterface: commandInterface)
    }

    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // viewDidLoad
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "mglMetal"
    }
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    // representedObject
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

