//
//  GrammarDrillView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI

struct GrammarDrillView: View {
    let topic: GrammarTopicWithProgress
    @EnvironmentObject var appData: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var exercises: [GrammarExercise] = []
    @State private var currentIndex: Int = 0
    @State private var isLoading: Bool = true
    @State private var sessionComplete: Bool = false
    @State private var correctCount: Int = 0
    @State private var incorrectCount: Int = 0
    
    // Exercise state
    @State private var selectedAnswer: Int? = nil
    @State private var fillBlankAnswer: String = ""
    @State private var hasAnswered: Bool = false
    @State private var isCorrect: Bool = false
    
    private var currentExercise: GrammarExercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }
    
    private var progress: Double {
        guard exercises.count > 0 else { return 0 }
        return Double(currentIndex) / Double(exercises.count)
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DrillHeader(
                    title: topic.titleFr,
                    subtitle: topic.title,
                    progress: progress,
                    onClose: { dismiss() }
                )
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.matcha)
                    Spacer()
                } else if sessionComplete {
                    DrillCompleteView(
                        topicTitle: topic.title,
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                        onDone: { dismiss() }
                    )
                } else if let exercise = currentExercise {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Exercise counter
                            Text("\(currentIndex + 1) of \(exercises.count)")
                                .font(.custom("Zen Maru Gothic", size: 14))
                                .foregroundColor(.clay)
                                .padding(.top, 16)
                            
                            // Exercise content
                            switch exercise.exerciseType {
                            case "multiple_choice":
                                MultipleChoiceExerciseView(
                                    exercise: exercise,
                                    selectedAnswer: $selectedAnswer,
                                    hasAnswered: hasAnswered,
                                    isCorrect: isCorrect
                                )
                            case "fill_blank":
                                FillBlankExerciseView(
                                    exercise: exercise,
                                    answer: $fillBlankAnswer,
                                    hasAnswered: hasAnswered,
                                    isCorrect: isCorrect
                                )
                            default:
                                Text("Unknown exercise type")
                                    .foregroundColor(.clay)
                            }
                            
                            // Hint
                            if let hint = exercise.hint, !hasAnswered {
                                HintView(hint: hint)
                            }
                            
                            // Feedback after answering
                            if hasAnswered {
                                FeedbackView(
                                    isCorrect: isCorrect,
                                    correctAnswer: getCorrectAnswer(exercise)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                    
                    // Bottom button
                    VStack {
                        Spacer()
                        
                        if hasAnswered {
                            ContinueButton(onTap: moveToNext)
                        } else {
                            CheckButton(
                                isEnabled: canCheck,
                                onTap: checkAnswer
                            )
                        }
                    }
                } else {
                    EmptyDrillView(onDone: { dismiss() })
                }
            }
        }
        .task {
            await loadExercises()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCheck: Bool {
        guard let exercise = currentExercise else { return false }
        
        switch exercise.exerciseType {
        case "multiple_choice":
            return selectedAnswer != nil
        case "fill_blank":
            return !fillBlankAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return false
        }
    }
    
    // MARK: - Methods
    
    private func loadExercises() async {
        // Determine difficulty range based on user's mastery
        let difficultyRange: ClosedRange<Int>
        if topic.masteryPercentage < 30 {
            difficultyRange = 1...4  // Easy
        } else if topic.masteryPercentage < 70 {
            difficultyRange = 3...7  // Medium
        } else {
            difficultyRange = 5...10 // Hard
        }
        
        exercises = await appData.grammarService.fetchGrammarExercises(
            topicId: topic.id,
            difficulty: difficultyRange,
            limit: 10
        )
        
        // Shuffle exercises
        exercises.shuffle()
        
        isLoading = false
    }
    
    private func checkAnswer() {
        guard let exercise = currentExercise else { return }
        
        var correct = false
        
        switch exercise.exerciseType {
        case "multiple_choice":
            if let selected = selectedAnswer,
               let correctIndex = exercise.content.correctIndex {
                correct = selected == correctIndex
            }
        case "fill_blank":
            if let correctAnswer = exercise.content.correctAnswer {
                correct = fillBlankAnswer.trimmingCharacters(in: .whitespaces)
                    .lowercased() == correctAnswer.lowercased()
            }
        default:
            break
        }
        
        isCorrect = correct
        hasAnswered = true
        
        if correct {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
        
        // Update progress in background
        Task {
            guard let profileId = appData.profile?.id else { return }
            await appData.grammarService.updateGrammarProgress(
                profileId: profileId,
                topicId: topic.id,
                isCorrect: correct
            )
        }
    }
    
    private func moveToNext() {
        // Reset state
        selectedAnswer = nil
        fillBlankAnswer = ""
        hasAnswered = false
        isCorrect = false
        
        if currentIndex < exercises.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                sessionComplete = true
            }
        }
    }
    
    private func getCorrectAnswer(_ exercise: GrammarExercise) -> String {
        switch exercise.exerciseType {
        case "multiple_choice":
            if let correctIndex = exercise.content.correctIndex,
               let options = exercise.content.options,
               correctIndex < options.count {
                return options[correctIndex]
            }
        case "fill_blank":
            return exercise.content.correctAnswer ?? ""
        default:
            break
        }
        return ""
    }
}

// MARK: - Grammar Option Button

