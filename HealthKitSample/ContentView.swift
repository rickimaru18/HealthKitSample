//
//  ContentView.swift
//  HealthKitSample
//
//  Created by Rick Krystianne Lim on 4/7/21.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    var body: some View {
        TabView {
            StepsView().tabItem {
                Image(systemName: "figure.walk")
                Text("Steps")
            }
            ECGView().tabItem {
                Image(systemName: "heart.fill")
                Text("ECG")
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
