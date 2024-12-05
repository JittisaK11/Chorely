//
//  LoadingAnimationView.swift
//  Chorely
//
//  Created by Melisa Zhang on 12/2/24.
//


import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loopMode
        animationView.contentMode = .scaleAspectFit
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

struct LoadingAnimationView: View {
    @State private var isLoadingComplete = false

    var body: some View {
        ZStack {
            LottieView(animationName: "LoadingAnimation", loopMode: .playOnce)
                .frame(width: 300, height: 300)

            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    isLoadingComplete = true
                }
            }
        }
        .fullScreenCover(isPresented: $isLoadingComplete) {
            ContentView()
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingAnimationView()
    }
}

