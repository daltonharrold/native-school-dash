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
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.rawValue)!
        }
    }
}
