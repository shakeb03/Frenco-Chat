//
//  Typography.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI

// MARK: - Typography System
// Primary: Zen Maru Gothic (rounded, approachable)
// Secondary: Cormorant Garamond (editorial, poetic)

struct FrencoFont {
    // MARK: - Font Names
    // Note: Add these fonts to your project and Info.plist
    static let zenMaru = "ZenMaruGothic"
    static let cormorant = "CormorantGaramond"
    
    // MARK: - Zen Maru Gothic Variants
    enum ZenMaru {
        static func regular(_ size: CGFloat) -> Font {
            .custom("\(zenMaru)-Regular", size: size)
        }
        static func medium(_ size: CGFloat) -> Font {
            .custom("\(zenMaru)-Medium", size: size)
        }
        static func bold(_ size: CGFloat) -> Font {
            .custom("\(zenMaru)-Bold", size: size)
        }
    }
    
    // MARK: - Cormorant Garamond Variants
    enum Cormorant {
        static func regular(_ size: CGFloat) -> Font {
            .custom("\(cormorant)-Regular", size: size)
        }
        static func italic(_ size: CGFloat) -> Font {
            .custom("\(cormorant)-Italic", size: size)
        }
        static func semiBoldItalic(_ size: CGFloat) -> Font {
            .custom("\(cormorant)-SemiBoldItalic", size: size)
        }
    }
}

// MARK: - Text Style Presets
extension Font {
    // Headers - Cormorant Garamond Italic
    static let frencoH1 = FrencoFont.Cormorant.italic(32)
    static let frencoH2 = FrencoFont.Cormorant.italic(28)
    static let frencoH3 = FrencoFont.Cormorant.italic(24)
    
    // Quotes - Cormorant Garamond Italic
    static let frencoQuote = FrencoFont.Cormorant.italic(24)
    
    // Subtitles - Zen Maru Uppercase with tracking
    static let frencoSubtitle = FrencoFont.ZenMaru.medium(11)
    
    // Body - Zen Maru Regular
    static let frencoBody = FrencoFont.ZenMaru.regular(16)
    static let frencoBodySmall = FrencoFont.ZenMaru.regular(14)
    
    // Buttons & Labels
    static let frencoButton = FrencoFont.ZenMaru.medium(16)
    static let frencoLabel = FrencoFont.ZenMaru.regular(14)
    static let frencoCaption = FrencoFont.ZenMaru.regular(12)
}

// MARK: - Text Style View Modifiers
struct FrencoTextStyle: ViewModifier {
    enum Style {
        case h1, h2, h3
        case subtitle
        case body, bodySmall
        case quote
        case button
        case caption
    }
    
    let style: Style
    
    func body(content: Content) -> some View {
        switch style {
        case .h1:
            content
                .font(.frencoH1)
                .foregroundColor(.ink)
        case .h2:
            content
                .font(.frencoH2)
                .foregroundColor(.ink)
        case .h3:
            content
                .font(.frencoH3)
                .foregroundColor(.ink)
        case .subtitle:
            content
                .font(.frencoSubtitle)
                .foregroundColor(.wood)
                .tracking(2.0)
                .textCase(.uppercase)
        case .body:
            content
                .font(.frencoBody)
                .foregroundColor(.ink)
                .lineSpacing(6) // 1.6 line height approximation
        case .bodySmall:
            content
                .font(.frencoBodySmall)
                .foregroundColor(.ink)
        case .quote:
            content
                .font(.frencoQuote)
                .foregroundColor(.ink)
                .italic()
        case .button:
            content
                .font(.frencoButton)
        case .caption:
            content
                .font(.frencoCaption)
                .foregroundColor(.wood)
        }
    }
}

extension View {
    func frencoTextStyle(_ style: FrencoTextStyle.Style) -> some View {
        modifier(FrencoTextStyle(style: style))
    }
}

// MARK: - Fallback System Fonts (Use until custom fonts are added)
extension Font {
    // Temporary fallbacks using system fonts
    static let frencoH1Fallback: Font = .system(size: 32, weight: .light, design: .serif)
    static let frencoH2Fallback: Font = .system(size: 28, weight: .light, design: .serif)
    static let frencoBodyFallback: Font = .system(size: 16, weight: .regular, design: .rounded)
    static let frencoSubtitleFallback: Font = .system(size: 11, weight: .medium, design: .rounded)
}
