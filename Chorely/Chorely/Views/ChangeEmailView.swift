//
//  ChangeEmailView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/26/24.
//


//
//  ChangeEmailView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/20/24.
//

import SwiftUI

struct ChangeEmailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var newEmail: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Email")) {
                    TextField("Enter new email", text: $newEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibility(label: Text("New Email TextField"))
                }
                
                Section {
                    Button(action: changeEmail) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Update Email")
                        }
                    }
                    .disabled(newEmail.isEmpty || isLoading)
                }
            }
            .navigationTitle("Change Email")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Email Update"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")) {
                          presentationMode.wrappedValue.dismiss()
                      })
            }
        }
    }
    
    func changeEmail() {
        guard !newEmail.isEmpty else {
            alertMessage = "Please enter a new email."
            showingAlert = true
            return
        }
        
        guard isValidEmail(newEmail) else {
            alertMessage = "Please enter a valid email address."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        appState.updateEmail(to: newEmail) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Email updated successfully."
                case .failure(let error):
                    alertMessage = "Failed to update email: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    // Email Validation Function
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct ChangeEmailView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeEmailView()
            .environmentObject(AppState())
    }
}
