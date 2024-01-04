//
//  mglLogger.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 1/4/24.
//  Copyright © 2024 GRU. All rights reserved.
//

import Foundation
import OSLog

protocol mglLogger {
    func info(component: String, details: String)
    func error(component: String, details: String)
    func getErrorMessage() -> String
}

// Apple is migrating logging apis, so check version and return the preferred implementation.
// https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code
func getMglLogger() -> mglLogger {
    if #available(macOS 11.0, *) {
        return mglMacOs11PLusLogger()
    } else {
        return mglLegacyLogger()
    }
}

@available(macOS 11.0, *)
private class mglMacOs11PLusLogger : mglLogger {
    private let logger = Logger()
    private var lastErrorMessage: String = "(mglMacOs11PLusLogger) No errors logged yet."

    func info(component: String, details: String) {
        logger.info("(\(component, privacy: .public)) \(details, privacy: .public)")
    }

    func error(component: String, details: String) {
        lastErrorMessage = "(\(component)) \(details)"
        logger.error("(\(component, privacy: .public)) \(details, privacy: .public)")
    }

    func getErrorMessage() -> String {
        return lastErrorMessage
    }
}

private class mglLegacyLogger : mglLogger {
    private var lastErrorMessage: String = "(mglLegacyLogger) No errors logged yet."

    func info(component: String, details: String) {
        os_log("(%{public}@) %{public}@", log: .default, type: .info, component, details)
    }

    func error(component: String, details: String) {
        lastErrorMessage = "(\(component)) \(details)"
        os_log("(%{public}@) %{public}@", log: .default, type: .error, component, details)
    }

    func getErrorMessage() -> String {
        return lastErrorMessage
    }
}
