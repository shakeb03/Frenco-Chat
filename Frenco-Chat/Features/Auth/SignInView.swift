//
//  SignInView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct SignInView: View {
    @Environment(\.clerk) private var clerk
    @State private var isShowingAuth = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.white, Color.paper],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Branding
                BrandingSection()
                
                Spacer()
                
                // Sign In Button
                VStack(spacing: 16) {
                    FrencoPrimaryButton(title: "Get Started") {
                        isShowingAuth = true
                    }
                    
                    // Terms
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.clay)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.bottom, 48)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .sheet(isPresented: $isShowingAuth) {
            // Clerk's built-in AuthView handles everything
            AuthView()
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Branding Section
struct BrandingSection: View {
    var body: some View {
        VStack(spacing: 32) {
            // App Icon / Logo
            ZStack {
                Circle()
                    .fill(Color.matchaLight)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(Color.matcha.opacity(0.3), lineWidth: 2)
                    .frame(width: 130, height: 130)
                
                Text("文")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.matcha)
            }
            
            // App Name
            VStack(spacing: 12) {
                Text("Frenco")
                    .font(.system(size: 42, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.ink)
                
                Text("LEARN FRENCH")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(3)
                    .foregroundColor(.wood)
            }
            
            // Tagline
            Text("Your gentle path to\nFrench fluency")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.top, 8)
        }
    }
}

// MARK: - Preview
#Preview {
    SignInView()
        .environment(\.clerk, Clerk.shared)
}
