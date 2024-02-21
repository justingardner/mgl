//
//  mglGetErrorMessageCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation

class mglGetErrorMessageCommand : mglCommand {
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        // Our mgl logger remembers the last error message!
        _ = commandInterface.writeString(data: logger.getErrorMessage())
        return true
    }
}
