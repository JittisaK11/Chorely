//
//  SignInView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.2) // 20% from top

                // "Sign In" Text
                Text("Sign In")
                    .font(Font.custom("Roboto-ExtraBold", size: 28))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding(.bottom, 20)
                    .accessibility(addTraits: .isHeader)

                // Email TextField
                TextField("Email", text: $appState.registrationEmail)
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accessibility(label: Text("Email TextField"))

                // Password SecureField
                SecureField("Password", text: $appState.registrationPassword)
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accessibility(label: Text("Password SecureField"))

                Spacer()

                // "Sign In" Button
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "7D84B2")))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FFE785"))
                            .cornerRadius(8)
                    } else {
                        Text("Sign In")
                            .font(Font.custom("Roboto-Regular", size: 18))
                            .foregroundColor(Color(hex: "7D84B2"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FFE785"))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                }
                .padding([.leading, .trailing, .bottom], 20)
                .accessibility(label: Text("Sign In Button"))
                .disabled(isLoading)

                // Hidden NavigationLink to HomeView
                NavigationLink(
                    destination: HomeView(),
                    isActive: $appState.isSignedIn
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Sign In Failed"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // Sign-In Function
    func signIn() {
        guard !appState.registrationEmail.isEmpty, !appState.registrationPassword.isEmpty else {
            alertMessage = "Please enter both email and password."
            showingAlert = true
            return
        }

        isLoading = true

        appState.signIn { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    // Successful sign-in: isSignedIn is already set via AppState's auth listener
                    print("User signed in successfully.")
                case .failure(let error):
                    // Handle failure: display the error in an alert
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }

    struct SignInView_Previews: PreviewProvider {
        static var previews: some View {
            SignInView()
                .environmentObject(AppState())
        }
    }
}
