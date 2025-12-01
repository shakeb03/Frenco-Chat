//
//  ChatView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct ChatView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: FrencoDesign.verticalSpacing) {
                // Header
                ChatHeader()
                
                // Scenario Cards
                ScenarioSection(scenarios: appData.scenarios)
                
                // Recent Conversations
                RecentConversationsSection(conversations: appData.recentConversations)
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .background(Color.paper.ignoresSafeArea())
        .refreshable {
            await appData.refreshData()
        }
    }
}

// MARK: - Chat Header
struct ChatHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conversations")
                .font(.system(size: 32, weight: .light, design: .serif))
                .italic()
                .foregroundColor(.ink)
            
            Text("PRACTICE WITH CONFIDENCE")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
        }
        .padding(.top, 16)
    }
}

// MARK: - Scenario Section
struct ScenarioSection: View {
    let scenarios: [ConversationScenario]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCENARIOS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            if scenarios.isEmpty {
                // Loading state
                FrencoCard {
                    HStack {
                        ProgressView()
                            .tint(.matcha)
                        Text("Loading scenarios...")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(scenarios) { scenario in
                            ScenarioCard(scenario: scenario)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Scenario Card
struct ScenarioCard: View {
    let scenario: ConversationScenario
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.matchaLight)
                    .frame(width: 56, height: 56)
                
                Image(systemName: scenario.iconName ?? "bubble.left.and.bubble.right")
                    .font(.system(size: 24))
                    .foregroundColor(.matcha)
            }
            
            // Title (English from DB)
            Text(scenario.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            
            // Description
            Text(scenario.description ?? scenario.titleFr)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
                .lineLimit(2)
            
            // Difficulty
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < scenario.difficulty ? Color.matcha : Color.clay.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                
                Spacer()
                
                Text(difficultyLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.wood)
            }
        }
        .padding(20)
        .frame(width: 160)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius)
                .stroke(Color.wood.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onTapGesture {
            // Navigate to conversation
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
    
    private var difficultyLabel: String {
        switch scenario.difficulty {
        case 1: return "Easy"
        case 2: return "Medium"
        case 3: return "Hard"
        default: return ""
        }
    }
}

// MARK: - Recent Conversations Section
struct RecentConversationsSection: View {
    let conversations: [UserConversation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECENT CONVERSATIONS")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
                
                Spacer()
                
                if !conversations.isEmpty {
                    Button("See all") {
                        // Show all conversations
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.matcha)
                }
            }
            
            if conversations.isEmpty {
                // Empty state
                FrencoCard {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundColor(.clay)
                        
                        Text("No conversations yet")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.wood)
                        
                        Text("Start a scenario to practice")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.clay)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(conversations.prefix(3)) { conversation in
                        ConversationRow(conversation: conversation)
                    }
                }
            }
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: UserConversation
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.startedAt, relativeTo: Date())
    }
    
    private var previewText: String {
        conversation.messages.last?.content ?? "New conversation"
    }
    
    var body: some View {
        FrencoCard {
            HStack(spacing: 16) {
                // Chat Icon
                ZStack {
                    Circle()
                        .fill(Color.matchaLight)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 18))
                        .foregroundColor(.matcha)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Conversation")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.ink)
                        
                        Spacer()
                        
                        Text(timeAgo)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                    }
                    
                    Text(previewText)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                        .lineLimit(1)
                }
                
                // Score (if available)
                if let score = conversation.overallScore {
                    ZStack {
                        Circle()
                            .stroke(Color.matcha.opacity(0.3), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: Double(score) / 100)
                            .stroke(Color.matcha, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(score)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.matcha)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView()
        .environment(\.clerk, Clerk.shared)
        .environmentObject(AppDataManager())
}