struct GrammarOptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let hasAnswered: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if hasAnswered {
            if isCorrect {
                return Color.matcha.opacity(0.15)
            } else if isSelected && !isCorrect {
                return Color.sakura.opacity(0.15)
            }
        }
        return isSelected ? Color.matcha.opacity(0.1) : Color.paper
    }
    
    private var borderColor: Color {
        if hasAnswered {
            if isCorrect {
                return .matcha
            } else if isSelected && !isCorrect {
                return .sakura
            }
        }
        return isSelected ? .matcha : .clay.opacity(0.3)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .foregroundColor(.ink)
                
                Spacer()
                
                if hasAnswered {
                    if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.matcha)
                    } else if isSelected && !isCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sakura)
                    }
                }
            }
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(hasAnswered)
    }
}

// MARK: - Drill Header

struct DrillHeader: View {
    let title: String
    let subtitle: String
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
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.custom("Zen Maru Gothic", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.ink)
                    
                    Text(subtitle)
                        .font(.custom("Zen Maru Gothic", size: 12))
                        .foregroundColor(.clay)
                }
                
                Spacer()
                
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
                        .fill(Color.sakura)
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

// MARK: - Multiple Choice Exercise

struct MultipleChoiceExerciseView: View {
    let exercise: GrammarExercise
    @Binding var selectedAnswer: Int?
    let hasAnswered: Bool
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question
            questionText
            
            // Options
            optionsList
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .ink.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var questionText: some View {
        Text(exercise.content.question ?? "")
            .font(.custom("Zen Maru Gothic", size: 18))
            .fontWeight(.medium)
            .foregroundColor(.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var optionsList: some View {
        VStack(spacing: 12) {
            if let options = exercise.content.options {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    GrammarOptionButton(
                        text: option,
                        index: index,
                        isSelected: selectedAnswer == index,
                        isCorrect: exercise.content.correctIndex == index,
                        hasAnswered: hasAnswered,
                        onTap: {
                            if !hasAnswered {
                                selectedAnswer = index
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Fill Blank Exercise

struct FillBlankExerciseView: View {
    let exercise: GrammarExercise
    @Binding var answer: String
    let hasAnswered: Bool
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Sentence with blank
            Text(exercise.content.sentence ?? "")
                .font(.custom("Zen Maru Gothic", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Text field
            TextField("Type your answer", text: $answer)
                .font(.custom("Zen Maru Gothic", size: 16))
                .padding(16)
                .background(hasAnswered ? (isCorrect ? Color.matcha.opacity(0.1) : Color.sakura.opacity(0.1)) : Color.paper)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(hasAnswered ? (isCorrect ? Color.matcha : Color.sakura) : Color.clay.opacity(0.3), lineWidth: 1.5)
                )
                .disabled(hasAnswered)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .ink.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Hint View

struct HintView: View {
    let hint: String
    @State private var isExpanded: Bool = false
    
    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.wood)
                
                Text(isExpanded ? hint : "Tap for hint")
                    .font(.custom("Zen Maru Gothic", size: 14))
                    .foregroundColor(.wood)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.wood)
            }
            .padding(12)
            .background(Color.wood.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Feedback View

struct FeedbackView: View {
    let isCorrect: Bool
    let correctAnswer: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(isCorrect ? .matcha : .sakura)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(isCorrect ? .matcha : .sakura)
                
                if !isCorrect {
                    Text("Correct answer: \(correctAnswer)")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(isCorrect ? Color.matcha.opacity(0.1) : Color.sakura.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Check Button

struct CheckButton: View {
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("Check")
                .font(.custom("Zen Maru Gothic", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? Color.matcha : Color.clay.opacity(0.3))
                .cornerRadius(25)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.paper.opacity(0), Color.paper],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }
}

// MARK: - Continue Button

struct ContinueButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("Continue")
                .font(.custom("Zen Maru Gothic", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.matcha)
                .cornerRadius(25)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.paper.opacity(0), Color.paper],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }
}

// MARK: - Drill Complete View

struct DrillCompleteView: View {
    let topicTitle: String
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
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.sakura.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: percentage >= 70 ? "star.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.sakura)
            }
            
            // Title
            VStack(spacing: 8) {
                Text(percentage >= 70 ? "Well done!" : "Keep going!")
                    .font(.custom("Cormorant Garamond", size: 28))
                    .italic()
                    .foregroundColor(.ink)
                
                Text(topicTitle)
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .foregroundColor(.clay)
            }
            
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
                    .background(Color.sakura)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Empty Drill View

struct EmptyDrillView: View {
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.clay)
            
            Text("No exercises available")
                .font(.custom("Cormorant Garamond", size: 24))
                .italic()
                .foregroundColor(.ink)
            
            Text("Exercises for this topic are being generated")
                .font(.custom("Zen Maru Gothic", size: 14))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: onDone) {
                Text("Go Back")
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.sakura)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    GrammarDrillView(
        topic: GrammarTopicWithProgress(
            id: UUID(),
            title: "Definite Articles",
            titleFr: "Les Articles Définis",
            description: "Learn le, la, les",
            explanation: "",
            sortOrder: 1,
            masteryPercentage: 40,
            uniqueDaysCorrect: 2,
            exercisesCompleted: 5,
            lastPracticedAt: nil
        )
    )
    .environmentObject(AppDataManager())
}
