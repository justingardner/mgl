//
//  mglRepeatFlushCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import MetalKit

class mglRepeatFlushCommand : mglCommand {
    private let repeatCount: UInt32

    init(repeatCount: UInt32, objectCount: UInt32, randomSeed: UInt32) {
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }

    init?(commandInterface: mglCommandInterface) {
        guard let repeatCount = commandInterface.readUInt32() else {
            return nil
        }
        self.repeatCount = repeatCount
        super.init(framesRemaining: Int(repeatCount))
    }
}
