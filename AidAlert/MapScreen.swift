import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// Place model with emoji icons
struct PlaceAnnotation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let emoji: String
    let address: String
    let phoneNumber: String?
    let isUserLocation: Bool
    let distance: Double // Distance from user's location in miles
    let type: PlaceType // Type of place (shelter, police station, fire station, hospital)
}

enum PlaceType: String, CaseIterable, Identifiable {
    case shelter = "Shelter"
    case police = "Police Station"
    case fireStation = "Fire Station"
    case hospital = "Hospital"
    
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .shelter: return "🏠"
        case .police: return "👮‍♂️"
        case .fireStation: return "🚒"
        case .hospital: return "🏥"
        }
    }
}

// View model for managing the user's location and disaster alerts
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private var sentNotifications = Set<String>() // To track sent notifications
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default (San Francisco)
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1) // Initial zoom level
    )
    @Published var disasterAlert: String? // Track disaster alert messages
    @Published var userLocation: CLLocation? // Track the user's location
    @Published var annotations: [PlaceAnnotation] = [] // Array of place annotations
    @Published var filters: [PlaceType] = PlaceType.allCases // Filters for the types of places to show
    @Published var selectedPlace: PlaceAnnotation? // Currently selected place for zoom-in effect

    var userLocationAnnotation: PlaceAnnotation? // Annotation for the user's location

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Request notification permission
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    // Update user's location and fetch disaster alerts based on new location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            userLocationAnnotation = PlaceAnnotation(name: "Your Location", coordinate: location.coordinate, emoji: "📍", address: "Current Location", phoneNumber: nil, isUserLocation: true, distance: 0, type: .shelter)
            
            // Reverse geocode to get the state and fetch disaster alerts
            getStateFromLocation { state in
                if let state = state {
                    self.fetchDisasterAlerts(for: state)
                }
            }
            
            // Fetch nearby places once the location is updated
            searchNearbyPlaces(in: region)
        }
    }
    
    // Reverse geocode to get the state for the FEMA API
    private func getStateFromLocation(completion: @escaping (String?) -> Void) {
        guard let location = self.userLocation else { return }
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first, let state = placemark.administrativeArea {
                completion(state)
            } else {
                print("Error in reverse geocoding: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    // Fetch disaster alerts from FEMA API using the state
    private func fetchDisasterAlerts(for state: String) {
        // FEMA API URL using the state
        let femaApiUrl = "https://www.fema.gov/api/open/v2/DisasterDeclarationsSummaries?$filter=state eq '\(state)' and lastIAFilingDate eq null&$orderby=incidentBeginDate desc&$top=10&$format=json"
        
        guard let url = URL(string: femaApiUrl) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching disaster data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from FEMA API")
                return
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                print("FEMA API Response: \(jsonResponse)")

                if let jsonResponse = jsonResponse as? [String: Any],
                   let disasters = jsonResponse["DisasterDeclarationsSummaries"] as? [[String: Any]] {
                    
                    // Display the title of the most recent disaster
                    if let firstDisaster = disasters.first,
                       let declarationTitle = firstDisaster["declarationTitle"] as? String {
                        DispatchQueue.main.async {
                            self.disasterAlert = "Alert: \(declarationTitle) is ongoing near your area (State: \(state))"
                            self.sendNotificationIfNewAlert(declarationTitle: declarationTitle)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.disasterAlert = "No recent active disasters reported for State: \(state)"
                        }
                    }
                }
            } catch {
                print("Error parsing FEMA API response: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Send a local push notification if a new disaster alert is detected
    private func sendNotificationIfNewAlert(declarationTitle: String) {
        if !sentNotifications.contains(declarationTitle) {
            sendNotification(title: "New Disaster Alert", body: declarationTitle)
            sentNotifications.insert(declarationTitle)
        }
    }

    // Send a local push notification
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }

    // Search for nearby places (police, hospitals, shelters, fire stations) and filter within 5 miles
    func searchNearbyPlaces(in region: MKCoordinateRegion) {
        guard let userLocation = self.userLocation else { return }

        let placeTypes: [(PlaceType, String)] = [
            (.police, "Police Station"),
            (.hospital, "Hospital"),
            (.fireStation, "Fire Station"),
            (.shelter, "Emergency Shelter")
        ]

        let dispatchGroup = DispatchGroup()
        var newAnnotations: [PlaceAnnotation] = []

        for (type, query) in placeTypes {
            dispatchGroup.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = region
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let mapItems = response?.mapItems {
                    for item in mapItems {
                        let distance = (item.placemark.location?.distance(from: userLocation) ?? 0) / 1609.34 // Distance in miles
                        
                        // Filter locations within a 5-mile radius
                        if distance <= 5 {
                            let annotation = PlaceAnnotation(
                                name: item.name ?? query,
                                coordinate: item.placemark.coordinate,
                                emoji: type.emoji,
                                address: item.placemark.title ?? "No Address Available",
                                phoneNumber: item.phoneNumber,
                                isUserLocation: false,
                                distance: distance,
                                type: type
                            )
                            newAnnotations.append(annotation)
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.annotations = newAnnotations.sorted { $0.distance < $1.distance }
        }
    }

    // Filter annotations by selected place types
    func filteredAnnotations() -> [PlaceAnnotation] {
        return annotations.filter { filters.contains($0.type) }
    }
}

struct MapScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isFullScreen = false
    @State private var scrollViewProxy: ScrollViewProxy? // To scroll to the list item
    @State private var showingFilterSheet = false // To show filter sheet

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Services Nearby")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                // Display disaster alert if available
                if let disasterAlert = locationManager.disasterAlert {
                    Text(disasterAlert)
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }

                ZStack {
                    Map(coordinateRegion: $locationManager.region, annotationItems: locationManager.filteredAnnotations() + (locationManager.userLocationAnnotation.map { [$0] } ?? [])) { place in
                        MapAnnotation(coordinate: place.coordinate) {
                            Button(action: {
                                withAnimation {
                                    locationManager.region.center = place.coordinate
                                    locationManager.selectedPlace = place // Set the selected place for zoom effect
                                    scrollViewProxy?.scrollTo(place.id, anchor: .top)
                                }
                            }) {
                                Text(place.emoji)
                                    .font(.largeTitle)
                                    .scaleEffect(locationManager.selectedPlace?.id == place.id ? 1.15 : 1.0) // Enlarge selected icon
                                    .zIndex(locationManager.selectedPlace?.id == place.id ? 1 : 0) // Bring to front if selected
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : 300)
                    
                    // Maximize/Minimize Map Button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isFullScreen.toggle() // Toggle fullscreen mode
                                }
                            }) {
                                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .font(.title2)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding()
                        }
                        Spacer()
                    }

                    VStack {
                        Spacer()
                        HStack {
                            VStack(spacing: 8) {
                                // Zoom In Button
                                Button(action: {
                                    withAnimation {
                                        locationManager.region.span.latitudeDelta /= 2
                                        locationManager.region.span.longitudeDelta /= 2
                                    }
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                        .font(.title3)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }

                                // Zoom Out Button
                                Button(action: {
                                    withAnimation {
                                        locationManager.region.span.latitudeDelta *= 2
                                        locationManager.region.span.longitudeDelta *= 2
                                    }
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .font(.title3)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }

                                // Current Location Button
                                Button(action: {
                                    withAnimation {
                                        if let userLocation = locationManager.userLocation {
                                            locationManager.region.center = userLocation.coordinate
                                            locationManager.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        }
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .font(.title3)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                            }
                            .padding(.bottom, 15)
                            .padding(.leading)
                            Spacer()
                        }
                    }
                }
                .cornerRadius(isFullScreen ? 0 : 10)
                .padding(isFullScreen ? 0 : 16)

                if !isFullScreen {
                    // Centered Filter Button
                    HStack {
                        Spacer()
                        Button(action: {
                            showingFilterSheet.toggle()
                        }) {
                            HStack {
                                Image(systemName: "line.horizontal.3.decrease.circle")
                                Text("Filter Places")
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        Spacer()
                    }
                    .padding()

                    // Mixed list of places sorted by distance from user's location
                    ScrollViewReader { proxy in
                        List(locationManager.filteredAnnotations().filter { !$0.isUserLocation }) { place in
                            HStack {
                                Text(place.emoji)
                                    .font(.title)
                                VStack(alignment: .leading) {
                                    Text(place.name)
                                        .font(.headline)
                                    Text(String(format: "%.2f miles away", place.distance))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text(place.address)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    if let phone = place.phoneNumber {
                                        Text("Phone: \(phone)")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .onTapGesture {
                                // When tapped, center the map on the corresponding annotation and zoom in
                                withAnimation {
                                    locationManager.region.center = place.coordinate
                                    locationManager.selectedPlace = place
                                }
                            }
                            .id(place.id)
                        }
                        .onAppear {
                            self.scrollViewProxy = proxy
                        }
                    }
                    .listStyle(PlainListStyle())
                    .padding(.bottom)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterView(selectedFilters: $locationManager.filters)
        }
        .onAppear {
            locationManager.searchNearbyPlaces(in: locationManager.region)
        }
        .navigationBarHidden(true)
    }
}

// Filter View for selecting which types of places to show
struct FilterView: View {
    @Binding var selectedFilters: [PlaceType]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Place Types")) {
                    ForEach(PlaceType.allCases) { type in
                        Toggle(type.rawValue, isOn: Binding(
                            get: { selectedFilters.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedFilters.append(type)
                                } else {
                                    selectedFilters.removeAll { $0 == type }
                                }
                            }
                        ))
                    }
                }
            }
            .navigationBarTitle("Filter Places", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
            })
        }
    }
}

#Preview {
    MapScreen()
}
