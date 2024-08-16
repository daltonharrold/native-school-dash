//
//  AppDelegate.swift
//  NativeDash Mac App
//
//  Created by Dalton Harrold on 8/15/24.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
}
