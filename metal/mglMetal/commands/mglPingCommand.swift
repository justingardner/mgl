//
//  mglPingCommand.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/3/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation

class mglPingCommand : mglCommand {
    override func writeQueryResults(
        logger: mglLogger,
        commandInterface : mglCommandInterface
    ) -> Bool {
        return commandInterface.writeCommand(data: mglPing) == mglSizeOfCommandCodeArray(1)
    }
}
