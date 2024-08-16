//
//  AppGroup.swift
//  NativeDash
//
//  Created by Dalton Harrold on 2/8/24.
//

import Foundation

public enum AppGroup: String {
    case dashManagement = "group.com.icloud-djharrold53.NativeDash"
    
    public var containerURL: URL {
        switch self {
        case .dashManagement:
            #if os(macOS)
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: (Bundle.main.object(forInfoDictionaryKey: "LSEnvironment") as! Dictionary<String, String>)["TEAM_IDENTIFIER_PREFIX"]! + "com.icloud-djharrold53.NativeDash")!
            #else
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.rawValue)!
            #endif
        }
    }
}
