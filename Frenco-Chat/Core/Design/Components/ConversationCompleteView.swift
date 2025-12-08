//
//  ConversationCompleteView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

// Features/Chat/Components/ConversationCompleteView.swift

import SwiftUI

struct ConversationCompleteView: View {
    let scenario: ConversationScenario
    let messagesCount: Int
    let correctionsCount: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.matchaLight)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.matcha)
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Conversation Complete!")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundColor(.ink)
                
                Text("You completed the \(scenario.titleFr) scenario")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                    .multilineTextAlignment(.center)
            }
            
            // Stats
            HStack(spacing: 24) {
                StatItem(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(messagesCount)",
                    label: "Messages"
                )
                
                StatItem(
                    icon: "lightbulb.fill",
                    value: "\(correctionsCount)",
                    label: "Tips"
                )
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            .background(Color.clay)
            .cornerRadius(16)
            
            // Encouragement
            Text(encouragementMessage)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Done button
            Button(action: onDismiss) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.matcha)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.paper.ignoresSafeArea())
    }
    
    private var encouragementMessage: String {
        if correctionsCount == 0 {
            return "Perfect! You made no mistakes. Excellent work! 🌟"
        } else if correctionsCount <= 2 {
            return "Great job! Just a few small tips to remember. Keep practicing! 💪"
        } else {
            return "Good effort! Practice makes perfect. Try again to improve! 📚"
        }
    }
}

// MARK: - Stat Item
private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.matcha)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.ink)
            
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Preview
#Preview {
    ConversationCompleteView(
        scenario: ConversationScenario(
            id: UUID(),
            title: "Café",
            titleFr: "Au café",
            description: "Order a coffee and pastry",
            iconName: "cup.and.saucer.fill",
            level: "A1",
            aiRole: "Marie, a friendly café server",
            openingMessage: "Bonjour!",
            goalDescription: "Order a drink and pastry",
            targetVocabulary: ["café", "croissant"],
            systemPrompt: "",
            sortOrder: 1,
            isActive: true
        ),
        messagesCount: 8,
        correctionsCount: 2,
        onDismiss: {}
    )
}
