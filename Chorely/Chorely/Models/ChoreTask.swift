//
//  ChoreTask.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/26/24.
//


import Foundation
import FirebaseFirestore
import FirebaseFirestore

struct ChoreTask: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var creatorId: String
    var scheduledTime: Date
    var createdAt: Date
    var participants: [String]
    var completed: Bool
    var locationName: String?
    // Initializer
    init(id: String? = nil, title: String, description: String, creatorId: String, scheduledTime: Date, createdAt: Date, participants: [String] = [], completed: Bool = false, locationName: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.creatorId = creatorId
        self.scheduledTime = scheduledTime
        self.createdAt = createdAt
        self.participants = participants
        self.completed = false
        self.locationName = locationName
    }

    // Initialize from Firestore document
    init?(document: DocumentSnapshot) {
        let data = document.data()
        guard let data = data,
              let title = data["title"] as? String,
              let description = data["description"] as? String,
              let creatorId = data["creatorId"] as? String,
              let scheduledTimeTimestamp = data["scheduledTime"] as? Timestamp,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let participants = data["participants"] as? [String],
              let completed = data["completed"] as? Bool else {
            return nil
        }

        self.id = document.documentID
        self.title = title
        self.description = description
        self.creatorId = creatorId
        self.scheduledTime = scheduledTimeTimestamp.dateValue()
        self.createdAt = createdAtTimestamp.dateValue()
        self.participants = participants
        self.completed = completed
        self.locationName = data["locationName"] as? String
    }

    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "title": title,
            "description": description,
            "creatorId": creatorId,
            "scheduledTime": Timestamp(date: scheduledTime),
            "createdAt": Timestamp(date: createdAt),
            "participants": participants,
            "completed": completed,
            "location": locationName
        ]
    }
}
