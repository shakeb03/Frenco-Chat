//
//  FrencoComponents.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI

// MARK: - Design Constants
struct FrencoDesign {
    static let cornerRadius: CGFloat = 24
    static let horizontalPadding: CGFloat = 24
    static let verticalSpacing: CGFloat = 24
    static let animationDuration: Double = 0.5
    static let buttonScalePressed: CGFloat = 0.95
}

// MARK: - Primary Button
struct FrencoPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.frencoButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.matcha)
                .clipShape(Capsule())
                .shadow(
                    color: Color.matcha.opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? FrencoDesign.buttonScalePressed : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// MARK: - Secondary Button
struct FrencoSecondaryButton: View {
    let title: String
    let action: () -> Void
    var showBorder: Bool = true
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.frencoButton)
                .foregroundColor(.wood)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.stone.opacity(0.3))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(showBorder ? Color.wood.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
        .scaleEffect(isPressed ? FrencoDesign.buttonScalePressed : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// MARK: - Card
struct FrencoCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .white
    var showBorder: Bool = true
    
    init(
        backgroundColor: Color = .white,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(FrencoDesign.horizontalPadding)
            .background(backgroundColor.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius)
                    .stroke(
                        showBorder ? Color.wood.opacity(0.1) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Progress Bar
struct FrencoProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 6
    var trackColor: Color = .stone
    var fillColor: Color = .matcha
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(trackColor.opacity(0.3))
                    .frame(height: height)
                
                // Fill
                Capsule()
                    .fill(fillColor)
                    .frame(
                        width: geometry.size.width * min(max(progress, 0), 1),
                        height: height
                    )
                    .animation(.easeOut(duration: FrencoDesign.animationDuration), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Tab Bar Item
struct FrencoTabItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(isSelected ? .matcha : .wood)
            
            Text(label)
                .font(.frencoCaption)
                .foregroundColor(isSelected ? .matcha : .wood)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            isSelected ? Color.matchaLight : Color.clear
        )
        .clipShape(Capsule())
        .animation(.easeOut(duration: 0.3), value: isSelected)
    }
}

// MARK: - Badge
struct FrencoBadge: View {
    let text: String
    var color: Color = .sakura
    
    var body: some View {
        Text(text)
            .font(.frencoCaption)
            .foregroundColor(.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Streak Display
struct FrencoStreakDisplay: View {
    let days: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundColor(.matcha)
            Text("\(days)")
                .font(.frencoButton)
                .foregroundColor(.matcha)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.matchaLight)
        .clipShape(Capsule())
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Glassmorphism Background
struct GlassBackground: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .stroke(Color.stone.opacity(0.3), lineWidth: 1)
            )
    }
}
