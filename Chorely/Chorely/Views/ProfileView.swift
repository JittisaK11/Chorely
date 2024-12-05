//
//  ProfileView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/20/24.
//

import SwiftUI

extension UIColor {
    // Helper to create UIColor from hex string
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingChangeEmail = false
    @State private var showingChangePhone = false
    @State private var showingSignOutAlert = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    init() {
     // Large Navigation Title
     UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(hex:"#7D84B2")]
     // Inline Navigation Title
     UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(hex:"#7D84B2")]
   }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    HStack {
                        Text("Full Name")
                            .foregroundColor(Color(hex:"#7D84B2"))
                        Spacer()
                        Text(appState.user?.fullName ?? "")
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Email")
                            .foregroundColor(Color(hex:"#7D84B2"))
                        Spacer()
                        Text(appState.user?.email ?? "")
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        showingChangeEmail = true
                    }
                    HStack {
                        Text("Phone Number")
                            .foregroundColor(Color(hex:"#7D84B2"))
                        Spacer()
                        Text(appState.user?.phoneNumber ?? "")
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        showingChangePhone = true
                    }
                }
                .listRowBackground(Color(hex: "E3E5F5"))
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(Color(hex:"#7D84B2"))
                            .bold()
                    }
                    .accessibilityLabel("Sign Out Button")
                }
                
            }
            
            .navigationTitle("Profile")
            .sheet(isPresented: $showingChangeEmail) {
                ChangeEmailView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingChangePhone) {
                ChangePhoneView()
                    .environmentObject(appState)
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil || successMessage != nil },
                set: { _ in
                    errorMessage = nil
                    successMessage = nil
                }
            )) {
                if let errorMessage = errorMessage {
                    return Alert(title: Text("Error"),
                                 message: Text(errorMessage),
                                 dismissButton: .default(Text("OK")))
                } else if let successMessage = successMessage {
                    return Alert(title: Text("Success"),
                                 message: Text(successMessage),
                                 dismissButton: .default(Text("OK")))
                } else {
                    return Alert(title: Text(""),
                                 message: Text(""),
                                 dismissButton: .default(Text("OK")))
                }
            }
            .alert(isPresented: $showingSignOutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        appState.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppState())
    }
}
