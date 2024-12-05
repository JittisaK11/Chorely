//
//  HomeView.swift
//  Chorely
//
//  Created by Melisa Zhang on 11/13/24.
//

import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var events: [ChoreTask] = []
    @State private var isLoading: Bool = false
    @State private var showingCreateEvent = false
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: ChoreTask?
    
    // For storing creator names
    @State private var creatorNames: [String: String] = [:]
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Your Events")
                        .font(.title)
                        .foregroundColor(Color(hex:"#7D84B2"))
                        .bold()
                        .padding()
                    Spacer()
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .padding()
                    }
                    .foregroundColor(Color(hex:"#7D84B2"))
                    .accessibilityLabel("Add a new event")
                    .sheet(isPresented: $showingCreateEvent, onDismiss: {
                        fetchEvents()
                    }) {
                        CreateEventView()
                            .environmentObject(appState)
                    }
                }
                
                if isLoading {
                    ProgressView()
                } else if events.isEmpty {
                    Text("No events scheduled.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(events) { event in
                            EventRowHome(event: event, creatorName: creatorNames[event.creatorId] ?? "Unknown",
                                         deleteAction: {
                                eventToDelete = event
                                showingDeleteConfirmation = true
                            },
                                         markAsCompleteAction: {
                                markEventAsComplete(event)
                            } // New action
                            )
                        }
                        .onDelete(perform: deleteEvent)
                    }
                }
                
                Spacer()
            }
            .onAppear {
                fetchEvents()
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage ?? ""),
                      dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Remove from Your Events"),
                    message: Text("Are you sure you want to remove \"\(eventToDelete?.title ?? "")\" from your events?"),
                    primaryButton: .destructive(Text("Remove")) {
                        if let event = eventToDelete {
                            confirmDelete(event)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationBarTitle("Home", displayMode: .inline)
        }
    }
    
    func fetchEvents() {
        guard let userId = appState.user?.id else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("events")
            .whereField("participants", arrayContains: userId)
            .order(by: "scheduledTime", descending: false)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to fetch events: \(error.localizedDescription)"
                } else if let documents = snapshot?.documents {
                    let fetchedEvents = documents.compactMap { doc in
                        ChoreTask(document: doc)
                    }
                    // Filter out completed events
                    let filteredEvents = fetchedEvents.filter { !$0.completed }
                    
                    // Increment pendingTasksCount for any new events
                    if filteredEvents.count > self.events.count {
                        let newEventsCount = filteredEvents.count - self.events.count
                        self.incrementPendingTasks(by: newEventsCount)
                    }

                    self.events = filteredEvents
                    fetchCreatorNames()
                }
            }
    }
    
    // Increment `pendingTasksCount` for the current user
    func incrementPendingTasks(by count: Int) {
        guard let userId = appState.user?.id else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.updateData([
            "pendingTasksCount": FieldValue.increment(Int64(count))
        ]) { error in
            if let error = error {
                errorMessage = "Failed to update pendingTasksCount: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchCreatorNames() {
        let uniqueCreatorIds = Set(events.map { $0.creatorId })
        let db = Firestore.firestore()
        
        // Clear previous creator names
        creatorNames = [:]
        
        // Firestore 'in' queries support up to 10 elements
        let chunks = Array(uniqueCreatorIds).chunked(into: 10)
        
        for chunk in chunks {
            db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to fetch creator names: \(error.localizedDescription)"
                } else if let documents = snapshot?.documents {
                    for doc in documents {
                        if let user = User(from: doc.data()) {
                            creatorNames[user.id] = user.fullName
                        }
                    }
                }
            }
        }
    }
    
    func deleteEvent(at offsets: IndexSet) {
        for index in offsets {
            let event = events[index]
            eventToDelete = event
            showingDeleteConfirmation = true
        }
    }
    
    func confirmDelete(_ event: ChoreTask) {
        guard let eventId = event.id, let userId = appState.user?.id else {
            errorMessage = "Invalid event or user ID."
            return
        }
        
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document(eventId)
        
        // Remove the user from the participants array instead of deleting the entire event
        eventRef.updateData([
            "participants": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                errorMessage = "Failed to remove event: \(error.localizedDescription)"
            } else {
                // Decrement pendingTasksCount when removing from an event
                self.incrementPendingTasks(by: -1)
                
                // Remove from local list
                if let index = events.firstIndex(where: { $0.id == event.id }) {
                    events.remove(at: index)
                }
            }
        }
    }
    func markEventAsComplete(_ event: ChoreTask) {
        guard let userId = appState.user?.id, let eventId = event.id else { return }
        let db = Firestore.firestore()
        let eventRef = db.collection("events").document(eventId)
        let userRef = db.collection("users").document(userId)

        // Update Firestore for event and user
        eventRef.updateData([
            "completed": true, // Add or update the completed status in Firestore
        ]) { error in
            if let error = error {
                errorMessage = "Failed to mark event as completed: \(error.localizedDescription)"
            } else {
                // Update the user's stats
                userRef.updateData([
                    "completedTasksCount": FieldValue.increment(Int64(1)),
                    "pendingTasksCount": FieldValue.increment(Int64(-1))
                ]) { error in
                    if let error = error {
                        errorMessage = "Failed to update user stats: \(error.localizedDescription)"
                    } else {
                        // Update local state
                        if let index = events.firstIndex(where: { $0.id == event.id }) {
                            events.remove(at: index) // Remove from the pending list
                        }
                    }
                }
            }
        }
    }

}

struct EventRowHome: View {
    var event: ChoreTask
    var creatorName: String
    var deleteAction: () -> Void
    var markAsCompleteAction: () -> Void // New action for marking completion
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(Color(hex:"#7D84B2"))
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(Color(hex:"7D84B2"))
                Text("Created by \(creatorName)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Scheduled: \(formattedDate(event.scheduledTime))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(event.locationName ?? "Unknown Location")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            // Add a checkmark button
            Button(action: markAsCompleteAction) {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color(hex:"7D84B2"))
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibility(label: Text("Mark \(event.title) as completed"))
            
            
            Button(action: deleteAction) {
                Image(systemName: "minus.circle")
                    .foregroundColor(.gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            .accessibility(label: Text("Remove \(event.title) from your events"))
        }
        .listRowBackground(Color(hex:"#E3E5F5"))
        .padding(.vertical, 5)
    }
        
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState())
    }
}
