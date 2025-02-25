//
//  Logging.swift
//  NFCSDK
//
//  Created by OCR Labs on 11/06/2019.
//  Copyright © 2019 OCR Labs. All rights reserved.
//

import Foundation

public enum LogLevel : Int, CaseIterable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
}

public class Log {
    public static var logLevel : LogLevel = .info
    public static var storeLogs = false
    public static var logData = [String]()

    public class func verbose( _ msg : @autoclosure () -> String ) {
        log( .verbose, msg )
    }
    public class func debug( _ msg : @autoclosure () -> String ) {
        log( .debug, msg )
    }
    public class func info( _ msg : @autoclosure () -> String ) {
        log( .info, msg )
    }
    public class func warning( _ msg : @autoclosure () -> String ) {
        log( .warning, msg )
    }
    public class func error( _ msg : @autoclosure () -> String ) {
        log( .error, msg )
    }
    
    public class func clearStoredLogs() {
        logData.removeAll()
    }
    
    class func log( _ logLevel : LogLevel, _ msg : () -> String ) {
        if self.logLevel.rawValue <= logLevel.rawValue {
            let message = msg()
            print( message )
            
            if storeLogs {
                logData.append( message )
            }
        }
    }
}
