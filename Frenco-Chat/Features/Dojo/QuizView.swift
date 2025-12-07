//
//  QuizView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI
import Combine

enum QuizMode {
    case quick  // 10 questions, 5 min
    case full   // 25 questions
    
    var questionCount: Int {
        switch self {
        case .quick: return 10
        case .full: return 25
        }
    }
    
    var title: String {
        switch self {
        case .quick: return "Quick Quiz"
        case .full: return "Full Quiz"
        }
    }
}

struct QuizView: View {
    let mode: QuizMode
    @EnvironmentObject var appData: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var questions: [QuizQuestion] = []
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
    
    // Timer for quick quiz
    @State private var timeRemaining: Int = 300 // 5 minutes
    @State private var timerActive: Bool = false
    
    private var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    private var progress: Double {
        guard questions.count > 0 else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                QuizHeader(
                    title: mode.title,
                    progress: progress,
                    timeRemaining: mode == .quick ? timeRemaining : nil,
                    onClose: { dismiss() }
                )
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.matcha)
                    Text("Preparing quiz...")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                        .padding(.top, 12)
                    Spacer()
                } else if sessionComplete || (mode == .quick && timeRemaining <= 0) {
                    QuizCompleteView(
                        mode: mode,
                        correctCount: correctCount,
                        incorrectCount: incorrectCount,
                        questionsAnswered: currentIndex,
                        totalQuestions: questions.count,
                        onDone: { dismiss() }
                    )
                } else if let question = currentQuestion {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question counter
                            Text("\(currentIndex + 1) of \(questions.count)")
                                .font(.custom("Zen Maru Gothic", size: 14))
                                .foregroundColor(.clay)
                                .padding(.top, 16)
                            
                            // Question type badge
                            QuestionTypeBadge(type: question.type)
                            
                            // Question content
                            switch question.type {
                            case .vocabulary:
                                VocabularyQuizQuestion(
                                    question: question,
                                    selectedAnswer: $selectedAnswer,
                                    hasAnswered: hasAnswered,
                                    isCorrect: isCorrect
                                )
                            case .grammarMultipleChoice:
                                GrammarMultipleChoiceQuestion(
                                    question: question,
                                    selectedAnswer: $selectedAnswer,
                                    hasAnswered: hasAnswered,
                                    isCorrect: isCorrect
                                )
                            case .grammarFillBlank:
                                GrammarFillBlankQuestion(
                                    question: question,
                                    answer: $fillBlankAnswer,
                                    hasAnswered: hasAnswered,
                                    isCorrect: isCorrect
                                )
                            }
                            
                            // Feedback
                            if hasAnswered {
                                QuizFeedbackView(
                                    isCorrect: isCorrect,
                                    correctAnswer: question.correctAnswer
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
                            QuizContinueButton(
                                isLastQuestion: currentIndex == questions.count - 1,
                                onTap: moveToNext
                            )
                        } else {
                            QuizCheckButton(
                                isEnabled: canCheck,
                                onTap: checkAnswer
                            )
                        }
                    }
                } else {
                    EmptyQuizView(onDone: { dismiss() })
                }
            }
        }
        .task {
            await loadQuiz()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if mode == .quick && timerActive && timeRemaining > 0 && !sessionComplete {
                timeRemaining -= 1
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canCheck: Bool {
        guard let question = currentQuestion else { return false }
        
        switch question.type {
        case .vocabulary, .grammarMultipleChoice:
            return selectedAnswer != nil
        case .grammarFillBlank:
            return !fillBlankAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    // MARK: - Methods
    
    private func loadQuiz() async {
        guard let profileId = appData.profile?.id else { return }
        
        var quizQuestions: [QuizQuestion] = []
        
        // 1. Fetch vocabulary for quiz (50% of questions)
        let vocabCount = mode.questionCount / 2
        await appData.vocabularyService.fetchWordsToReview(profileId: profileId, limit: vocabCount)
        let vocabWords = appData.vocabularyService.wordsToReview
        
        for word in vocabWords {
            guard let vocab = word.vocabulary else { continue }
            
            // Create multiple choice from vocabulary
            let question = QuizQuestion(
                type: .vocabulary,
                questionText: "What does '\(vocab.word)' mean?",
                options: generateVocabOptions(correct: vocab.translation),
                correctAnswer: vocab.translation,
                correctIndex: 0, // Will be shuffled
                sourceId: word.id
            )
            quizQuestions.append(question)
        }
        
        // 2. Fetch grammar exercises (50% of questions)
        let grammarCount = mode.questionCount - quizQuestions.count
        let topics = await appData.grammarService.fetchGrammarTopicsWithProgress(profileId: profileId)
        
        // Get exercises from random topics
        for topic in topics.shuffled().prefix(3) {
            let exercises = await appData.grammarService.fetchGrammarExercises(
                topicId: topic.id,
                limit: grammarCount / 3 + 1
            )
            
            for exercise in exercises {
                let question: QuizQuestion
                
                if exercise.exerciseType == "multiple_choice" {
                    question = QuizQuestion(
                        type: .grammarMultipleChoice,
                        questionText: exercise.content.question ?? "",
                        options: exercise.content.options ?? [],
                        correctAnswer: exercise.content.options?[safe: exercise.content.correctIndex ?? 0] ?? "",
                        correctIndex: exercise.content.correctIndex ?? 0,
                        sourceId: nil,
                        grammarTopicId: topic.id
                    )
                } else {
                    question = QuizQuestion(
                        type: .grammarFillBlank,
                        questionText: exercise.content.sentence ?? "",
                        options: [],
                        correctAnswer: exercise.content.correctAnswer ?? "",
                        correctIndex: nil,
                        sourceId: nil,
                        grammarTopicId: topic.id
                    )
                }
                quizQuestions.append(question)
            }
        }
        
        // 3. Shuffle and limit to question count
        questions = Array(quizQuestions.shuffled().prefix(mode.questionCount))
        
        // Shuffle options for vocabulary questions
        for i in questions.indices {
            if questions[i].type == .vocabulary {
                questions[i] = shuffleVocabOptions(questions[i])
            }
        }
        
        isLoading = false
        timerActive = true
    }
    
    private func generateVocabOptions(correct: String) -> [String] {
        // Generate 3 fake options + correct answer
        let fakeOptions = [
            "to eat", "to drink", "to sleep", "to walk", "to run",
            "hello", "goodbye", "please", "thank you", "yes", "no",
            "the house", "the car", "the book", "the dog", "the cat",
            "big", "small", "good", "bad", "happy", "sad"
        ].filter { $0.lowercased() != correct.lowercased() }
        
        var options = [correct]
        options.append(contentsOf: fakeOptions.shuffled().prefix(3))
        return options
    }
    
    private func shuffleVocabOptions(_ question: QuizQuestion) -> QuizQuestion {
        var shuffledOptions = question.options.shuffled()
        let correctIndex = shuffledOptions.firstIndex(of: question.correctAnswer) ?? 0
        
        return QuizQuestion(
            type: question.type,
            questionText: question.questionText,
            options: shuffledOptions,
            correctAnswer: question.correctAnswer,
            correctIndex: correctIndex,
            sourceId: question.sourceId,
            grammarTopicId: question.grammarTopicId
        )
    }
    
    private func checkAnswer() {
        guard let question = currentQuestion else { return }
        
        var correct = false
        
        switch question.type {
        case .vocabulary, .grammarMultipleChoice:
            if let selected = selectedAnswer, let correctIdx = question.correctIndex {
                correct = selected == correctIdx
            }
        case .grammarFillBlank:
            correct = fillBlankAnswer.trimmingCharacters(in: .whitespaces)
                .lowercased() == question.correctAnswer.lowercased()
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
            
            // Update vocabulary SM-2 if applicable
            if question.type == .vocabulary, let sourceId = question.sourceId {
                await appData.vocabularyService.updateReview(
                    userVocabId: sourceId,
                    isCorrect: correct
                )
            }
            
            // Update grammar progress if applicable
            if let topicId = question.grammarTopicId {
                await appData.grammarService.updateGrammarProgress(
                    profileId: profileId,
                    topicId: topicId,
                    isCorrect: correct
                )
            }
        }
    }
    
    private func moveToNext() {
        // Reset state
        selectedAnswer = nil
        fillBlankAnswer = ""
        hasAnswered = false
        isCorrect = false
        
        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            withAnimation {
                sessionComplete = true
            }
        }
    }
}

// MARK: - Quiz Question Model

enum QuizQuestionType {
    case vocabulary
    case grammarMultipleChoice
    case grammarFillBlank
}

struct QuizQuestion {
    let type: QuizQuestionType
    let questionText: String
    var options: [String]
    let correctAnswer: String
    var correctIndex: Int?
    let sourceId: UUID?  // For vocabulary - user_vocabulary.id
    let grammarTopicId: UUID?  // For grammar
    
    init(type: QuizQuestionType, questionText: String, options: [String], correctAnswer: String, correctIndex: Int?, sourceId: UUID? = nil, grammarTopicId: UUID? = nil) {
        self.type = type
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.correctIndex = correctIndex
        self.sourceId = sourceId
        self.grammarTopicId = grammarTopicId
    }
}

// MARK: - Quiz Header

struct QuizHeader: View {
    let title: String
    let progress: Double
    let timeRemaining: Int?
    let onClose: () -> Void
    
    private var timeString: String {
        guard let time = timeRemaining else { return "" }
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var timeColor: Color {
        guard let time = timeRemaining else { return .clay }
        if time <= 30 { return .sakura }
        if time <= 60 { return .wood }
        return .clay
    }
    
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
                
                // Timer or placeholder
                if let _ = timeRemaining {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(timeString)
                            .font(.custom("Zen Maru Gothic", size: 14))
                            .fontWeight(.medium)
                    }
                    .foregroundColor(timeColor)
                    .frame(width: 60, alignment: .trailing)
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.clay.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.wood)
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

// MARK: - Question Type Badge

struct QuestionTypeBadge: View {
    let type: QuizQuestionType
    
    private var text: String {
        switch type {
        case .vocabulary: return "Vocabulary"
        case .grammarMultipleChoice, .grammarFillBlank: return "Grammar"
        }
    }
    
    private var color: Color {
        switch type {
        case .vocabulary: return .matcha
        case .grammarMultipleChoice, .grammarFillBlank: return .sakura
        }
    }
    
    var body: some View {
        Text(text)
            .font(.custom("Zen Maru Gothic", size: 12))
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .cornerRadius(12)
    }
}

// MARK: - Vocabulary Quiz Question

struct VocabularyQuizQuestion: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: Int?
    let hasAnswered: Bool
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.questionText)
                .font(.custom("Zen Maru Gothic", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    QuizOptionButton(
                        text: option,
                        index: index,
                        isSelected: selectedAnswer == index,
                        isCorrect: question.correctIndex == index,
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .ink.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Grammar Multiple Choice Question

struct GrammarMultipleChoiceQuestion: View {
    let question: QuizQuestion
    @Binding var selectedAnswer: Int?
    let hasAnswered: Bool
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.questionText)
                .font(.custom("Zen Maru Gothic", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    QuizOptionButton(
                        text: option,
                        index: index,
                        isSelected: selectedAnswer == index,
                        isCorrect: question.correctIndex == index,
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
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .ink.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Grammar Fill Blank Question

struct GrammarFillBlankQuestion: View {
    let question: QuizQuestion
    @Binding var answer: String
    let hasAnswered: Bool
    let isCorrect: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.questionText)
                .font(.custom("Zen Maru Gothic", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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

// MARK: - Quiz Option Button

struct QuizOptionButton: View {
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
        return isSelected ? Color.wood.opacity(0.1) : Color.paper
    }
    
    private var borderColor: Color {
        if hasAnswered {
            if isCorrect {
                return .matcha
            } else if isSelected && !isCorrect {
                return .sakura
            }
        }
        return isSelected ? .wood : .clay.opacity(0.3)
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

// MARK: - Quiz Feedback View

struct QuizFeedbackView: View {
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

// MARK: - Quiz Check Button

struct QuizCheckButton: View {
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
                .background(isEnabled ? Color.wood : Color.clay.opacity(0.3))
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

// MARK: - Quiz Continue Button

struct QuizContinueButton: View {
    let isLastQuestion: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(isLastQuestion ? "Finish" : "Continue")
                .font(.custom("Zen Maru Gothic", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.wood)
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

// MARK: - Quiz Complete View

struct QuizCompleteView: View {
    let mode: QuizMode
    let correctCount: Int
    let incorrectCount: Int
    let questionsAnswered: Int
    let totalQuestions: Int
    let onDone: () -> Void
    
    private var percentage: Int {
        guard questionsAnswered > 0 else { return 0 }
        return Int(Double(correctCount) / Double(questionsAnswered) * 100)
    }
    
    private var grade: (text: String, color: Color) {
        if percentage >= 90 { return ("Excellent!", .matcha) }
        if percentage >= 70 { return ("Great job!", .matcha) }
        if percentage >= 50 { return ("Good effort!", .wood) }
        return ("Keep practicing!", .sakura)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(grade.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: percentage >= 70 ? "trophy.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(grade.color)
            }
            
            // Title
            VStack(spacing: 8) {
                Text(grade.text)
                    .font(.custom("Cormorant Garamond", size: 28))
                    .italic()
                    .foregroundColor(.ink)
                
                Text(mode.title)
                    .font(.custom("Zen Maru Gothic", size: 16))
                    .foregroundColor(.clay)
            }
            
            // Stats
            HStack(spacing: 32) {
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
                        .foregroundColor(grade.color)
                    Text("Score")
                        .font(.custom("Zen Maru Gothic", size: 14))
                        .foregroundColor(.clay)
                }
            }
            
            // Questions answered
            if questionsAnswered < totalQuestions {
                Text("Answered \(questionsAnswered) of \(totalQuestions) questions")
                    .font(.custom("Zen Maru Gothic", size: 14))
                    .foregroundColor(.clay)
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
                    .background(Color.wood)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Empty Quiz View

struct EmptyQuizView: View {
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.clay)
            
            Text("No questions available")
                .font(.custom("Cormorant Garamond", size: 24))
                .italic()
                .foregroundColor(.ink)
            
            Text("Complete some lessons first to unlock quiz mode")
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
                    .background(Color.wood)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    QuizView(mode: .quick)
        .environmentObject(AppDataManager())
}
