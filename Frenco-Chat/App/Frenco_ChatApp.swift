//
//  Frenco_ChatApp.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
// pk_test_bG92aW5nLXBvc3N1bS03LmNsZXJrLmFjY291bnRzLmRldiQ
//

import SwiftUI
import Clerk

@main
struct Frenco_ChatApp: App {
    @State private var clerk = Clerk.shared
    @StateObject private var appData = AppDataManager()
    @State private var isLoading = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    LoadingView()
                } else {
                    RootView()
                }
            }
            .environment(\.clerk, clerk)
            .environmentObject(appData)
            .task {
                await initializeApp()
            }
            // Listen for auth state changes
            .onChange(of: clerk.user?.id) { oldValue, newValue in
                print("🔐 Auth state changed: \(oldValue ?? "nil") -> \(newValue ?? "nil")")
                Task {
                    if let user = clerk.user {
                        print("✅ User signed in: \(user.id)")
                        await appData.initializeForUser(
                            clerkUserId: user.id,
                            email: user.primaryEmailAddress?.emailAddress,
                            displayName: user.firstName
                        )
                    } else {
                        print("👋 User signed out")
                        appData.clearData()
                    }
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    private func initializeApp() async {
        print("🚀 Initializing app...")
        
        // Configure Clerk
        // ⚠️ REPLACE WITH YOUR ACTUAL CLERK PUBLISHABLE KEY
        clerk.configure(publishableKey: "pk_test_bG92aW5nLXBvc3N1bS03LmNsZXJrLmFjY291bnRzLmRldiQ")
        print("✅ Clerk configured")
        
        // Load Clerk
        do {
            try await clerk.load()
            print("✅ Clerk loaded")
        } catch {
            print("❌ Clerk load error: \(error)")
        }
        
        // If user is signed in, initialize app data
        if let user = clerk.user {
            print("👤 Found existing user: \(user.id)")
            await appData.initializeForUser(
                clerkUserId: user.id,
                email: user.primaryEmailAddress?.emailAddress,
                displayName: user.firstName
            )
        } else {
            print("👤 No user signed in")
        }
        
        isLoading = false
        print("🎉 App initialization complete")
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.matchaLight)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(Color.matcha.opacity(0.3), lineWidth: 2)
                        .frame(width: 90, height: 90)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                    
                    Text("文")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.matcha)
                }
                
                Text("Loading...")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
