//
//  RootView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct RootView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    
    var body: some View {
        Group {
            if clerk.user != nil {
                // User is signed in
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Not signed in - show sign in
                SignInView()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.easeOut(duration: 0.4), value: clerk.user?.id)
    }
}

// MARK: - Preview
#Preview {
    RootView()
        .environment(\.clerk, Clerk.shared)
        .environmentObject(AppDataManager())
}
