//
//  CreateEventView.swift
//  Chorely
//
//  Created by Melisa Zhang on 11/12/24.
//

import SwiftUI
import FirebaseFirestore
import MapKit

struct CreateEventView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var scheduledTime: Date = Date()
    @State private var latitude: Double = 40.7128 // Default to NYC
    @State private var longitude: Double = -74.0060
    @State private var locationName: String = ""
    @State private var errorMessage: String?

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                        .accessibility(label: Text("Event Title"))
                    TextField("Description", text: $description)
                        .accessibility(label: Text("Event Description"))
                    Group {
                        
                        DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: [.date, .hourAndMinute])
//                            .colorInvert()
//                                .colorMultiply(Color(hex:"7D84B2"))
//                            .colorInvert()
                            .accessibility(label: Text("Event Scheduled Time"))
                            .foregroundColor(Color(hex:"7D84B2"))
                            .accentColor(Color(hex:"7D84B2"))
                            
                        }

                }
                .listRowBackground(Color(hex:"#E3E5F5"))
                
                Section(header: Text("Event Location")) {
                                    ZStack {
                                        Map(coordinateRegion: Binding(
                                                get: { region },
                                                set: { newRegion in
                                                    region = newRegion
                                                    latitude = newRegion.center.latitude
                                                    longitude = newRegion.center.longitude
                                                }
                                            ),
                                            interactionModes: .all,
                                            showsUserLocation: true
                                        )
                                        .frame(height: 300)
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.largeTitle)
                                            .offset(x: 0, y: -16)
                                    }
                                }
                .listRowBackground(Color(hex:"#E3E5F5"))


                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitle("Create Event", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
                .foregroundColor(Color(hex:"7D84B2"))

                                
                                , trailing: Button("Save") {
                fetchLocationNameAndSave()
            }
                .foregroundColor(Color(hex:"7D84B2"))
)
        }
    }

    func fetchLocationNameAndSave() {
        let url = URL(string: "https://trueway-geocoding.p.rapidapi.com/ReverseGeocode?location=\(latitude),\(longitude)&language=en")!
        var request = URLRequest(url: url)
        request.addValue("97e18e3883msh3200bd59eda2916p190ef8jsn7956631767b8", forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("trueway-geocoding.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Failed to fetch location: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received from API."
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let fetchedLocationName = firstResult["address"] as? String {
                    print(fetchedLocationName)
                    DispatchQueue.main.async {
                        locationName = fetchedLocationName
                        saveEvent()
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Failed to parse location data."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Failed to decode location data: \(error.localizedDescription)"
                }
            }
        }

        task.resume()
    }

    func saveEvent() {
        guard let user = appState.user else {
            errorMessage = "User not authenticated."
            return
        }

        guard !title.isEmpty else {
            errorMessage = "Title cannot be empty."
            return
        }

        guard !locationName.isEmpty else {
            errorMessage = "Failed to determine location name."
            return
        }

        let db = Firestore.firestore()
        var newEvent = ChoreTask(
            title: title,
            description: description,
            creatorId: user.id,
            scheduledTime: scheduledTime,
            createdAt: Date(),
            participants: [user.id],
            locationName: locationName ?? "Unknown location"
        )

        newEvent.locationName = locationName

        do {
            let ref = try db.collection("events").addDocument(from: newEvent)
            newEvent.id = ref.documentID
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
        }
    }
}
