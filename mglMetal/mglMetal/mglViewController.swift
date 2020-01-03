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
    // holds our renderer class which does all the work
    var renderer : mglRenderer?
    
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
        renderer = mglRenderer(metalView: metalView)
        
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

