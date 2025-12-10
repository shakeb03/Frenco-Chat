//
//  Frenco_ChatApp.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
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
                Log.debug("🔐 Auth state changed: \(oldValue ?? "nil") -> \(newValue ?? "nil")")
                Task {
                    if let user = clerk.user {
                        Log.debug("✅ User signed in: \(user.id)")
                        SupabaseManager.shared.setUserId(user.id)
                        await appData.initializeForUser(
                            clerkUserId: user.id,
                            email: user.primaryEmailAddress?.emailAddress,
                            displayName: user.firstName
                        )
                    } else {
                        Log.debug("👋 User signed out")
                        SupabaseManager.shared.clearUser()
                        appData.clearData()
                    }
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    private func initializeApp() async {
        Log.debug("🚀 Initializing app...")
        
        // Configure Clerk
        // ⚠️ REPLACE WITH YOUR ACTUAL CLERK PUBLISHABLE KEY
        clerk.configure(publishableKey: "pk_test_YmlnLW1hY2F3LTQuY2xlcmsuYWNjb3VudHMuZGV2JA")
        Log.debug("✅ Clerk configured")
        
        // Load Clerk
        do {
            try await clerk.load()
            Log.debug("✅ Clerk loaded")
        } catch {
            Log.debug("❌ Clerk load error: \(error)")
        }
        
        // If user is signed in, initialize app data
        if let user = clerk.user {
            Log.debug("👤 Found existing user: \(user.id)")
            SupabaseManager.shared.setUserId(user.id)
            await appData.initializeForUser(
                clerkUserId: user.id,
                email: user.primaryEmailAddress?.emailAddress,
                displayName: user.firstName
            )
        } else {
            Log.debug("👤 No user signed in")
        }
        
        isLoading = false
        Log.debug("🎉 App initialization complete")
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
