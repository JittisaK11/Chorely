//
//  EventRow.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/26/24.
//


import SwiftUI

struct EventRow: View {
    var event: ChoreTask
    var isJoined: Bool
    var joinAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(event.title)
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(hex:"7D84B2"))
                Spacer()
                if !isJoined {
                    Button(action: joinAction) {
                        Text("Join")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .accessibility(label: Text("Join \(event.title)"))
                } else {
                    Text("Joined")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(Color(hex:"7D84B2"))
            Text("Scheduled: \(formattedDate(event.scheduledTime))")
                .font(.caption)
                .foregroundColor(.gray)
            Text(event.locationName ?? "Unknown Location")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
        .listRowBackground(Color(hex: "E3E5F5"))
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EventRow_Previews: PreviewProvider {
    static var previews: some View {
        EventRow(
            event: ChoreTask(
                title: "Sample Event",
                description: "Description here",
                creatorId: "user123",
                scheduledTime: Date(),
                createdAt: Date()
            ),
            isJoined: false,
            joinAction: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
