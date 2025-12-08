//
//  ConversationView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

// Features/Chat/ConversationView.swift

import SwiftUI
import Combine

struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    let scenario: ConversationScenario
    
    init(scenario: ConversationScenario, userId: String) {
        self.scenario = scenario
        _viewModel = StateObject(wrappedValue: ConversationViewModel(scenario: scenario, userId: userId))
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message, aiName: viewModel.aiName)
                                    .id(message.id)
                            }
                            
                            // Typing indicator
                            if viewModel.isTyping {
                                TypingIndicator(name: viewModel.aiName)
                                    .id("typing")
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isTyping) { isTyping in
                        if isTyping {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input bar
                InputBar(
                    text: $viewModel.inputText,
                    isLoading: viewModel.isLoading,
                    canSend: viewModel.canSend,
                    isFocused: $isInputFocused,
                    onSend: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.wood)
                }
            }
            
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: scenario.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(.matcha)
                    
                    Text(scenario.titleFr)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.ink)
                }
            }
        }
        .navigationBarBackButtonHidden(viewModel.isLoading)
        .task {
            await viewModel.startConversation()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.error ?? "Something went wrong")
        }
        .fullScreenCover(isPresented: $viewModel.isConversationComplete) {
            ConversationCompleteView(
                scenario: scenario,
                messagesCount: viewModel.messages.count,
                correctionsCount: viewModel.messages.filter { $0.correction != nil }.count,
                onDismiss: {
                    dismiss()
                }
            )
        }
        .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Typing Indicator
private struct TypingIndicator: View {
    let name: String
    @State private var dotCount = 0
    
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(name) is typing")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                
                Text(String(repeating: ".", count: dotCount + 1))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                    .frame(width: 20, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clay)
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

// MARK: - Input Bar
private struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    let canSend: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type en français...", text: $text, axis: .vertical)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clay)
                    .cornerRadius(24)
                    .lineLimit(1...4)
                    .focused(isFocused)
                    .disabled(isLoading)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(canSend ? .matcha : .clay)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.paper)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ConversationView(
            scenario: ConversationScenario(
                id: UUID(),
                title: "Café",
                titleFr: "Au café",
                description: "Order a coffee and pastry",
                iconName: "cup.and.saucer.fill",
                level: "A1",
                aiRole: "Marie, a friendly café server",
                openingMessage: "Bonjour! Bienvenue au café. Qu'est-ce que je vous sers aujourd'hui?",
                goalDescription: "Order a drink and pastry",
                targetVocabulary: ["café", "croissant"],
                systemPrompt: "",
                sortOrder: 1,
                isActive: true
            ),
            userId: "test-user"
        )
    }
}
