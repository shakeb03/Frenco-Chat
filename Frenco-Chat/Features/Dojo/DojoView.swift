//
//  DojoView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI

struct DojoView: View {
    @EnvironmentObject var appData: AppDataManager
    
    // MARK: - State
    @State private var vocabularyCategories: [VocabularyCategory] = []
    @State private var grammarTopics: [GrammarTopicWithProgress] = []
    @State private var wordsToReviewCount: Int = 0
    @State private var hasActivityToday: Bool = false
    @State private var isLoading: Bool = true
    
    // MARK: - Navigation
    @State private var selectedCategory: VocabularyCategory?
    @State private var selectedGrammarTopic: GrammarTopicWithProgress?
    @State private var showQuickQuiz: Bool = false
    @State private var showFullQuiz: Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                DojoHeader()
                
                if isLoading {
                    LoadingView()
                } else {
                    // Hero Card
                    HeroRecommendationCard(
                        wordsToReviewCount: wordsToReviewCount,
                        weakGrammarTopic: weakestGrammarTopic,
                        hasActivityToday: hasActivityToday,
                        onTap: handleHeroTap
                    )
                    
                    // Vocabulary Grove
                    VocabularyGroveSection(
                        categories: vocabularyCategories,
                        onCategoryTap: { category in
                            selectedCategory = category
                        }
                    )
                    
                    // Grammar Garden
                    GrammarGardenSection(
                        topics: grammarTopics,
                        onTopicTap: { topic in
                            selectedGrammarTopic = topic
                        }
                    )
                    
                    // Quiz Mode
                    QuizModeSection(
                        onQuickQuiz: { showQuickQuiz = true },
                        onFullQuiz: { showFullQuiz = true }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .background(Color.paper.ignoresSafeArea())
        .task {
            await loadDojoData()
        }
        .fullScreenCover(item: $selectedCategory) { category in
            VocabularyReviewView(category: category)
                .environmentObject(appData)
        }
        .fullScreenCover(item: $selectedGrammarTopic) { topic in
            GrammarDrillView(topic: topic)
                .environmentObject(appData)
        }
        .fullScreenCover(isPresented: $showQuickQuiz) {
            QuizView(mode: .quick)
                .environmentObject(appData)
        }
        .fullScreenCover(isPresented: $showFullQuiz) {
            QuizView(mode: .full)
                .environmentObject(appData)
        }
    }
    
    // MARK: - Computed Properties
    
    private var weakestGrammarTopic: GrammarTopicWithProgress? {
        grammarTopics
            .filter { $0.masteryPercentage < 70 && $0.exercisesCompleted > 0 }
            .min { $0.masteryPercentage < $1.masteryPercentage }
    }
    
    // MARK: - Methods
    
    private func loadDojoData() async {
        guard let profileId = appData.profile?.id else { return }
        
        async let categories = appData.vocabularyService.fetchVocabularyCategories(profileId: profileId)
        async let topics = appData.grammarService.fetchGrammarTopicsWithProgress(profileId: profileId)
        async let wordsToReview = appData.vocabularyService.fetchWordsToReview(profileId: profileId)
        async let activityToday = appData.progressService.hasActivityToday(profileId: profileId)
        
        vocabularyCategories = await categories
        grammarTopics = await topics
        await wordsToReview
        wordsToReviewCount = appData.vocabularyService.wordsToReview.count
        hasActivityToday = await activityToday
        
        isLoading = false
    }
    
    private func handleHeroTap() {
        if wordsToReviewCount > 0 {
            // Open vocabulary review for all due words
            if let firstCategory = vocabularyCategories.first {
                selectedCategory = firstCategory
            }
        } else if let weakTopic = weakestGrammarTopic {
            selectedGrammarTopic = weakTopic
        } else {
            showQuickQuiz = true
        }
    }
}

// MARK: - Header

struct DojoHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Le Dojo")
                .font(.custom("Cormorant Garamond", size: 32))
                .italic()
                .foregroundColor(.ink)
            
            Text("MAÎTRISEZ VOS FONDATIONS")
                .font(.custom("Zen Maru Gothic", size: 12))
                .tracking(1.5)
                .foregroundColor(.clay)
        }
        .padding(.top, 16)
    }
}


// MARK: - Hero Recommendation Card
struct HeroRecommendationCard: View {
    let wordsToReviewCount: Int
    let weakGrammarTopic: GrammarTopicWithProgress?
    let hasActivityToday: Bool
    let onTap: () -> Void
    
