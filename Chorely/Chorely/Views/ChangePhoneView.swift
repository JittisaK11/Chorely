//
//  ChangePhoneView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/26/24.
//


//
//  ChangePhoneView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/20/24.
//

import SwiftUI

struct ChangePhoneView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var newPhoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Phone Number")) {
                    TextField("Enter new phone number", text: $newPhoneNumber)
                        .keyboardType(.phonePad)
                        .accessibility(label: Text("New Phone Number TextField"))
                }
                
                Section {
                    Button(action: changePhoneNumber) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Update Phone Number")
                        }
                    }
                    .disabled(newPhoneNumber.isEmpty || isLoading)
                }
            }
            .navigationTitle("Change Phone")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Phone Number Update"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")) {
                          presentationMode.wrappedValue.dismiss()
                      })
            }
        }
    }
    
    func changePhoneNumber() {
        guard !newPhoneNumber.isEmpty else {
            alertMessage = "Please enter a new phone number."
            showingAlert = true
            return
        }
        
        guard isValidPhoneNumber(newPhoneNumber) else {
            alertMessage = "Please enter a valid phone number."
            showingAlert = true
            return
        }
        
        isLoading = true
        
        appState.updatePhoneNumber(to: newPhoneNumber) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    alertMessage = "Phone number updated successfully."
                case .failure(let error):
                    alertMessage = "Failed to update phone number: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }
    
    // Phone Number Validation Function
    func isValidPhoneNumber(_ phone: String) -> Bool {
        // Simple regex for phone number validation
        let phoneRegEx = "^\\+?[0-9]{10,15}$" // Adjust according to your requirements
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone)
    }
}

struct ChangePhoneView_Previews: PreviewProvider {
    static var previews: some View {
        ChangePhoneView()
            .environmentObject(AppState())
    }
}
