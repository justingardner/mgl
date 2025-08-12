//
//  mglFlushCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 12/22/23.
//  Copyright © 2023 GRU. All rights reserved.
//

import Foundation
import MetalKit

// Flush is the simplest command, acting as a placeholder to tell us when a frame should be presented.
class mglFlushCommand : mglCommand {
    init() {
        super.init(framesRemaining: 1)
    }

    init?(commandInterface: mglCommandInterface) {
        super.init(framesRemaining: 1)
    }
}
