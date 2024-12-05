//
//  AddFriendView.swift
//  Chorely
//
//  Created by Melisa Zhang on 11/20/24.
//

import SwiftUI
import FirebaseFirestore

struct AddFriendView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @State private var searchText: String = ""
    @State private var searchResults: [User] = []
    @State private var errorMessage: String?

    var onAddFriend: (User) -> Void

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    
                    TextField("Search by name, email, or phone", text: $searchText)
                        .foregroundColor(Color(hex:"#7D84B2"))
                        .onSubmit {
                            searchFriends()
                        }
                        .accessibility(label: Text("Search for friends by name, email, or phone"))
                    Button(action: {
                        searchFriends()
                    }) {
                        Text("Search")
                            .bold()
                            .foregroundColor(Color(hex: "#7D84B2"))
                    }
                }
                .padding()
                .background(Color(hex: "#ECE6F1"))
                .cornerRadius(10)
                .padding()

                // Search Results
                List {
                    ForEach(searchResults) { user in
                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 50, height: 50)
                                .overlay(Text(user.fullName.prefix(1)).foregroundColor(.white))

                            VStack(alignment: .leading) {
                                Text(user.fullName)
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#7D84B2"))
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#7D84B2"))
                                Text(user.phoneNumber)
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#7D84B2"))
                            }
                            
                            Spacer()
                            Button(action: {
                                onAddFriend(user)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color(hex: "#7D84B2"))                            }
                            .accessibility(label: Text("Add \(user.fullName) as friend"))
                        }
                        .background(Color(hex: "#E3E5F5"))
                    }
                    .listRowBackground(Color(hex: "#E3E5F5"))

                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .navigationBarTitle("Add Friend", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
                .foregroundColor(Color(hex: "#7D84B2"))

            )
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Alert(title: Text("Error"),
                      message: Text(errorMessage ?? ""),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    func searchFriends() {
        guard !searchText.isEmpty else { return }

        let db = Firestore.firestore()
        searchResults = []

        // Search by name
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
                    searchResults += filteredUsers
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
                    searchResults += filteredUsers
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
                    searchResults += filteredUsers
                }
            }
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView { _ in }
            .environmentObject(AppState())
    }
}
