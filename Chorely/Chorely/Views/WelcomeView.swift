// WelcomeView.swift
// Chorely
//
// Created by Samuel Dobson.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Background Gradient
            BackgroundGradient()
                .edgesIgnoringSafeArea(.all)
            
            // Confetti Animation
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }

            // Main Content
            VStack(spacing: 40) {
                LogoView()
                WelcomeTextView()
                ButtonsView()
            }
            .padding()
        }
        .onAppear {
            // Trigger the confetti animation
            showConfetti = true
            // Removed the code that hides the confetti after 8 seconds
        }
    }
}

// MARK: - BackgroundGradient
struct BackgroundGradient: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.white, Color(hex: "7D84B2")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - LogoView
struct LogoView: View {
    @State private var animate = false
    
    var body: some View {
        Image("Logo") // Ensure you have an image named "Logo" in your assets
            .resizable()
            .scaledToFit()
            .frame(width: 180, height: 180)
            .accessibilityLabel("Chorely Logo")
            .shadow(color: Color(hex: "7D84B2").opacity(0.6), radius: 10, x: 0, y: 5)
            .scaleEffect(animate ? 1.05 : 1.0)
    }
}

// MARK: - WelcomeTextView
struct WelcomeTextView: View {
    var body: some View {
        Text("CHORELY")
            .font(Font.custom("Roboto-ExtraBold", size: 48))
            .foregroundColor(Color(hex: "7D84B2"))
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .accessibility(addTraits: .isHeader)
    }
}

// MARK: - ButtonsView
struct ButtonsView: View {
    var body: some View {
        VStack(spacing: 20) {
            // "Sign In" Button
            NavigationLink(destination: SignInView()) { // Ensure SignInView exists
                Text("Sign In")
                    .font(Font.custom("Roboto-Medium", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "7D84B2"))
                    .cornerRadius(10)
                    .shadow(color: Color(hex: "7D84B2").opacity(0.5), radius: 5, x: 0, y: 3)
            }
            .accessibilityLabel("Sign In Button")
            
            // "Create Account" Button
            NavigationLink(destination: CreateAccountView()) { // Ensure CreateAccountView exists
                Text("Create Account")
                    .font(Font.custom("Roboto-Medium", size: 18))
                    .foregroundColor(Color(hex: "7D84B2"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "7D84B2"), lineWidth: 2)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color(hex: "7D84B2").opacity(0.5), radius: 5, x: 0, y: 3)
            }
            .accessibilityLabel("Create Account Button")
        }
        .padding([.leading, .trailing], 20)
    }
}

// MARK: - ConfettiView
struct ConfettiView: View {
    let numberOfParticles = 15 // Increased number for more confetti
    @State private var particles: [Particle] = []
    let confettiColor: Color = .white

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiParticleView(particle: particle, screenHeight: geometry.size.height)
                }
            }
            .onAppear {
                // Initialize particles only once
                if particles.isEmpty {
                    for _ in 0..<numberOfParticles {
                        let size = CGFloat.random(in: 30...50) // Increased size for bigger confetti
                        let xPosition = CGFloat.random(in: 0...geometry.size.width)
                        let yPosition = CGFloat.random(in: -geometry.size.height...0)
                        let duration = Double.random(in: 5...8) // Ensures animation lasts up to 8 seconds
                        let delay = Double.random(in: 0...3) // Delays to stagger the animations
                        let opacity = Double.random(in: 0.7...1.0)
                        
                        let particle = Particle(
                            id: UUID(),
                            size: size,
                            xPosition: xPosition,
                            yPosition: yPosition,
                            duration: duration,
                            delay: delay,
                            opacity: opacity,
                            color: confettiColor
                        )
                        particles.append(particle)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Particle Model
    struct Particle: Identifiable {
        let id: UUID
        let size: CGFloat
        let xPosition: CGFloat
        var yPosition: CGFloat
        let duration: Double
        let delay: Double
        let opacity: Double
        let color: Color
    }
}

// MARK: - ConfettiParticleView
struct ConfettiParticleView: View {
    let particle: ConfettiView.Particle
    let screenHeight: CGFloat
    
    @State private var currentYPosition: CGFloat
    
    init(particle: ConfettiView.Particle, screenHeight: CGFloat) {
        self.particle = particle
        self.screenHeight = screenHeight
        self._currentYPosition = State(initialValue: particle.yPosition)
    }
    
    var body: some View {
        Image("Logo") // Using the Logo image as confetti
            .resizable()
            .scaledToFit()
            .frame(width: particle.size, height: particle.size)
            .position(x: particle.xPosition, y: currentYPosition)
            .opacity(particle.opacity)
            .rotationEffect(Angle(degrees: Double.random(in: 0...360))) // Random rotation
            .onAppear {
                withAnimation(Animation.linear(duration: particle.duration).delay(particle.delay)) {
                    // Move the particle below the screen
                    currentYPosition += screenHeight + particle.size
                }
            }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState())
    }
}
