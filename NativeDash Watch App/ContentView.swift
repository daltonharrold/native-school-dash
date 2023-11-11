//
//  ContentView.swift
//  NativeDash Watch App
//
//  Created by student on 9/13/23.
//

import SwiftUI

struct ContentView: View {
    @State var timeLeftInPeriod = Duration.seconds(633)
    @State var progress: CGFloat = 0.8
    var body: some View {
        VStack{
            Text("Period 1")
                .font(.title3)
                .fontWeight(.bold)
            Spacer().frame(height: 20)
            // PeriodTimerRing(progress: $progress, timeLeftInPeriod: $timeLeftInPeriod)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
