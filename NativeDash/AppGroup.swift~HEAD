//
//  AppGroup.swift
//  NativeDash
//
//  Created by Dalton Harrold on 1/4/24.
//

import Foundation

public enum AppGroup: String {
    case dashManaged = "group.com.icloud-djharrold53.NativeDash"
    
    public var containerURL: URL {
        switch self {
        case .dashManaged:
            return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.rawValue)!
        }
    }
}
