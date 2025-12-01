//
//  AuthManager.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

// MARK: - Auth Helper Extension
// Helper to get user info from Clerk's shared instance

extension Clerk {
    // Get user's display name
    var displayName: String {
        if let firstName = user?.firstName, !firstName.isEmpty {
            return firstName
        }
        if let email = user?.primaryEmailAddress?.emailAddress {
            return email.components(separatedBy: "@").first ?? "Learner"
        }
        return "Learner"
    }
    
    // Get user's initials for avatar
    var initials: String {
        let name = displayName
        return String(name.prefix(1)).uppercased()
    }
}
