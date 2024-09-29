//
//  MoreScreen.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/29/24.
//

import SwiftUI

struct MoreScreen: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: ContactsView()) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                        Text("Contacts")
                            .font(.headline)
                    }
                }
                
                NavigationLink(destination: DonateView()) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Donate")
                            .font(.headline)
                    }
                }
                
                NavigationLink(destination: VolunteerView()) {
                    HStack {
                        Image(systemName: "hands.sparkles.fill")
                            .foregroundColor(.green)
                        Text("Volunteer")
                            .font(.headline)
                    }
                }
                
                NavigationLink(destination: ProvideShelterView()) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.orange)
                        Text("Provide Shelter")
                            .font(.headline)
                    }
                }
                
                NavigationLink(destination: FAQView()) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.purple)
                        Text("FAQ")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("More Options")
        }
    }
}

// Placeholder views for each section
struct ContactsView: View {
    var body: some View {
        Text("Contacts")
            .font(.title)
            .padding()
    }
}

struct DonateView: View {
    var body: some View {
        Text("Donate")
            .font(.title)
            .padding()
    }
}

struct VolunteerView: View {
    var body: some View {
        Text("Volunteer")
            .font(.title)
            .padding()
    }
}

struct ProvideShelterView: View {
    var body: some View {
        Text("Provide Shelter")
            .font(.title)
            .padding()
    }
}

struct FAQView: View {
    var body: some View {
        Text("FAQ")
            .font(.title)
            .padding()
    }
}

struct MoreScreen_Previews: PreviewProvider {
    static var previews: some View {
        MoreScreen()
    }
}
