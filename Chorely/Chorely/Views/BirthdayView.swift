//
//  BirthdayView.swift
//  Chorely
//
//  Created by Samuel Dobson on 11/12/24.
//

import SwiftUI

struct BirthdayView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigateToLookingFor = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.2) // 20% from top

                // "Enter Birthday" Text
                Text("Enter Birthday")
                    .font(Font.custom("Roboto-ExtraBold", size: 28))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding(.bottom, 20)
                    .accessibility(addTraits: .isHeader)

                // Birthday DatePicker
                DatePicker("Birthday", selection: $appState.registrationBirthday, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .font(Font.custom("Roboto-Regular", size: 16))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .padding()
                    .background(Color(hex: "D9DBF1"))
                    .cornerRadius(8)
                    .padding([.leading, .trailing], 20)
                    .accentColor(Color(hex: "7D84B2"))
                    .accessibility(label: Text("Birthday DatePicker"))

                Spacer()

                // "Continue" Button
                Button(action: {
                    navigateToLookingFor = true
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
                .accessibility(hint: Text("Proceed to selecting options"))

                // Hidden NavigationLink to WhatLookingForView
                NavigationLink(
                    destination: WhatLookingForView(),
                    isActive: $navigateToLookingFor
                ) {
                    EmptyView()
                }
            }
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
        }
    }
}
