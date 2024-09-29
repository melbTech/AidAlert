//
//  ContentView.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/28/24.
//

import SwiftUI

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("hello, world! 🚀🌍🚀")
//        }
//        .padding()
//    }
//}

struct ContentView: View {
    var body: some View {
        TabView {
            MapsView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            
            PrepareView()
                .tabItem {
                    Image(systemName: "shield")
                    Text("Prepare")
                }
            
            AlertsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Alerts")
                }
            
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
        }
        .edgesIgnoringSafeArea(.bottom) // Optional: ignores safe area at the bottom
    }
}

#Preview {
    ContentView()
}
