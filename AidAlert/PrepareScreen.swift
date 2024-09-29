//
//  PrepareScreen.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/29/24.
//

import SwiftUI

struct PrepareScreen: View {
    init() {
        // Customize the navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBlue  // Set the background color

        // Customize title text attributes
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white,
                                          .font: UIFont.boldSystemFont(ofSize: 24)]

        // Apply the customized appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance  
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 50) {
                    HStack {
                        NavigationButton(title: "YOUR TO-DOS")
                        Spacer()
                        NavigationButton(title: "TOOLKIT")
                    }
                    .padding(.horizontal)
                    .padding(.vertical,30)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, -50) // Reduced padding to reduce space

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Miami, FL")
                            .bold()
                            .font(.title)
                            .padding(.leading)
                        
                        Divider()
                        
                        Text("Plan for hazards")
                            .bold()
                            .font(.title2)
                            .padding(.leading)
                            .padding(.top)

                        ActionButton(title: "View hazard risk")
                    }
                    .padding(.horizontal) // Ensure consistent horizontal padding

                    VStack(alignment: .leading) {
                        Text("Flood Preparation")
                            .bold()
                            .padding(.top)
                            .padding(.leading)

                        Text("Current Preparation Level")
                            .padding(.leading)

                        ProgressView(value: 0.2)
                            .padding()
                        
                        Divider()

                        ActionButton(title: "View plan")
                    }
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .padding() // Consistent padding for this section
                    .padding(.top, -50)
                    
                    VStack(alignment: .leading) {
                        Text("Hurricane Preparation")
                            .bold()
                            .padding(.top)
                            .padding(.leading)

                        Text("Current Preparation Level")
                            .padding(.leading)

                        ProgressView(value: 0.2)
                            .padding()
                        
                        Divider()

                        ActionButton(title: "View plan")
                    }
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .padding() // Consistent padding for this section
                    .padding(.top, -50)
                    
                    VStack(alignment: .leading) {
                        Text("Tornado Preparation")
                            .bold()
                            .padding(.top)
                            .padding(.leading)

                        Text("Current Preparation Level")
                            .padding(.leading)

                        ProgressView(value: 0.2)
                            .padding()
                        
                        Divider()

                        ActionButton(title: "View plan")
                    }
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .padding() // Consistent padding for this section
                    .padding(.top, -50)
                    
                    VStack(alignment: .leading) {
                        Text("Wildfire Preparation")
                            .bold()
                            .padding(.top)
                            .padding(.leading)

                        Text("Current Preparation Level")
                            .padding(.leading)

                        ProgressView(value: 0.2)
                            .padding()
                        
                        Divider()

                        ActionButton(title: "View plan")
                    }
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .padding() // Consistent padding for this section
                    .padding(.top, -50)
                }
            }
            .navigationBarTitle("Prepare", displayMode: .inline) // Makes title inline to reduce space
        }
    }
}

struct NavigationButton: View {
    var title: String

    var body: some View {
        Button(action: {
            // Placeholder for action
        }) {
            Text(title)
                .bold()
                .foregroundColor(.blue)
                .padding()
                .frame(height: 44)
                .frame(maxWidth: .infinity) // Makes sure buttons take equal space
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
        }
    }
}

struct ActionButton: View {
    var title: String
    var isNew: Bool = false

    var body: some View {
        Button(action: {
            // Placeholder for action
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                if isNew {
                    Text("New")
                        .padding(4)
                        .background(Color.red)
                        .cornerRadius(5)
                        .foregroundColor(.white)
                }
            }
        }
        .bold()
        .foregroundColor(.blue)
        .padding()
        .background(Color.blue)
        .cornerRadius(8)
        .padding([.horizontal, .top, .bottom])
    }
}

struct PrepareScreen_Previews: PreviewProvider {
    static var previews: some View {
        PrepareScreen()
    }
}
