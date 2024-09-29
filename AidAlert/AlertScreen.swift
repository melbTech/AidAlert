import SwiftUI

struct AlertScreen: View {
    @StateObject private var alertsViewModel = AlertsViewModel()
    @State private var stateInput: String = "" // For state search input
    @State private var selectedState: String = "Select State" // Initial state
    @State private var states: [String] = [
        "Alabama", "Alaska", "Arizona", "Arkansas", "California",
        "Colorado", "Connecticut", "Delaware", "Florida",
        "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana",
        "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine",
        "Maryland", "Massachusetts", "Michigan", "Minnesota",
        "Mississippi", "Missouri", "Montana", "Nebraska",
        "Nevada", "New Hampshire", "New Jersey", "New Mexico",
        "New York", "North Carolina", "North Dakota", "Ohio",
        "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
        "South Carolina", "South Dakota", "Tennessee", "Texas",
        "Utah", "Vermont", "Virginia", "Washington", "West Virginia",
        "Wisconsin", "Wyoming"
    ]
    
    // State abbreviation mapping
    private let stateAbbreviations: [String: String] = [
        "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR", "California": "CA",
        "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE", "Florida": "FL",
        "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID", "Illinois": "IL", "Indiana": "IN",
        "Iowa": "IA", "Kansas": "KS", "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME",
        "Maryland": "MD", "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN",
        "Mississippi": "MS", "Missouri": "MO", "Montana": "MT", "Nebraska": "NE",
        "Nevada": "NV", "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM",
        "New York": "NY", "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH",
        "Oklahoma": "OK", "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI",
        "South Carolina": "SC", "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX",
        "Utah": "UT", "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
        "Wisconsin": "WI", "Wyoming": "WY"
    ]
    
    @State private var isPickerVisible: Bool = false // State for dropdown visibility
    
    var body: some View {
        Text("Disaster Alerts")
            .font(.title)
            .padding()
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
        VStack (spacing: 0) {
            Text("Search for alerts by state")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
               
                TextField("Enter state (e.g., CA)", text: $stateInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    alertsViewModel.fetchDisasterAlerts(for: stateInput) // Fetch alerts for entered state
                }) {
                    Text("Search")
                        .padding()
                }
            }
            
            HStack {
                Text("Alerts based on")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "location.fill")
                    Text(alertsViewModel.selectedState)
                        .underline()
                        .onTapGesture {
                            withAnimation {
                                isPickerVisible.toggle()
                            }
                        }
                }
            }
            .padding()
            
            if isPickerVisible {
                VStack(spacing: 0) {
                    ScrollView{
                        ForEach(states, id: \.self) {state in
                            Button(action: {
                                //Update selected state and fetch alerts
                                selectedState = state
                                if let abbreviation = stateAbbreviations[state] {
                                    alertsViewModel.fetchDisasterAlerts(for: abbreviation)
                                }
                                isPickerVisible = false //Hide dropdown after selection
                            }) {
                                Text(state)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(Color.clear)
                        }
                    }
                    .frame(maxHeight: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                    .padding(.horizontal)
                }
            }
            
            Text(alertsViewModel.disasterAlert)
                .font(.body)
                .padding()
                .foregroundColor(alertsViewModel.disasterAlert.contains("Alert") ? .red : .gray) // Color based on alert status
            
            Spacer()
        }
        .onAppear {
            alertsViewModel.startUpdatingLocation()
        }
        .navigationBarTitle("Alerts")
        .navigationBarItems(trailing: HStack {
            Button(action: {
                // Info button action
            }) {
                Image(systemName: "info.circle")
            }
            Button(action: {
                // Settings button action
            }) {
                Image(systemName: "gearshape.fill")
            }
        })
    }
}

#Preview {
    AlertScreen()
}

