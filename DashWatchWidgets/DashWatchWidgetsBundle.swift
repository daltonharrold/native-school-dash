//
//  DashWatchWidgetsBundle.swift
//  DashWatchWidgetsExtension
//
//  Created by Dalton Harrold on 4/8/24.
//

import SwiftUI
import WidgetKit

@main
struct DashWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
//        TimerWatchWidget()
//        EndTimeWatchWidget()
        TimerWidget()
        EndTimeWidget()
    }
}
