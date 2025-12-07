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
            if clerk.user == nil {
                // Not signed in
                SignInView()
            } else if !appData.onboardingCompleted {
                // Signed in but not onboarded
                OnboardingView()
            } else {
                // Signed in and onboarded
                MainTabView()
            }
        }
        .animation(.easeOut(duration: 0.3), value: clerk.user != nil)
        .animation(.easeOut(duration: 0.3), value: appData.onboardingCompleted)
    }
}
