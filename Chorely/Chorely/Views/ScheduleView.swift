//
//  ScheduleView.swift
//  Chorely
//
//  Created by Melisa Zhang on 11/13/24.
//

import SwiftUI
import FirebaseFirestore

struct ScheduleView: View {
    @EnvironmentObject var appState: AppState
    @State private var events: [ChoreTask] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Calendar State
    @State private var currentDate: Date = Date()
    @State private var selectedDate: Date? = nil
    @State private var eventsForSelectedDate: [ChoreTask] = []

    // Date Formatter
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationView {
            VStack {
                // Calendar Header with Month and Navigation
                HStack {
                    Button(action: {
                        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                        fetchEvents()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex:"#7D84B2"))
                    }

                    Spacer()

                    Text(monthFormatter.string(from: currentDate))
                        .font(.headline)
                        .foregroundColor(Color(hex:"#7D84B2"))

                    Spacer()

                    Button(action: {
                        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                        fetchEvents()
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(Color(hex:"#7D84B2"))
                    }
                }
                .padding()

                // Calendar Grid
                CalendarGridView(currentDate: $currentDate, selectedDate: $selectedDate, events: events)
                    .onAppear {
                        fetchEvents()
                    }
                    .onChange(of: selectedDate) { newDate in
                        if let date = newDate {
                            fetchEventsForDate(date)
                        } else {
                            eventsForSelectedDate = []
                        }
                    }

                // Events for Selected Date
                if let date = selectedDate {
                    Text("Events on \(formattedDate(date))")
                        .font(.headline)
                        .foregroundColor(Color(hex:"#7D84B2"))
                        .bold()
                        .padding([.leading, .trailing, .top], 10)

                    if isLoading {
                        ProgressView()
                    } else if eventsForSelectedDate.isEmpty {
                        Text("No events on this date.")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List(eventsForSelectedDate) { event in
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundColor(Color(hex:"#7D84B2"))
                                Text(event.description)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex:"#7D84B2"))

                                Text("Scheduled: \(formattedTime(event.scheduledTime))")
                                    .font(.caption)
                                    .foregroundColor(Color(hex:"#7D84B2"))
                                Text(event.locationName ?? "Unknown Location")
                                    .font(.caption)
                                    .foregroundColor(Color(hex:"#7D84B2"))
                            }
                            .listRowBackground(Color(hex: "#E3E5F5"))
                        }
                    }
                }

                Spacer()
            }
            .navigationBarTitle("Schedule", displayMode: .inline)
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
                    self.events = documents.compactMap { doc in
                        ChoreTask(document: doc)
                    }
                }
            }
    }

    func fetchEventsForDate(_ date: Date) {
        guard let userId = appState.user?.id else { return }
        isLoading = true
        let db = Firestore.firestore()

        // Define the start and end of the selected day
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            isLoading = false
            return
        }

        db.collection("events")
            .whereField("participants", arrayContains: userId)
            .whereField("scheduledTime", isGreaterThanOrEqualTo: startOfDay)
            .whereField("scheduledTime", isLessThan: endOfDay)
            .order(by: "scheduledTime", descending: false)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMessage = "Failed to fetch events for selected date: \(error.localizedDescription)"
                } else if let documents = snapshot?.documents {
                    self.eventsForSelectedDate = documents.compactMap { doc in
                        ChoreTask(document: doc)
                    }
                }
            }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CalendarGridView: View {
    @Binding var currentDate: Date
    @Binding var selectedDate: Date?
    var events: [ChoreTask]

    private let calendar = Calendar.current
    private let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack {
            // Days of the Week Header
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(days, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex:"#7D84B2"))
                }
            }

            // Dates Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        Button(action: {
                            selectedDate = date
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundColor(Color(hex:"#7D84B2"))
                                .padding(8)
                                .background(isSelected(date) ? Color(hex: "#E3E5F5") : Color.clear)
                                .clipShape(Circle())
                                .overlay(
                                    // Highlight if there is an event on this day
                                    Circle()
                                        .stroke(Color(hex: "#ECE6F1"), lineWidth: hasEvent(on: date) ? 2 : 0)
                                )
                        }
                        .disabled(!isSameMonth(date))
                        .accessibility(label: Text("Day \(calendar.component(.day, from: date)), \(hasEvent(on: date) ? "has events" : "no events")"))
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    func getDaysInMonth() -> [Date?] {
        var days = [Date?]()

        // Determine first day of the month
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return days
        }

        // Determine the weekday of the first day
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Add empty slots for days before the first weekday
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add all days of the month
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    func isSameMonth(_ date: Date) -> Bool {
        return calendar.component(.month, from: date) == calendar.component(.month, from: currentDate) &&
               calendar.component(.year, from: date) == calendar.component(.year, from: currentDate)
    }

    func hasEvent(on date: Date) -> Bool {
        return events.contains { event in
            calendar.isDate(event.scheduledTime, inSameDayAs: date)
        }
    }

    func isSelected(_ date: Date) -> Bool {
        if let selected = selectedDate {
            return calendar.isDate(selected, inSameDayAs: date)
        }
        return false
    }

    var daysInMonth: [Date?] {
        getDaysInMonth()
    }
}

struct ScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView()
            .environmentObject(AppState())
    }
}
