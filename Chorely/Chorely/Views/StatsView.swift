import SwiftUI
import FirebaseFirestore
import Combine

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: String = "Daily"
    @State private var selectedFriends: Set<String> = []
    @State private var friendColors: [String: Color] = [:]
    @State private var friendStats: [String: (completed: Int, pending: Int)] = [:] // Real stats
    @State private var progress: CGFloat = 0.0 // Progress percentage
    @State private var friendsScheduledEvents: [String: [(String, Date)]] = [:] // Store scheduled events
    @State private var userCancellable: AnyCancellable?

    var body: some View {
        ScrollView{
            VStack(spacing: 5) {
                Text("Your Statistics")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#7d84b2"))
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                
                ZStack {
                    CircleProgressView(progress: progress, lineWidth: 8, size: 150, color: Color(hex: "#7d84b2"))
                    CircleProgressView(progress: progress, lineWidth: 8, size: 180, color: Color(hex: "#ece6f0"))
                    CircleProgressView(progress: progress, lineWidth: 8, size: 210, color: Color(hex: "#e3e5f5"))
                    
                    VStack {
                        Text("Completed Today")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(width: 240, height: 210)
                .padding()
                
                Picker("", selection: $selectedTab) {
                    Text("Daily").tag("Daily")
                    Text("Monthly").tag("Monthly")
                    Text("Yearly").tag("Yearly")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                MultiSelectDropdown(selectedFriends: $selectedFriends, friends: Array(friendStats.keys))
                    .padding(.bottom, 2)
                
                LineChartView(selectedTab: $selectedTab, selectedFriends: $selectedFriends, friends: Array(friendStats.keys), friendColors: friendColors, friendsScheduledEvents: $friendsScheduledEvents)
                    .frame(height: 250)
                    .padding(.horizontal)
                    .padding(.leading, -22)
                    .padding(.bottom, 20)
                    .foregroundColor(.black)
                
            }
            .padding()
        }
        .onAppear {
            if friendColors.isEmpty {
                fetchFriendsAndStats()
            }
            fetchTodayTasks()

            userCancellable = appState.$user.sink { _ in
                fetchFriendsAndStats()
            }
            
        }
        .onDisappear {
            userCancellable?.cancel()
            userCancellable = nil
        }
        .navigationBarBackButtonHidden(true)
    }

    func fetchFriendsAndStats() {
        guard let user = appState.user else { return }
        let db = Firestore.firestore()

        // Fetch friends' stats
        let friendsToFetch = [user.id] + user.friends
        friendStats = [:]
        friendsScheduledEvents = [:] // Use scheduled events instead of completed events

        db.collection("users")
            .whereField(FieldPath.documentID(), in: friendsToFetch)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching friends' stats: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                for document in documents {
                    if let friend = User(from: document.data()) {
                        friendStats[friend.fullName] = (friend.completedTasksCount, friend.pendingTasksCount)

                        // Fetch scheduled events for this friend
                        db.collection("events")
                            .whereField("participants", arrayContains: friend.id)
                            .addSnapshotListener { eventSnapshot, eventError in
                                if let eventError = eventError {
                                    print("Error fetching scheduled events for \(friend.fullName): \(eventError.localizedDescription)")
                                    return
                                }

                                guard let eventDocuments = eventSnapshot?.documents else { return }

                                let scheduledEvents = eventDocuments.compactMap { doc -> (String, Date)? in
                                    let data = doc.data()
                                    guard let title = data["title"] as? String,
                                          let scheduledTime = (data["scheduledTime"] as? Timestamp)?.dateValue() else {
                                        return nil
                                    }
                                    return (title, scheduledTime)
                                }

                                // Store scheduled events for the friend
                                DispatchQueue.main.async {
                                    self.friendsScheduledEvents[friend.fullName] = scheduledEvents

                                    // Debug print to verify the structure
                                    print("Scheduled events for \(friend.fullName): \(scheduledEvents)")

                                    // Update progress for the current user
                                    if friend.id == user.id {
                                        if let stats = self.friendStats[user.fullName] {
                                            let totalTasks = stats.completed + stats.pending
                                            self.progress = totalTasks > 0 ? CGFloat(stats.completed) / CGFloat(totalTasks) : 0.0
                                        }
                                    }
                                }
                            }
                    }
                }

                // Generate random colors for friends
                DispatchQueue.main.async {
                    self.generateRandomColors()

                    // Initialize selectedFriends with the current user's name
                    self.selectedFriends.insert(user.fullName)
                }
            }
    }

    
    func fetchTodayTasks() {
        guard let userId = appState.user?.id else { return }
        let db = Firestore.firestore()
        
        // Fetch events assigned to the user and scheduled for today
        let todayStart = Calendar.current.startOfDay(for: Date())
        let todayEnd = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
        
        db.collection("events")
            .whereField("participants", arrayContains: userId)
            .whereField("scheduledTime", isGreaterThanOrEqualTo: todayStart)
            .whereField("scheduledTime", isLessThan: todayEnd)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching today's tasks: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let tasks = documents.compactMap { doc in
                    ChoreTask(document: doc)
                }
                
                // Calculate progress
                let totalTasks = tasks.count
                let completedTasks = tasks.filter { $0.completed }.count
                
                DispatchQueue.main.async {
                    self.progress = totalTasks > 0 ? CGFloat(completedTasks) / CGFloat(totalTasks) : 0.0
                }
            }
    }

    

    func generateRandomColors() {
        var generatedColors: Set<Color> = [] // To ensure colors are unique
        friendColors = friendStats.keys.reduce(into: [:]) { result, friend in
//        friendColors = friends.reduce(into: [:]) { result, friend in
            var newColor: Color
            repeat {
                newColor = Color(
                    red: Double.random(in: 0.1...0.9),
                    green: Double.random(in: 0...0.4),
                    blue: Double.random(in: 0.1...1)
                )
            }
            while generatedColors.contains(newColor) // Avoid duplicate colors
            generatedColors.insert(newColor)
            result[friend] = newColor
        }
        print("Generated Colors: \(friendColors)")
    }
}


