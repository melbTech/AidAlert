import Foundation
import CoreLocation
import Combine
import UserNotifications

struct DisasterAlert: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let issuedDate: String
}

class AlertsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var userLocality: String = "Your Location"
    @Published var disasterAlert: DisasterAlert? // Change to optional DisasterAlert type
    @Published var selectedState: String = "Select State" // New property for selected state
    
    private var locationManager = CLLocationManager()
    private var sentNotifications = Set<String>()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        startUpdatingLocation() // Start updating location
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            reverseGeocodeLocation(location) // Fetch locality and alerts
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.userLocality = placemark.locality ?? "Your Location"
                    if let state = placemark.administrativeArea {
                        self.fetchDisasterAlerts(for: state) // Fetch alerts based on state
                    }
                }
            }
        }
    }
    
    func fetchDisasterAlerts(for state: String) {
        // Update selected state
        self.selectedState = state
        
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
                    
                    // Handle the title and issued date of the most recent disaster
                    if let firstDisaster = disasters.first,
                       let declarationTitle = firstDisaster["declarationTitle"] as? String,
                       let issuedDate = firstDisaster["declarationDate"] as? String { // Adjust to match your API response structure
                        
                        let alert = DisasterAlert(title: declarationTitle, description: "Alert ongoing in \(state)", issuedDate: issuedDate)
                        
                        DispatchQueue.main.async {
                            self.disasterAlert = alert // Set the disaster alert
                            self.sendNotificationIfNewAlert(declarationTitle: declarationTitle)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.disasterAlert = nil // No alerts
                        }
                    }
                }
            } catch {
                print("Error parsing FEMA API response: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func sendNotificationIfNewAlert(declarationTitle: String) {
        if !sentNotifications.contains(declarationTitle) {
            sendNotification(title: "New Disaster Alert", body: declarationTitle)
            sentNotifications.insert(declarationTitle)
        }
    }

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
}

