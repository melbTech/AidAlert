//
//  MapScreen.swift
//  AidAlert
//
//  Created by Melvin Santos on 9/29/24.
//

import SwiftUI
import MapKit
import CoreLocation


// View model for managing the user's location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default (San Francisco)
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Initial zoom level
    )
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            //Update region to the user's current location
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

struct Shelter: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isFullScreen = false
        
    let shelterLocations = [
        Shelter(name: "Shelter 1", coordinate: CLLocationCoordinate2D(latitude: 37.7793, longitude: -122.4193)),
        Shelter(name: "Shelter 2", coordinate: CLLocationCoordinate2D(latitude: 37.7814, longitude: -122.4171)),
        Shelter(name: "Shelter 3", coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4181))
    ]
        
    var body: some View {
        NavigationView {
            VStack {
                // Title
                Text("Shelters Nearby")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                //Placeholder for the map
                ZStack {
                    Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: shelterLocations) { shelter in
                        MapMarker(coordinate: shelter.coordinate, tint: .blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : 300) // Fullscreen toggle
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isFullScreen.toggle() //Toggle Fullscreen
                                }
                            }) {
                                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .padding(10)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                .cornerRadius(isFullScreen ? 0 : 10) // No corner radius in fullscreen
                .padding(isFullScreen ? 0 : 16)
                
                if !isFullScreen {
                    // List of shelters
                    List(shelterLocations) {
                        shelter in
                        Text(shelter.name)
                    }
                    .listStyle(PlainListStyle())
                    .padding(.bottom)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    MapScreen()
}
