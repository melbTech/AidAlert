import Foundation
import CoreLocation
import Combine
import UserNotifications

// Disaster Model for decoding the FEMA API response
struct Disaster: Codable, Identifiable {
    let id = UUID() // Assign a unique identifier
    let declarationTitle: String
    let incidentBeginDate: String
    let expirationDate: String?
}

// Codable struct for the full FEMA API response
struct DisasterResponse: Codable {
    let DisasterDeclarationsSummaries: [Disaster]
}

class AlertsViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocation?
    @Published var userLocality: String = "Your Location"
    @Published var disasterAlert: String = "Fetching alerts..."
    @Published var selectedState: String = "Select State"
    @Published var issuedDate: String = ""
    @Published var expirationDate: String = ""

    
    private var locationManager = CLLocationManager()
    
    // Change private to fileprivate to allow limited access within the module
    private var _sentNotifications = Set<String>()
    
    // Computed property to expose sentNotifications
    var sentNotifications: [String] {
        Array(_sentNotifications) // Converting Set<String> to Array<String> for ForEach compatibility
    }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location
            reverseGeocodeLocation(location)
        }
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.userLocality = placemark.locality ?? "Your Location"
                    if let state = placemark.administrativeArea {
                        self.fetchDisasterAlerts(for: state)
                    }
                }
            }
        }
    }
    
    func fetchDisasterAlerts(for state: String) {
        self.selectedState = state
        
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
                    
                    if let firstDisaster = disasters.first,
                       let declarationTitle = firstDisaster["declarationTitle"] as? String {
                        DispatchQueue.main.async {
                            self.disasterAlert = "Alert: \(declarationTitle) is ongoing in \(state)"
                            self.sendNotificationIfNewAlert(declarationTitle: declarationTitle)
                            self.issuedDate = firstDisaster["declarationDate"] as? String ?? "N/A"
                            self.expirationDate = firstDisaster["expirationDate"] as? String ?? "N/A"
                            self.sendNotificationIfNewAlert(declarationTitle: declarationTitle)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.disasterAlert = "No recent active disasters reported for \(state)"
                        }
                    }
                }
            } catch {
                print("Error parsing FEMA API response: \(error.localizedDescription)")
            }
        }.resume()
    }

    private func sendNotificationIfNewAlert(declarationTitle: String) {
        if !_sentNotifications.contains(declarationTitle) {
            sendNotification(title: "New Disaster Alert", body: declarationTitle)
            _sentNotifications.insert(declarationTitle)
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


