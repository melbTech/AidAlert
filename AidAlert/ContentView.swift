//
//  ContentView.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/28/24.
//

import SwiftUI

struct ContentView: View {
    init() {
        // Customize TabView background color
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = UIColor.systemGray6 // Slightly darker color
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView {
            ChatScreen()
                .tabItem {
                    Image(systemName: "brain")
                    Text("AidAI")
                        .background(Color.blue.opacity(0.1))
                }
            PrepareScreen()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Prepare")
                }
            AlertScreen()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Alert")
                }
            MapScreen()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            MoreScreen()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

