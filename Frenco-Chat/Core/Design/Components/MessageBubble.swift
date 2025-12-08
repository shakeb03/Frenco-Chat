//
//  MessageBubble.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

// Features/Chat/Components/MessageBubble.swift

import SwiftUI

struct MessageBubble: View {
    let message: ConversationMessage
    let aiName: String
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
            // Message bubble
            HStack {
                if isUser { Spacer(minLength: 60) }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(isUser ? .white : .ink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isUser ? Color.matcha : Color.clay)
                .cornerRadius(20)
                .cornerRadius(isUser ? 20 : 20, corners: isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                if !isUser { Spacer(minLength: 60) }
            }
            
            // Correction card (only for assistant messages with corrections)
            if !isUser, let correction = message.correction, !correction.isEmpty {
                CorrectionCard(correction: correction)
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        MessageBubble(
            message: ConversationMessage(
                id: UUID(),
                conversationId: UUID(),
                role: .assistant,
                content: "Bonjour! Bienvenue au café. Qu'est-ce que je vous sers aujourd'hui?",
                correction: nil,
                vocabularyUsed: nil,
                isGoalComplete: false,
                createdAt: Date(),
                sortOrder: 0
            ),
            aiName: "Marie"
        )
        
        MessageBubble(
            message: ConversationMessage(
                id: UUID(),
                conversationId: UUID(),
                role: .user,
                content: "Je veux un café",
                correction: nil,
                vocabularyUsed: nil,
                isGoalComplete: false,
                createdAt: Date(),
                sortOrder: 1
            ),
            aiName: "Marie"
        )
        
        MessageBubble(
            message: ConversationMessage(
                id: UUID(),
                conversationId: UUID(),
                role: .assistant,
                content: "Très bien! Un café. Noir ou au lait?",
                correction: "Tip: \"Je voudrais\" is more polite than \"Je veux\"",
                vocabularyUsed: ["café"],
                isGoalComplete: false,
                createdAt: Date(),
                sortOrder: 2
            ),
            aiName: "Marie"
        )
    }
    .padding()
    .background(Color.paper)
}
