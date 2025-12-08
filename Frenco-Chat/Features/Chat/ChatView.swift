//
//  ChatView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

// Features/Chat/ChatView.swift

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var appData: AppDataManager
    @State private var scenarios: [ConversationScenario] = []
    @State private var isLoading = true
    @State private var selectedScenario: ConversationScenario?
    
    private let conversationService = ConversationService()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    ChatHeader()
                    
                    // Scenarios Section
                    if isLoading {
                        LoadingSection()
                    } else if scenarios.isEmpty {
                        EmptySection()
                    } else {
                        ScenarioSection(
                            scenarios: scenarios,
                            onSelect: { scenario in
                                selectedScenario = scenario
                            }
                        )
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 24)
            }
            .background(Color.paper.ignoresSafeArea())
            .fullScreenCover(item: $selectedScenario) { scenario in
                NavigationStack {
                    ConversationView(
                        scenario: scenario,
                        userId: appData.userId ?? ""
                    )
                }
            }
            .task {
                await loadScenarios()
            }
            .refreshable {
                await loadScenarios()
            }
        }
    }
    
    private func loadScenarios() async {
        isLoading = true
        await conversationService.fetchScenarios()
        scenarios = conversationService.scenarios
        isLoading = false
    }
}

// MARK: - Chat Header
private struct ChatHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conversations")
                .font(.system(size: 32, weight: .light, design: .serif))
                .italic()
                .foregroundColor(.ink)
            
            Text("PRATIQUEZ AVEC CONFIANCE")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
        }
        .padding(.top, 16)
    }
}

// MARK: - Scenario Section
private struct ScenarioSection: View {
    let scenarios: [ConversationScenario]
    let onSelect: (ConversationScenario) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SCÉNARIOS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            VStack(spacing: 12) {
                ForEach(scenarios) { scenario in
                    ScenarioCard(scenario: scenario) {
                        onSelect(scenario)
                    }
                }
            }
        }
    }
}

// MARK: - Scenario Card
private struct ScenarioCard: View {
    let scenario: ConversationScenario
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.matchaLight)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: scenario.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.matcha)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.titleFr)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.ink)
                    
                    Text(scenario.description)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Level badge & arrow
                VStack(alignment: .trailing, spacing: 8) {
                    Text(scenario.level)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.matcha)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.matchaLight)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.clay)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Loading Section
private struct LoadingSection: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clay)
                    .frame(height: 88)
                    .shimmering()
            }
        }
    }
}

// MARK: - Empty Section
private struct EmptySection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.clay)
            
            Text("No scenarios available")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.wood)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

// MARK: - Make ConversationScenario Hashable for NavigationDestination
extension ConversationScenario: Hashable {
    static func == (lhs: ConversationScenario, rhs: ConversationScenario) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview
#Preview {
    ChatView()
        .environmentObject(AppDataManager())
}
