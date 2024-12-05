//
//  FriendsView.swift
//  Chorely
//
//  Created by Melisa Zhang on 11/13/24.
//

import SwiftUI
import FirebaseFirestore

struct FriendsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var selectedTasks: SelectedTasks

    @State private var searchText: String = ""
    @State private var availableFriends: [User] = []
    @State private var addedFriends: [User] = []
    @State private var showingAddFriendSheet = false
    @State private var errorMessage: String?

    // New State Variables for Friends' Events
    @State private var friendsEvents: [ChoreTask] = []
    @State private var isLoadingEvents: Bool = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                VStack(alignment: .center){
                    Text("What your friends are planning:")
                        .font(.title)
                        .bold()
                        .padding(.top, 16)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex:"#7D84B2"))
                    Text("Join in on common tasks!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 16)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex:"#7D84B2"))
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search by name, email, or phone", text: $searchText)
                        .foregroundColor(Color(hex:"#7D84B2"))
                        .onChange(of: searchText) { _ in
                            // Implement search logic
                            if searchText.count >= 3 {
                                searchFriends()
                            } else {
                                availableFriends = []
                            }
                        }
                        .accessibility(label: Text("Search for friends by name, email, or phone"))
                }
                .padding()
                .background(Color(hex: "#ECE6F1"))
                .cornerRadius(10)
                .padding([.leading, .trailing, .top], 10)

                // Friends List
                List {
                    Section(header: Text("Friends")) {
                        if addedFriends.isEmpty {
                            Text("No friends added yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(addedFriends) { friend in
                                FriendRow(friend: friend)
                            }
                        }
                    }
                    

                    // Friends' Events Section
                    if !friendsEvents.isEmpty {
                        Section(header: Text("Friends' Events")) {
                            ForEach(friendsEvents) { event in
                                EventRow(
                                    event: event,
                                    isJoined: event.participants.contains(appState.user?.id ?? ""),
                                    joinAction: {
                                        joinEvent(event)
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .background(Color.clear)

                Spacer()
            }
            .navigationBarTitle("Friends", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showingAddFriendSheet = true
            }) {
                Image(systemName: "person.badge.plus")
            }
            .accessibilityLabel("Add Friend Button"))
            .foregroundColor(Color(hex:"#7D84B2"))
            .sheet(isPresented: $showingAddFriendSheet) {
                AddFriendView { newFriend in
                    addFriend(newFriend)
                }
                .environmentObject(appState)
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage ?? ""),
                      dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadFriends()
                fetchFriendsEvents()
            }
        }
    }

    // Load existing friends from Firestore
    func loadFriends() {
        guard let user = appState.user else { return }
        let db = Firestore.firestore()

        // Check if friends array is non-empty
        if user.friends.isEmpty {
            addedFriends = []
            friendsEvents = []
            return
        }

        // Firestore 'in' queries support a maximum of 10 elements
        // If more, batch the queries
        let chunks = user.friends.chunked(into: 10)
        addedFriends = [] // Reset before loading

        for chunk in chunks {
            db.collection("users").whereField(FieldPath.documentID(), in: chunk).getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to load friends: \(error.localizedDescription)"
                } else {
                    if let documents = snapshot?.documents {
                        let friends = documents.compactMap { doc in
                            User(from: doc.data())
                        }
                        addedFriends += friends
                    }
                }
            }
        }
    }

    // Fetch friends' events
    func fetchFriendsEvents() {
        guard let user = appState.user else { return }
        let db = Firestore.firestore()

        if user.friends.isEmpty {
            friendsEvents = []
            return
        }

        isLoadingEvents = true
        friendsEvents = []

        // Split into chunks if necessary
        let chunks = user.friends.chunked(into: 10)
        let dispatchGroup = DispatchGroup()

        for chunk in chunks {
            dispatchGroup.enter()
            db.collection("events")
                .whereField("creatorId", in: chunk)
                .getDocuments { snapshot, error in
                    if let error = error {
                        errorMessage = "Failed to fetch friends' events: \(error.localizedDescription)"
                    } else {
                        if let documents = snapshot?.documents {
                            let events = documents.compactMap { doc in
                                ChoreTask(document: doc)
                            }
//                            friendsEvents += events
                            // Filter out completed events
                            friendsEvents += events.filter { !$0.completed }
                        }
                    }
                    dispatchGroup.leave()
                }
        }

        dispatchGroup.notify(queue: .main) {
            isLoadingEvents = false
        }
    }

    // Fetch available friends based on search
    func searchFriends() {
        guard !searchText.isEmpty else {
            availableFriends = []
            return
        }

        let db = Firestore.firestore()
        availableFriends = []

        // Search by name (fullName)
        let nameQuery = db.collection("users")
            .whereField("fullName", isGreaterThanOrEqualTo: searchText)
            .whereField("fullName", isLessThanOrEqualTo: searchText + "\u{f8ff}")

        nameQuery.getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Search by name failed: \(error.localizedDescription)"
            } else {
                if let documents = snapshot?.documents {
                    let usersByName = documents.compactMap { doc in
                        User(from: doc.data())
                    }
                    let filteredUsers = usersByName.filter { user in
                        !appState.user!.friends.contains(user.id) && user.id != appState.user!.id
                    }
                    availableFriends += filteredUsers
                }
            }
        }

        // Search by email
        let emailQuery = db.collection("users")
            .whereField("email", isEqualTo: searchText)

        emailQuery.getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Search by email failed: \(error.localizedDescription)"
            } else {
                if let documents = snapshot?.documents {
                    let usersByEmail = documents.compactMap { doc in
                        User(from: doc.data())
                    }
                    let filteredUsers = usersByEmail.filter { user in
                        !appState.user!.friends.contains(user.id) && user.id != appState.user!.id
                    }
                    availableFriends += filteredUsers
                }
            }
        }

        // Search by phone number
        let phoneQuery = db.collection("users")
            .whereField("phoneNumber", isEqualTo: searchText)

        phoneQuery.getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Search by phone number failed: \(error.localizedDescription)"
            } else {
                if let documents = snapshot?.documents {
                    let usersByPhone = documents.compactMap { doc in
                        User(from: doc.data())
                    }
                    let filteredUsers = usersByPhone.filter { user in
                        !appState.user!.friends.contains(user.id) && user.id != appState.user!.id
                    }
                    availableFriends += filteredUsers
                }
            }
        }
    }

    // Add a friend to Firestore and local list
    func addFriend(_ friend: User) {
        guard let user = appState.user else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        userRef.updateData([
            "friends": FieldValue.arrayUnion([friend.id])
        ]) { error in
            if let error = error {
                errorMessage = "Failed to add friend: \(error.localizedDescription)"
            } else {
                // Update local state
                addedFriends.append(friend)
                appState.user?.friends.append(friend.id)
            }
        }
    }

    // Join an event
    func joinEvent(_ event: ChoreTask) {
        guard let user = appState.user else { return }
        let db = Firestore.firestore()
        guard let eventId = event.id else {
            errorMessage = "Invalid event ID."
            return
        }
        let eventRef = db.collection("events").document(eventId)

        eventRef.updateData([
            "participants": FieldValue.arrayUnion([user.id])
        ]) { error in
            if let error = error {
                errorMessage = "Failed to join event: \(error.localizedDescription)"
            } else {
                // Update local state
                if let index = friendsEvents.firstIndex(where: { $0.id == event.id }) {
                    friendsEvents[index].participants.append(user.id)
                }
                // Optionally, refresh HomeView by fetching events again
                // This requires a way to notify HomeView to refresh, such as using a shared AppState or a publisher
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

struct FriendRow: View {
    var friend: User

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 50, height: 50)
                .overlay(Text(friend.fullName.prefix(1)).foregroundColor(.white))

            VStack(alignment: .leading) {
                Text(friend.fullName)
                    .font(.headline)
                    .foregroundColor(Color(hex:"#848BB6"))
                Text(friend.email)
                    .font(.subheadline)
                    .foregroundColor(Color(hex:"#848BB6"))
                Text(friend.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .foregroundColor(Color(hex:"#848BB6"))
            }
            Spacer()
        }
        .listRowBackground(Color(hex: "#E3E5F5"))
    }
    
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
            .environmentObject(AppState())
            .environmentObject(SelectedTasks())
    }
}
