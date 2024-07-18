//
//  NativeDashApp.swift
//  NativeDash Watch App
//
//  Created by student on 9/13/23.
//

import SwiftUI
import WatchKit

@main
struct NativeDash_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: WatchAppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