    private var recommendation: (title: String, subtitle: String, icon: String, color: Color) {
        if wordsToReviewCount > 0 {
            return (
                "\(wordsToReviewCount) words to review",
                "Keep your vocabulary fresh",
                "book.fill",
                .matcha
            )
        } else if let topic = weakGrammarTopic {
            return (
                "Practice \(topic.title)",
                "Strengthen your weak spots",
                "pencil.and.outline",
                .sakura
            )
        } else if !hasActivityToday {
            return (
                "Keep your streak!",
                "Complete a quick quiz today",
                "flame.fill",
                .wood
            )
        } else {
            return (
                "You're all caught up!",
                "Try a challenge quiz",
                "star.fill",
                .matcha
            )
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(recommendation.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: recommendation.icon)
                        .font(.system(size: 24))
                        .foregroundColor(recommendation.color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.custom("Zen Maru Gothic", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.ink)
                    
                    Text(recommendation.subtitle)
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.clay)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .ink.opacity(0.06), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Vocabulary Grove Section

struct VocabularyGroveSection: View {
    let categories: [VocabularyCategory]
    let onCategoryTap: (VocabularyCategory) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Vocabulary Grove", icon: "leaf.fill")
            
            if categories.isEmpty {
                EmptyStateCard(
                    message: "Complete lessons to unlock vocabulary review",
                    icon: "book.closed"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories) { category in
                            VocabularyCategoryCard(
                                category: category,
                                onTap: { onCategoryTap(category) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct VocabularyCategoryCard: View {
    let category: VocabularyCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.matcha)
                
                // Name
                Text(category.name)
                    .font(.custom("Zen Maru Gothic", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Word count
                Text("\(category.wordCount) words")
                    .font(.custom("Zen Maru Gothic", size: 12))
                    .foregroundColor(.clay)
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: category.masteryPercentage, total: 100)
                        .tint(.matcha)
                    
                    Text("\(Int(category.masteryPercentage))% mastered")
                        .font(.custom("Zen Maru Gothic", size: 10))
                        .foregroundColor(.clay)
                }
            }
            .padding(16)
            .frame(width: 150, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .ink.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Grammar Garden Section

struct GrammarGardenSection: View {
    let topics: [GrammarTopicWithProgress]
    let onTopicTap: (GrammarTopicWithProgress) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Grammar Garden", icon: "pencil.and.outline")
            
            if topics.isEmpty {
                EmptyStateCard(
                    message: "Grammar topics loading...",
                    icon: "hourglass"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(topics) { topic in
                            GrammarTopicCard(
                                topic: topic,
                                onTap: { onTopicTap(topic) }
                            )
                        }
                    }
                }
            }
        }
    }
}

struct GrammarTopicCard: View {
    let topic: GrammarTopicWithProgress
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(topic.titleFr)
                    .font(.custom("Zen Maru Gothic", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // English title
                Text(topic.title)
                    .font(.custom("Zen Maru Gothic", size: 12))
                    .foregroundColor(.clay)
                    .lineLimit(1)
                
                Spacer()
                
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.clay.opacity(0.2), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: topic.masteryPercentage / 100)
                        .stroke(Color.sakura, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(topic.masteryPercentage))%")
                        .font(.custom("Zen Maru Gothic", size: 11))
                        .fontWeight(.semibold)
                        .foregroundColor(.ink)
                }
                .frame(width: 44, height: 44)
            }
            .padding(16)
            .frame(width: 140, height: 160, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .ink.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quiz Mode Section

struct QuizModeSection: View {
    let onQuickQuiz: () -> Void
    let onFullQuiz: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quiz Mode", icon: "questionmark.circle.fill")
            
            HStack(spacing: 12) {
                QuizButton(
                    title: "Quick Quiz",
                    subtitle: "5 minutes",
                    icon: "bolt.fill",
                    color: .matcha,
                    onTap: onQuickQuiz
                )
                
                QuizButton(
                    title: "Full Quiz",
                    subtitle: "25 questions",
                    icon: "list.bullet.clipboard.fill",
                    color: .wood,
                    onTap: onFullQuiz
                )
            }
        }
    }
}

struct QuizButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("Zen Maru Gothic", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.ink)
                
                Text(subtitle)
                    .font(.custom("Zen Maru Gothic", size: 12))
                    .foregroundColor(.clay)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .ink.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Helper Components

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.matcha)
            
            Text(title)
                .font(.custom("Zen Maru Gothic", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.ink)
        }
    }
}

struct EmptyStateCard: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.clay)
            
            Text(message)
                .font(.custom("Zen Maru Gothic", size: 14))
                .foregroundColor(.clay)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.clay.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    DojoView()
        .environmentObject(AppDataManager())
}
