//
//  DojoView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct DojoView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: FrencoDesign.verticalSpacing) {
                // Header
                DojoHeader()
                
                // Quick Quiz Section
                if appData.wordsToReview.count > 0 {
                    QuickQuizCard(wordsToReview: appData.wordsToReview.count)
                }
                
                // Grammar Garden
                GrammarSection(topics: appData.grammarTopics)
                
                // Vocabulary Grove
                VocabularySection(categories: appData.vocabularyCategories)
                
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

// MARK: - Dojo Header
struct DojoHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("The Dojo")
                .font(.system(size: 32, weight: .light, design: .serif))
                .italic()
                .foregroundColor(.ink)
            
            Text("MASTER YOUR FOUNDATIONS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
        }
        .padding(.top, 16)
    }
}

// MARK: - Quick Quiz Card
struct QuickQuizCard: View {
    let wordsToReview: Int
    
    var body: some View {
        FrencoCard(backgroundColor: .matchaLight, showBorder: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.matcha)
                            Text("\(wordsToReview) words to review")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.matcha)
                        }
                        
                        Text("Keep your streak alive!")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.matcha)
                }
            }
        }
    }
}

// MARK: - Grammar Section
struct GrammarSection: View {
    let topics: [GrammarTopic]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("GRAMMAR")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
                
                Spacer()
                
                Text("Grammar Garden")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.wood)
            }
            
            if topics.isEmpty {
                FrencoCard {
                    HStack {
                        ProgressView()
                            .tint(.matcha)
                        Text("Loading...")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(topics) { topic in
                        GrammarTopicCard(topic: topic)
                    }
                }
            }
        }
    }
}

// MARK: - Grammar Topic Card
struct GrammarTopicCard: View {
    let topic: GrammarTopic
    
    private var progress: Double {
        topic.progress?.masteryPercentage ?? 0
    }
    
    private var isLocked: Bool {
        // First topic is always unlocked
        topic.sortOrder > 1 && progress == 0 && topic.progress == nil
    }
    
    var body: some View {
        FrencoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: isLocked ? "lock" : (topic.iconName ?? "book"))
                        .font(.system(size: 16))
                        .foregroundColor(isLocked ? .clay : .matcha)
                    
                    Spacer()
                    
                    if !isLocked {
                        Text("\(Int(progress))%")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.matcha)
                    }
                }
                
                // English title from DB
                Text(topic.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(isLocked ? .clay : .ink)
                
                FrencoProgressBar(
                    progress: progress / 100,
                    height: 4,
                    trackColor: isLocked ? .clay : .stone
                )
            }
        }
    }
}

// MARK: - Vocabulary Section
struct VocabularySection: View {
    let categories: [VocabularyCategory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("VOCABULARY")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
                
                Spacer()
                
                Text("Word Grove")
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(.wood)
            }
            
            if categories.isEmpty {
                FrencoCard {
                    HStack {
                        ProgressView()
                            .tint(.matcha)
                        Text("Loading...")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(categories) { category in
                        VocabularyRow(category: category)
                    }
                }
            }
        }
    }
}

// MARK: - Vocabulary Row
struct VocabularyRow: View {
    let category: VocabularyCategory
    
    var body: some View {
        FrencoCard {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.sakuraLight)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.sakura)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        // English name
                        Text(category.name)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.ink)
                        
                        Spacer()
                        
                        Text("\(category.wordCount) words")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                    }
                    
                    FrencoProgressBar(
                        progress: category.masteryPercentage,
                        height: 4,
                        fillColor: .sakura
                    )
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.clay)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DojoView()
        .environment(\.clerk, Clerk.shared)
        .environmentObject(AppDataManager())
}
