//
//  VocabularyReviewView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI

struct VocabularyReviewView: View {
    let category: VocabularyCategory
    @EnvironmentObject var appData: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var words: [UserVocabulary] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var isLoading: Bool = true
    @State private var sessionComplete: Bool = false
    @State private var correctCount: Int = 0
    @State private var incorrectCount: Int = 0
    
    private var currentWord: UserVocabulary? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }
    
    private var progress: Double {
        guard words.count > 0 else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ReviewHeader(
                    title: category.name,
                    progress: progress,
                    onClose: { dismiss() }
                )
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.matcha)
                    Spacer()
                } else if sessionComplete {
                    // Session Complete
                    SessionCompleteView(
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                        onDone: { dismiss() }
                    )
                } else if let word = currentWord {
                    // Flashcard
                    Spacer()
                    
                    FlashcardView(
                        word: word,
                        isFlipped: isFlipped,
                        onFlip: { isFlipped = true }
                    )
                    
                    Spacer()
                    
                    // Grade Buttons (only show when flipped)
                    if isFlipped {
                        GradeButtonsView(
                            onCorrect: { handleGrade(isCorrect: true) },
                            onIncorrect: { handleGrade(isCorrect: false) }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        Text("Tap card to reveal")
                            .font(.custom("Zen Maru Gothic", size: 14))
                            .foregroundColor(.clay)
                            .padding(.bottom, 40)
                    }
                } else {
                    // No words to review
                    EmptyReviewView(onDone: { dismiss() })
                }
            }
        }
        .task {
            await loadWords()
        }
    }
    
    // MARK: - Methods
    
    private func loadWords() async {
        guard let profileId = appData.profile?.id else { return }
        
        words = await appData.vocabularyService.fetchWordsDueByCategory(
            profileId: profileId,
            category: category.name
        )
        
        // If no words due, fetch all words from category for practice
        if words.isEmpty {
            await appData.vocabularyService.fetchWordsToReview(profileId: profileId)
            words = Array(appData.vocabularyService.wordsToReview.prefix(20))
        }
        
        isLoading = false
    }
    
    private func handleGrade(isCorrect: Bool) {
        guard let word = currentWord else { return }
        
        // Update counts
        if isCorrect {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        
        // Update SM-2 in background
        Task {
            await appData.vocabularyService.updateReview(
                userVocabId: word.id,
                isCorrect: isCorrect
            )
        }
        
        // Move to next card
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentIndex < words.count - 1 {
                currentIndex += 1
            } else {
                withAnimation {
                    sessionComplete = true
                }
            }
        }
    }
}

// MARK: - Review Header

struct ReviewHeader: View {
    let title: String
    let progress: Double
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.ink)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Text(title)
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(.ink)
                
                Spacer()
                
                // Placeholder for balance
                Color.clear.frame(width: 44, height: 44)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.clay.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.matcha)
                        .frame(width: geo.size.width * progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.paper)
    }
}

// MARK: - Flashcard View

struct FlashcardView: View {
    let word: UserVocabulary
    let isFlipped: Bool
    let onFlip: () -> Void
    
    var body: some View {
        Button(action: onFlip) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .ink.opacity(0.08), radius: 16, x: 0, y: 8)
                
                if isFlipped {
                    // Back of card - Answer
                    VStack(spacing: 16) {
                        Text(word.vocabulary?.word ?? "")
                            .font(.custom("Cormorant Garamond", size: 32))
                            .fontWeight(.semibold)
                            .foregroundColor(.ink)
                        
                        Divider()
                            .padding(.horizontal, 40)
                        
                        Text(word.vocabulary?.translation ?? "")
                            .font(.custom("Zen Maru Gothic", size: 20))
                            .foregroundColor(.matcha)
                        
                        if let ipa = word.vocabulary?.pronunciationIpa, !ipa.isEmpty {
                            Text("/\(ipa)/")
                                .font(.custom("Zen Maru Gothic", size: 16))
                                .foregroundColor(.clay)
                        }
                        
                        if let example = word.vocabulary?.exampleSentence, !example.isEmpty {
                            Text(example)
                                .font(.custom("Zen Maru Gothic", size: 14))
                                .foregroundColor(.clay)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(32)
                    .transition(.opacity)
                } else {
                    // Front of card - Question
                    VStack(spacing: 16) {
                        Text(word.vocabulary?.word ?? "")
                            .font(.custom("Cormorant Garamond", size: 36))
                            .fontWeight(.semibold)
                            .foregroundColor(.ink)
                        
                        if let ipa = word.vocabulary?.pronunciationIpa, !ipa.isEmpty {
                            Text("/\(ipa)/")
                                .font(.custom("Zen Maru Gothic", size: 18))
                                .foregroundColor(.clay)
                        }
                        
                        // Speaker button placeholder
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.matcha)
                            .padding(.top, 8)
                    }
                    .padding(32)
                    .transition(.opacity)
                    
                    // Speaker Button
                    SpeakerButton(audioUrl: word.vocabulary?.audioUrl)
                        .padding(16)
                }
            }
            .frame(width: 300, height: 400)
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Grade Buttons

struct GradeButtonsView: View {
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Incorrect button
            Button(action: onIncorrect) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Missed it")
                        .font(.custom("Zen Maru Gothic", size: 16))
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 140, height: 50)
                .background(Color.sakura)
                .cornerRadius(25)
            }
            
            // Correct button
            Button(action: onCorrect) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Got it")
                        .font(.custom("Zen Maru Gothic", size: 16))
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 140, height: 50)
                .background(Color.matcha)
                .cornerRadius(25)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Session Complete View

struct SessionCompleteView: View {
    let correctCount: Int
    let incorrectCount: Int
    let onDone: () -> Void
    
    private var totalCount: Int {
        correctCount + incorrectCount
    }
    
    private var percentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalCount) * 100)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.matcha.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: percentage >= 70 ? "star.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.matcha)
            }
            
            // Title
            Text(percentage >= 70 ? "Great job!" : "Keep practicing!")
                .font(.custom("Cormorant Garamond", size: 28))
                .italic()
                .foregroundColor(.ink)
            
            // Stats
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(correctCount)")
                        .font(.custom("Zen Maru Gothic", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.matcha)
                    Text("Correct")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
                
                VStack(spacing: 4) {
                    Text("\(incorrectCount)")
                        .font(.custom("Zen Maru Gothic", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.sakura)
                    Text("Missed")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
                
                VStack(spacing: 4) {
                    Text("\(percentage)%")
                        .font(.custom("Zen Maru Gothic", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.ink)
                    Text("Score")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
            }
            
            Spacer()
            
            // Done button
            Button(action: onDone) {
                Text("Done")
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.matcha)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Empty Review View

struct EmptyReviewView: View {
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.matcha)
            
            Text("All caught up!")
                .font(.custom("Cormorant Garamond", size: 24))
                .italic()
                .foregroundColor(.ink)
            
            Text("No words due for review in this category")
                .font(.custom("Zen Maru Gothic", size: 14))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: onDone) {
                Text("Done")
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.matcha)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    VocabularyReviewView(
        category: VocabularyCategory(
            id: "test",
            name: "Greetings",
            nameFr: "Salutations",
            wordCount: 20,
            learnedCount: 10,
            masteredCount: 5,
            iconName: "hand.wave.fill"
        )
    )
    .environmentObject(AppDataManager())
}
