//
//  ConversationViewModel.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    // MARK: - Published State
    @Published var messages: [ConversationMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var isTyping: Bool = false
    @Published var error: String?
    @Published var isConversationComplete: Bool = false
    @Published var showError: Bool = false
    
    // MARK: - Properties
    let scenario: ConversationScenario
    let userId: String
    private var conversation: Conversation?
    private var correctionsCount: Int = 0
    private var vocabularyPracticed: Set<String> = []
    
    // Services
    private let chatService = ChatService()
    private let conversationService = ConversationService()
    
    // MARK: - Computed Properties
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    var aiName: String {
        // Extract first name from ai_role (e.g., "Marie, a friendly café server" -> "Marie")
        scenario.aiRole.components(separatedBy: ",").first ?? "Assistant"
    }
    
    // MARK: - Init
    init(scenario: ConversationScenario, userId: String) {
        self.scenario = scenario
        self.userId = userId
    }
    
    // MARK: - Start Conversation
    func startConversation() async {
        isLoading = true
        
        do {
            // Create conversation in DB
            conversation = try await conversationService.createConversation(
                userId: userId,
                scenarioId: scenario.id
            )
            
            guard let conversation = conversation else {
                throw ChatError.invalidResponse
            }
            
            // Save opening message as first assistant message
            let openingMessage = try await conversationService.saveMessage(
                conversationId: conversation.id,
                role: .assistant,
                content: scenario.openingMessage,
                sortOrder: 0
            )
            
            messages.append(openingMessage)
            
            // Update conversation message count
            try await conversationService.updateConversation(
                conversationId: conversation.id,
                messageCount: 1
            )
            
        } catch {
            self.error = "Failed to start conversation. Please try again."
            self.showError = true
            Log.debug("❌ Start conversation error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty, let conversation = conversation else { return }
        
        // Clear input immediately
        inputText = ""
        isLoading = true
        isTyping = true
        
        do {
            // Save user message to DB
            let userMessage = try await conversationService.saveMessage(
                conversationId: conversation.id,
                role: .user,
                content: userText,
                sortOrder: messages.count
            )
            messages.append(userMessage)
            
            // Call AI via Edge Function
            let aiResponse = try await chatService.sendMessage(
                scenario: scenario,
                messages: messages
            )
            
            // Track corrections and vocabulary
            if aiResponse.correction != nil {
                correctionsCount += 1
            }
            for word in aiResponse.vocabularyUsed {
                vocabularyPracticed.insert(word.lowercased())
            }
            
            // Save AI response to DB
            let assistantMessage = try await conversationService.saveMessage(
                conversationId: conversation.id,
                role: .assistant,
                content: aiResponse.message,
                correction: aiResponse.correction,
                vocabularyUsed: aiResponse.vocabularyUsed,
                isGoalComplete: aiResponse.isGoalComplete,
                sortOrder: messages.count
            )
            
            isTyping = false
            messages.append(assistantMessage)
            
            // Update conversation stats
            try await conversationService.updateConversation(
                conversationId: conversation.id,
                messageCount: messages.count,
                correctionsCount: correctionsCount,
                vocabularyPracticed: Array(vocabularyPracticed)
            )
            
            // Check if conversation is complete
            if aiResponse.isGoalComplete {
                await completeConversation()
            }
            
        } catch {
            isTyping = false
            self.error = "Something went wrong. Please try again."
            self.showError = true
            await endConversationWithError()
            Log.debug("❌ Send message error: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Complete Conversation (Goal Reached)
    private func completeConversation() async {
        guard let conversation = conversation else { return }
        
        do {
            try await conversationService.updateConversation(
                conversationId: conversation.id,
                status: .completed,
                vocabularyPracticed: Array(vocabularyPracticed)
            )
            
            // Increment total conversations in user stats
            await ProfileService().incrementConversations()
            
            // Small delay before showing completion screen
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            isConversationComplete = true
            
        } catch {
            Log.debug("❌ Complete conversation error: \(error)")
        }
    }
    
    // MARK: - End Conversation With Error
    private func endConversationWithError() async {
        guard let conversation = conversation else { return }
        
        do {
            try await conversationService.updateConversation(
                conversationId: conversation.id,
                status: .abandoned
            )
        } catch {
            Log.debug("❌ End conversation error: \(error)")
        }
    }
}
