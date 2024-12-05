//
//  CreateAccountView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct CreateAccountView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToFullName = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.2) // 20% from top

                // "Create Account" Text
                Text("Create Account")
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
                SecureField("Create Password", text: $appState.registrationPassword)
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accessibility(label: Text("Create Password SecureField"))

                // Phone Number TextField
                TextField("Phone Number", text: $appState.registrationPhoneNumber)
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .keyboardType(.phonePad)
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accessibility(label: Text("Phone Number TextField"))

                Spacer()

                // "Continue" Button
                Button(action: {
                    if validate() {
                        navigateToFullName = true
                    }
                }) {
                    Text("Continue")
                        .font(Font.custom("Roboto-Regular", size: 18))
                        .foregroundColor(Color(hex: "7D84B2"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FFE785"))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                }
                .padding([.leading, .trailing, .bottom], 20)
                .accessibility(label: Text("Continue Button"))

                // Hidden NavigationLink to FullNameView
                NavigationLink(
                    destination: FullNameView(),
                    isActive: $navigateToFullName
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Invalid Input"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // Validation Function
    func validate() -> Bool {
        if appState.registrationEmail.isEmpty || appState.registrationPassword.isEmpty || appState.registrationPhoneNumber.isEmpty {
            alertMessage = "Please enter email, password, and phone number."
            showingAlert = true
            return false
        }
        // Add more validation as needed
        if !isValidEmail(appState.registrationEmail) {
            alertMessage = "Please enter a valid email address."
            showingAlert = true
            return false
        }

        if !isValidPhoneNumber(appState.registrationPhoneNumber) {
            alertMessage = "Please enter a valid phone number."
            showingAlert = true
            return false
        }

        if appState.registrationPassword.count < 6 {
            alertMessage = "Password must be at least 6 characters long."
            showingAlert = true
            return false
        }

        return true
    }

    // Email Validation Function
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    // Phone Number Validation Function
    func isValidPhoneNumber(_ phone: String) -> Bool {
        // Simple regex for phone number validation
        let phoneRegEx = "^\\+?[0-9]{10,15}$" // Adjust according to your requirements
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
}
