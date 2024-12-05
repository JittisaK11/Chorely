//
//  User.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Equatable {
    var id: String // Firebase UID or unique identifier for the user
    var email: String
    var fullName: String
    var phoneNumber: String
    var birthday: Date
    var lookingFor: [String]
    var completedTasksCount: Int
    var pendingTasksCount: Int
    var friends: [String]
    
    // Initializer to create a User object with provided values
    init(id: String, email: String, fullName: String, phoneNumber: String, birthday: Date, lookingFor: [String]) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = phoneNumber
        self.birthday = birthday
        self.lookingFor = lookingFor
        self.completedTasksCount = 0
        self.pendingTasksCount = 0
        self.friends = []
    }
    
    // Initializer to create a User object from Firestore data
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let fullName = dictionary["fullName"] as? String,
              let birthdayTimestamp = dictionary["birthday"] as? TimeInterval,
              let lookingFor = dictionary["lookingFor"] as? [String],
              let friends = dictionary["friends"] as? [String],
              let pendingTasksCount = dictionary["pendingTasksCount"] as? Int,
              let completedTasksCount = dictionary["completedTasksCount"] as? Int else {
            print("Failed to parse user data.")
            return nil
        }
        
        self.id = id
        self.email = email
        self.fullName = fullName
        self.phoneNumber = dictionary["phoneNumber"] as? String ?? ""
        self.birthday = Date(timeIntervalSince1970: birthdayTimestamp)
        self.lookingFor = lookingFor
        
        // Assign additional attributes, providing default values if not present
        self.completedTasksCount = dictionary["completedTasksCount"] as? Int ?? 0
        self.pendingTasksCount = dictionary["pendingTasksCount"] as? Int ?? 0
        self.friends = dictionary["friends"] as? [String] ?? []

    }
    
    // Convert User instance to a dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id, // Include the ID when saving back to Firestore
            "email": email,
            "fullName": fullName,
            "phoneNumber": phoneNumber,
            "birthday": birthday.timeIntervalSince1970,
            "lookingFor": lookingFor,
            "completedTasksCount": completedTasksCount,
            "pendingTasksCount": pendingTasksCount,
            "friends": friends
        ]
    }
}
