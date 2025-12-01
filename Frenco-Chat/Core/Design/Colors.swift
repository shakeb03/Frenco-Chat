//
//  Colors.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI

// MARK: - Ikigai Color Palette
extension Color {
    // Primary Backgrounds
    static let paper = Color(hex: "F9F7F2")      // Main background - warm off-white
    static let stone = Color(hex: "E5E5E5")      // iPad/Desktop surrounding background
    
    // Text Colors
    static let ink = Color(hex: "2C2C2C")        // Primary text - soft charcoal
    static let wood = Color(hex: "8D7B68")       // Secondary text, subtitles
    static let clay = Color(hex: "D6CEC3")       // Borders, disabled, placeholders
    
    // Primary Action - Matcha
    static let matcha = Color(hex: "5C7F67")     // Primary action, success, active
    static let matchaLight = Color(hex: "E8F1EB") // Active item backgrounds
    
    // Accent - Sakura
    static let sakura = Color(hex: "EACAC0")     // Accents, avatars, badges
    static let sakuraLight = Color(hex: "F8F0EE") // Warm section backgrounds
}

// MARK: - Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Semantic Colors
extension Color {
    static let primaryBackground = Color.paper
    static let primaryText = Color.ink
    static let secondaryText = Color.wood
    static let primaryAction = Color.matcha
    static let accent = Color.sakura
    static let border = Color.clay
    static let disabled = Color.clay
}
