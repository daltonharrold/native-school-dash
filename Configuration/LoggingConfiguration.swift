//
//  LoggingConfiguration.swift
//  NativeDash
//
//  Created by Dalton Harrold on 7/13/24.
//

import OSLog

extension Logger {
    /// Use bundle identifier for uniqueness
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs any information or errors that result from using network requests or fetching
    static let fetch = Logger(subsystem: subsystem, category: "fetch")
    
    /// Logs any  information or errors that result from trying to use Core Data database
    static let coreData = Logger(subsystem: subsystem, category: "coreData")
    
    /// Logs any  information or errors from WidgetKit Widget-related code
    static let widget = Logger(subsystem: subsystem, category: "widget")
    
    /// Logs any  information or errors from Background Proccess scheduling or execution specifically related to background processes
    /// Errors and logs resulting form an action a background process started will be logged in that category.
    static let background = Logger(subsystem: subsystem, category: "background")
    
    /// Used for logging any other errors.
    /// Any Messages logged using this API should specify what the system was doing when the error was encountered.
    static let other = Logger(subsystem: subsystem, category: "other")
}


//Logger.viewCycle.info("Info example")
//Logger.viewCycle.info("Debug example")
//Logger.viewCycle.trace("Trace example")
//Logger.viewCycle.warning("Warning example")
//Logger.viewCycle.error("Error example")
//Logger.viewCycle.fault("Fault example")
//Logger.viewCycle.critical("Critical example")
