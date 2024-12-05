//
//  ChorelyApp.swift
//  Chorely
//
//  Created by Sam Dobson
//

import SwiftUI
import Firebase // Ensure Firebase is imported

@main
struct ChorelyApp: App {
    // Integrate AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState = AppState()
    @StateObject private var selectedTasks = SelectedTasks()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(selectedTasks)
        }
    }
}
