//
//  FullNameView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct FullNameView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToBirthday = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.2) // 20% from top

                // "Enter Full Name" Text
                Text("Enter Full Name")
                    .font(Font.custom("Roboto-ExtraBold", size: 28))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding(.bottom, 20)
                    .accessibility(addTraits: .isHeader)

                // Full Name TextField
                TextField("Full Name", text: $appState.registrationFullName)
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accessibility(label: Text("Full Name TextField"))

                Spacer()

                // "Continue" Button
                Button(action: {
                    if validate() {
                        navigateToBirthday = true
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

                // Hidden NavigationLink to BirthdayView
                NavigationLink(
                    destination: BirthdayView(),
                    isActive: $navigateToBirthday
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
        if appState.registrationFullName.isEmpty {
            alertMessage = "Please enter your full name."
            showingAlert = true
            return false
        }
        return true
    }
}
