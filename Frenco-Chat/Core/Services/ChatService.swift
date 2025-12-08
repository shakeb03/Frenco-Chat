//
//  ChatService.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import Foundation
import Supabase

class ChatService {
    
    // MARK: - Send Message to AI
    func sendMessage(
        scenario: ConversationScenario,
        messages: [ConversationMessage]
    ) async throws -> ChatResponseData {
        
        // Build messages array for the API
        let messageHistory = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }
        
        // Request body struct
        struct ChatRequest: Codable {
            let scenario_system_prompt: String
            let opening_message: String
            let messages: [[String: String]]
            let message_count: Int
        }
        
        let request = ChatRequest(
            scenario_system_prompt: scenario.systemPrompt,
            opening_message: scenario.openingMessage,
            messages: messageHistory,
            message_count: messages.count
        )
        
        // Call Edge Function
        let response: ChatAPIResponse = try await supabase.functions.invoke(
            "chat",
            options: FunctionInvokeOptions(body: request)
        )
        
        guard response.success, let data = response.data else {
            throw ChatError.apiError(response.error ?? "Unknown error")
        }
        
        return data
    }
}

// MARK: - Chat Errors
enum ChatError: LocalizedError {
    case apiError(String)
    case networkError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        case .networkError:
            return "Network connection error. Please try again."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}