struct MultiSelectDropdown: View {
    @Binding var selectedFriends: Set<String>
    let friends: [String]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Select Friends")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 7) // Reduced vertical padding
                .padding(.horizontal, 10) // Reduced horizontal padding
                .background(Color(hex: "#eeeeef"))
                .cornerRadius(8)
            }
            .padding(.horizontal, 15)
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(friends, id: \.self) { friend in
                            Button(action: {
                                if selectedFriends.contains(friend) {
                                    selectedFriends.remove(friend)
                                } else {
                                    selectedFriends.insert(friend)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedFriends.contains(friend) ? "checkmark.square" : "square")
                                        .foregroundColor(Color(hex: "#7d84b2"))
                                    Text(friend)
                                        .font(.caption)
                                        .foregroundColor(.black)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxHeight: 150)
                .background(Color(.white))
                .cornerRadius(8)
                .padding(.top, 5)
                .shadow(radius: 5)
            }
        }
        .animation(.easeInOut, value: isExpanded)
    }
}


struct CircleProgressView: View {
    var progress: CGFloat
    var lineWidth: CGFloat
    var size: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: -90))
                .frame(width: size, height: size)
        }
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct LineChartView: View {
    @Binding var selectedTab: String
    @Binding var selectedFriends: Set<String>
    let friends: [String]
    var friendColors: [String: Color]
    @Binding var friendsScheduledEvents: [String: [(String, Date)]]

    let leftMargin: CGFloat = 40

    var body: some View {
        VStack {
            // Legend for friends and colors
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(selectedFriends), id: \.self) { friend in
                        if let color = friendColors[friend] {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 6, height: 6)

                                Text(friend)
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, -2)
            .padding(.bottom, 10)

            // Line chart rendering
            ZStack {
                GeometryReader { geometry in
                    let chartWidth = geometry.size.width - leftMargin
                    let data = getData(for: selectedTab)
                    let yRange = yAxisRange(data: data)

                    let xLabels = getXAxisLabels(for: selectedTab)
                    let xLabelsCount = xLabels.count
                    let xSpacing = chartWidth / CGFloat(max(xLabelsCount - 1, 1))

                    ZStack(alignment: .center) {
                        // Horizontal grid lines and Y-axis labels
                        ForEach(yAxisLabels(yRange: yRange), id: \.self) { label in
                            let yPosition = geometry.size.height - (geometry.size.height * (label / max(yRange.max, 1)))

                            // Grid line
                            Path { path in
                                path.move(to: CGPoint(x: leftMargin, y: yPosition))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: yPosition))
                            }
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)

                            // Y-axis label
                            Text("\(label, specifier: "%.0f")")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .position(x: leftMargin / 2, y: yPosition)
                        }

                        // Render lines and points for each friend
                        ForEach(Array(selectedFriends), id: \.self) { friend in
                            if let points = data[friend],
                               let color = friendColors[friend] {

                                // Ensure data points match the number of labels
                                let validPoints = points.prefix(xLabelsCount)

                                Path { path in
                                    for index in validPoints.indices {
                                        let xPosition = leftMargin + xSpacing * CGFloat(index)
                                        let yPosition = geometry.size.height - (geometry.size.height * (validPoints[index] / max(yRange.max, 1)))

                                        if index == 0 {
                                            path.move(to: CGPoint(x: xPosition, y: yPosition))
                                        } else {
                                            path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                                        }
                                    }
                                }
                                .stroke(color, lineWidth: 2)

                                // Draw points on the line
                                ForEach(validPoints.indices, id: \.self) { index in
                                    let xPosition = leftMargin + xSpacing * CGFloat(index)
                                    let yPosition = geometry.size.height - (geometry.size.height * (validPoints[index] / max(yRange.max, 1)))

                                    Circle()
                                        .fill(color)
                                        .frame(width: 6, height: 6)
                                        .position(x: xPosition, y: yPosition)
                                }
                            }
                        }

                        // X-axis labels
                        ForEach(Array(xLabels.enumerated()), id: \.offset) { index, label in
                            let xPosition = leftMargin + xSpacing * CGFloat(index)
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .position(x: xPosition, y: geometry.size.height + 10)
                        }
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 10)
    }

    // Updated functions for Y-axis labels and range
    func yAxisLabels(yRange: (min: CGFloat, max: CGFloat)) -> [CGFloat] {
        let minY = Int(yRange.min)
        let maxY = Int(ceil(yRange.max))

        if minY == maxY {
            // If min and max are the same, add 1 to max to create a range
            return [CGFloat(minY), CGFloat(maxY + 1)]
        }

        let range = maxY - minY
        let maxLabels = 5 // Maximum number of labels
        let step = max(1, (range + maxLabels - 1) / (maxLabels - 1)) // Ensure at least 1

        var labels = [CGFloat]()
        var current = minY
        while current <= maxY {
            labels.append(CGFloat(current))
            current += step
        }
        // Ensure the last label is maxY
        if labels.last != CGFloat(maxY) {
            labels.append(CGFloat(maxY))
        }
        return labels
    }

    func yAxisRange(data: [String: [CGFloat]]) -> (min: CGFloat, max: CGFloat) {
        let allDataPoints = data.values.flatMap { $0 }
        let max = allDataPoints.max() ?? 1
        let min: CGFloat = 0 // Set min to 0
        return (min, max)
    }

    func getData(for tab: String) -> [String: [CGFloat]] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let now = Date()

        var result: [String: [CGFloat]] = [:]

        for friend in selectedFriends {
            guard let events = friendsScheduledEvents[friend] else {
                result[friend] = []
                continue
            }

            // Use scheduled times
            let eventTimes = events.map { $0.1 }

            // Group events based on the selected tab
            let groupedCounts: [CGFloat]
            switch tab {
            case "Daily":
                // Get the start of the current week
                guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [:] }
                let daysOfWeek = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStart)! }

                groupedCounts = daysOfWeek.map { day in
                    let count = CGFloat(eventTimes.filter {
                        calendar.isDate($0, inSameDayAs: day)
                    }.count)
                    return count
                }
            case "Monthly":
                // Months of the current year
                let months = Array(1...12)
                groupedCounts = months.map { month in
                    let count = CGFloat(eventTimes.filter {
                        calendar.component(.year, from: $0) == calendar.component(.year, from: now) &&
                        calendar.component(.month, from: $0) == month
                    }.count)
                    return count
                }
            case "Yearly":
                // Past three years and current year
                let currentYear = calendar.component(.year, from: now)
                let years = (currentYear - 3...currentYear).map { $0 }
                groupedCounts = years.map { year in
                    let count = CGFloat(eventTimes.filter {
                        calendar.component(.year, from: $0) == year
                    }.count)
                    return count
                }
            default:
                groupedCounts = []
            }

            // Debug: Print grouped counts
            print("Grouped counts for \(friend) on tab \(tab): \(groupedCounts)")

            result[friend] = groupedCounts
        }

        return result
    }

    func getXAxisLabels(for tab: String) -> [String] {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = calendar.timeZone

        switch tab {
        case "Daily":
            dateFormatter.dateFormat = "EEE" // Short day name (e.g., Mon, Tue)
            // Get the start of the current week
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
            let daysOfWeek = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: weekStart)! }
            return daysOfWeek.map { dateFormatter.string(from: $0) }
        case "Monthly":
            dateFormatter.dateFormat = "MMM" // Short month name (e.g., Jan, Feb)
            let months = (1...12).map { month -> String in
                let dateComponents = DateComponents(year: calendar.component(.year, from: now), month: month)
                if let date = calendar.date(from: dateComponents) {
                    return dateFormatter.string(from: date)
                }
                return ""
            }
            return months
        case "Yearly":
            let currentYear = calendar.component(.year, from: now)
            let years = (currentYear - 3...currentYear).map { "\($0)" }
            return years
        default:
            return []
        }
    }
}



struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .foregroundColor(configuration.isOn ? Color(hex: "#7d84b2") : Color.gray)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
