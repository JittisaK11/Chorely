//
//  WhatLookingForView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct WhatLookingForView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedOptions: [String] = []
    @State private var navigateToHome = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    let options = ["Groceries & Cooking", "Cleaning", "Laundry", "Exercise", "Study", "Other"]

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.2) // 20% from top

                // "What are you looking to get done?" Text
                Text("What are you looking to get done?")
                    .font(Font.custom("Roboto-ExtraBold", size: 24))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding(.bottom, 20)
                    .accessibility(addTraits: .isHeader)

                // Options Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            toggleSelection(option)
                        }) {
                            Text(option)
                                .font(Font.custom("Roboto-Regular", size: 16))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(selectedOptions.contains(option) ? Color(hex: "7D84B2") : Color(hex: "D9DBF1"))
                                .foregroundColor(selectedOptions.contains(option) ? .white : Color(hex: "7D84B2"))
                                .cornerRadius(8)
                        }
                        .accessibility(label: Text(option))
                        .accessibility(addTraits: selectedOptions.contains(option) ? .isSelected : .isButton)
                    }
                }
                .padding([.leading, .trailing], 20)

                Spacer()

                // "Continue" Button
                Button(action: {
                    createAccount()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "7D84B2")))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FFE785"))
                            .cornerRadius(8)
                    } else {
                        Text("Continue")
                            .font(Font.custom("Roboto-Regular", size: 18))
                            .foregroundColor(Color(hex: "7D84B2"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedOptions.isEmpty ? Color.gray.opacity(0.3) : Color(hex: "FFE785"))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                    }
                }
                .padding([.leading, .trailing, .bottom], 20)
                .disabled(selectedOptions.isEmpty || isLoading)
                .accessibility(label: Text("Continue Button"))
                .accessibility(hint: Text(selectedOptions.isEmpty ? "Select at least one option to continue" : "Proceed to the home screen"))

                // Hidden NavigationLink to HomeView
                NavigationLink(
                    destination: HomeView(),
                    isActive: $navigateToHome
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
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

    // Toggle Selection Function
    func toggleSelection(_ option: String) {
        if let index = selectedOptions.firstIndex(of: option) {
            selectedOptions.remove(at: index)
        } else {
            selectedOptions.append(option)
        }
    }

    // Create Account Function
    func createAccount() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        appState.registerUser(
            email: appState.registrationEmail,
            password: appState.registrationPassword,
            fullName: appState.registrationFullName,
            phoneNumber: appState.registrationPhoneNumber,
            birthday: appState.registrationBirthday,
            lookingFor: selectedOptions
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    navigateToHome = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct WhatLookingForView_Previews: PreviewProvider {
    static var previews: some View {
        WhatLookingForView()
            .environmentObject(AppState())
            .environmentObject(SelectedTasks())
    }
}
