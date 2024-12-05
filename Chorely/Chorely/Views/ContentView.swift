//
//  ContentView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLoading {
            LoadingAnimationView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        appState.stopLoading()
                    }
                }
        } else {
            if appState.isSignedIn {
                // Main TabView with Bottom Navigation Bar
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    FriendsView()
                        .tabItem {
                            Label("Friends", systemImage: "person.2.fill")
                        }
                    ScheduleView()
                        .tabItem {
                            Label("Schedule", systemImage: "calendar")
                        }
                    StatsView()
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar.fill")
                        }
                    ProfileView() // New Profile Tab
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
                .accentColor(Color(hex:"#7D84B2"))
                .environmentObject(appState)
            } else {
                // Welcome Screen within NavigationView
                NavigationView {
                    WelcomeView()
                        .navigationBarHidden(true) // Hide navigation bar on WelcomeView
                }
                .environmentObject(appState)
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
                .environmentObject(AppState())
        }
    }
}
