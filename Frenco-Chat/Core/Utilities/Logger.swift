//
//  Logger.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-08.
//

import Foundation
import os

enum Log {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Frenco", category: "App")
    
    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message)")
        #endif
    }
    
    static func error(_ message: String) {
        logger.error("\(message)")  // Always log errors
    }
}
