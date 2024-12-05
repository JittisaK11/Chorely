//
//  AppState.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AppState: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var user: User? // Reference to User defined in User.swift
    
    // Centralized Registration Data
    @Published var registrationEmail: String = ""
    @Published var registrationPassword: String = ""
    @Published var registrationPhoneNumber: String = ""
    @Published var registrationFullName: String = ""
    @Published var registrationBirthday: Date = Date()
    @Published var registrationLookingFor: [String] = []
    
    private var db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    
    init() {
        // Listen to Firebase authentication state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseUser in
            guard let self = self else { return }
            if let firebaseUser = firebaseUser {
                print("Firebase user signed in with UID: \(firebaseUser.uid)")
                self.fetchUserData(uid: firebaseUser.uid) { result in
                    switch result {
                    case .success(let user):
                        DispatchQueue.main.async {
                            self.user = user
                            self.isSignedIn = true
                            self.listenToUserChanges()
                        }
                        print("User data fetched and set: \(user)")
                    case .failure(let error):
                        print("Error fetching user data: \(error.localizedDescription)")
                        // Automatically sign out if user data cannot be fetched
                        self.signOut()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isSignedIn = false
                    self.user = nil
                    print("Firebase user signed out.")
                }
                self.stopListeningToUserChanges()
            }
        }
    }
    
    deinit {
        // Remove the auth state listener when AppState is deinitialized
        if let authStateListener = authStateListener {
            Auth.auth().removeStateDidChangeListener(authStateListener)
        }
        stopListeningToUserChanges()
    }
    
    // MARK: - Authentication Methods
    
    // Sign In Method - Uses stored registrationEmail and registrationPassword
    func signIn(completion: @escaping (Result<Void, Error>) -> Void) {
        let email = self.registrationEmail
        let password = self.registrationPassword
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("User signed in successfully.")
                completion(.success(()))
                // The auth state listener will handle fetching user data
            }
        }
    }
    
    // Sign Out Method
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.user = nil
                print("User signed out successfully.")
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    // Register User Method - Accepts parameters
    func registerUser(email: String, password: String, fullName: String, phoneNumber: String, birthday: Date, lookingFor: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else if let firebaseUser = authResult?.user {
                print("User registered with UID: \(firebaseUser.uid)")
                // Create a new user document in Firestore
                let newUser = User(
                    id: firebaseUser.uid,
                    email: email,
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    birthday: birthday,
                    lookingFor: lookingFor
                )
                
                self.db.collection("users").document(firebaseUser.uid).setData(newUser.toDictionary()) { error in
                    if let error = error {
                        completion(.failure(error))
                        // Optionally, delete the Firebase Auth user if Firestore write fails
                        firebaseUser.delete { deleteError in
                            if let deleteError = deleteError {
                                print("Error deleting user after Firestore failure: \(deleteError.localizedDescription)")
                            }
                        }
                    } else {
                        print("User document created in Firestore.")
                        completion(.success(()))
                        // The auth state listener will handle fetching user data
                    }
                }
            } else {
                completion(.failure(NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown registration error."])))
            }
        }
    }
    
    // MARK: - User Data Management
    
    // Fetch User Data from Firestore
    func fetchUserData(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let document = document, let data = document.data(), let user = User(from: data) {
                print("User data fetched: \(user.fullName)")
                completion(.success(user))
            } else {
                print("User data not found.")
                let error = NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found in Firestore."])
                completion(.failure(error))
            }
        }
    }
    
    // Add Friend to User's Friends List
    func addFriendToList(_ friendId: String) {
        guard let user = self.user else { return }
        let userRef = db.collection("users").document(user.id)
        
        userRef.updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ]) { error in
            if let error = error {
                print("Error adding friend: \(error.localizedDescription)")
            } else {
                print("Friend added successfully!")
                // Optionally, update local user data
                DispatchQueue.main.async {
                    self.user?.friends.append(friendId)
                }
            }
        }
    }
    
    // Remove Friend from User's Friends List
    func removeFriendFromList(_ friendId: String) {
        guard let user = self.user else { return }
        let userRef = db.collection("users").document(user.id)
        
        userRef.updateData([
            "friends": FieldValue.arrayRemove([friendId])
        ]) { error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                print("Friend removed successfully!")
                // Optionally, update local user data
                DispatchQueue.main.async {
                    self.user?.friends.removeAll { $0 == friendId }
                }
            }
        }
    }
    
    // MARK: - Update User Information
    
    // Update Email Method
    func updateEmail(to newEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = self.user else {
            completion(.failure(NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."])))
            return
        }
        
        Auth.auth().currentUser?.updateEmail(to: newEmail) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Update Firestore user document
                let userRef = self.db.collection("users").document(user.id)
                userRef.updateData([
                    "email": newEmail
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Update local user object
                        DispatchQueue.main.async {
                            self.user?.email = newEmail
                        }
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // Update Phone Number Method
    func updatePhoneNumber(to newPhoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = self.user else {
            completion(.failure(NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."])))
            return
        }
        
        // Note: Firebase Auth does not provide a direct method to update phone number like email.
        // It requires verification via SMS. However, for the purpose of this example, we'll assume we can update the Firestore document.
        
        let userRef = self.db.collection("users").document(user.id)
        userRef.updateData([
            "phoneNumber": newPhoneNumber
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Update local user object
                DispatchQueue.main.async {
                    self.user?.phoneNumber = newPhoneNumber
                }
                completion(.success(()))
            }
        }
    }
    
    func listenToUserChanges() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let userRef = db.collection("users").document(userId)
            userListener = userRef.addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening to user changes: \(error.localizedDescription)")
                    return
                }
                if let data = snapshot?.data(), let updatedUser = User(from: data) {
                    DispatchQueue.main.async {
                        self.user = updatedUser
                        print("User data updated: \(updatedUser)")
                    }
                }
            }
        }
        
        func stopListeningToUserChanges() {
            userListener?.remove()
            userListener = nil
        }
    
    func stopLoading() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.isLoading = false
            }
    }
}
