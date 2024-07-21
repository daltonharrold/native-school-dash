//
//  NativeDash_Mac_AppApp.swift
//  NativeDash Mac App
//
//  Created by Dalton Harrold on 7/20/24.
//

import SwiftUI

@main
struct NativeDash_Mac_App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                .frame(width: 400)
        }
        .windowResizability(.contentSize)
    }
}
