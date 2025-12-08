//
//  CorrectionCard.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

// Features/Chat/Components/CorrectionCard.swift

import SwiftUI

struct CorrectionCard: View {
    let correction: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(.yellow)
            
            Text(correction)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        CorrectionCard(correction: "Tip: \"Je voudrais\" is more polite than \"Je veux\"")
        
        CorrectionCard(correction: "Remember: In French, adjectives usually come after the noun.")
    }
    .padding()
    .background(Color.paper)
}
