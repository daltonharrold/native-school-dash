//
//  DashWidgetsBundle.swift
//  DashWidgets
//
//  Created by Dalton Harrold on 2/8/24.
//

import WidgetKit
import SwiftUI

@main
struct DashWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        EndTimeWidget()
    }
}
