//
//  LessonView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-01.
//

import SwiftUI


struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var appData: AppDataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentExerciseIndex = 0
    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var score = 0
    @State private var showingCompletion = false
    @State private var errorMessage: String?
    
    // Progress tracking
    @State private var lessonProgressId: UUID?
    @State private var startTime: Date = Date()
    @State private var isCompleting = false  // Prevent multiple completion calls
    // Add state for navigation
    @State private var selectedNextLesson: Lesson?
    
    
    // Add computed property to find next lesson
    private var nextLesson: Lesson? {
        let allLessons = appData.units
            .flatMap { $0.lessons ?? [] }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        guard let currentIndex = allLessons.firstIndex(where: { $0.id == lesson.id }) else {
            return nil
        }
        
        let nextIndex = currentIndex + 1
        guard nextIndex < allLessons.count else { return nil }
        
        return allLessons[nextIndex]
    }
    
    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(exercises.count)
    }
    
    // Check if all exercises are done
    var isLessonComplete: Bool {
        !exercises.isEmpty && currentExerciseIndex >= exercises.count
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                LessonHeader(
                    lessonTitle: lesson.titleFr,
                    progress: progress,
                    onClose: { dismiss() }
                )
                
                // Content
                Group {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if exercises.isEmpty {
                        emptyView
                    } else if !isLessonComplete {
                        exerciseContent
                    } else {
                        completedView
                    }
                }
            }
        }
        .task {
            await loadLesson()
        }
        .sheet(isPresented: $showingCompletion) {
            LessonCompleteView(
                lesson: lesson,
                score: score,
                totalExercises: exercises.count,
                nextLesson: nextLesson,
                onContinue: {
                    dismiss()
                },
                onNextLesson: { next in
                    selectedNextLesson = next
                }
            )
        }
        .fullScreenCover(item: $selectedNextLesson) { next in
            LessonView(lesson: next)
                .environmentObject(appData)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(.matcha)
            Text("Loading lesson...")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.sakura)
            Text("Error loading lesson")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Text(error)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                Task {
                    await loadLesson()
                }
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.matcha)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.clay)
            Text("No exercises available")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Text("This lesson doesn't have any exercises yet.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
            
            FrencoPrimaryButton(title: "Go Back") {
                dismiss()
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            .padding(.top, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Exercise Content
    private var exerciseContent: some View {
        let exercise = exercises[currentExerciseIndex]
        
        return ScrollView(showsIndicators: false) {
            VStack(spacing: FrencoDesign.verticalSpacing) {
                ExerciseContainerView(
                    exercise: exercise,
                    exerciseNumber: currentExerciseIndex + 1,
                    totalExercises: exercises.count,
                    onComplete: { correct in
                        handleExerciseComplete(correct: correct)
                    }
                )
            }
            .padding(.bottom, 100)
        }
        .id(currentExerciseIndex) // Force view refresh when index changes
    }
    
    // MARK: - Completed View
    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.matcha)
            Text("All exercises completed!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Spacer()
        }
        .onAppear {
            // Only complete once
            if !isCompleting {
                isCompleting = true
                Task {
                    await completeLesson()
                }
                showingCompletion = true
            }
        }
    }
    
    // MARK: - Load Lesson
    private func loadLesson() async {
        isLoading = true
        errorMessage = nil
        startTime = Date()
        
        print("📖 LessonView: Loading lesson \(lesson.id)")
        
        // Check for existing progress and resume
        if let profileId = appData.profile?.id {
            // First check if there's existing progress
            if let existingProgress = await appData.progressService.fetchLessonProgress(
                profileId: profileId,
                lessonId: lesson.id
            ) {
                lessonProgressId = existingProgress.id
                
                // If not completed, resume from where left off
                if existingProgress.status != .completed {
                    let resumeIndex = existingProgress.currentExerciseIndex ?? 0
                    print("📖 LessonView: Resuming from exercise \(resumeIndex + 1)")
                    
                    // We'll set currentExerciseIndex after loading exercises
                    await MainActor.run {
                        self.currentExerciseIndex = resumeIndex
                        self.score = existingProgress.bestScore ?? 0
                    }
                } else {
                    // Lesson was completed, start fresh for review
                    print("📖 LessonView: Lesson already completed, starting review")
                }
            } else {
                // No existing progress, create new
                print("📖 LessonView: Starting fresh progress tracking...")
                if let progress = await appData.progressService.startLesson(
                    profileId: profileId,
                    lessonId: lesson.id
                ) {
                    lessonProgressId = progress.id
                    print("✅ LessonView: Progress tracking started - ID: \(progress.id)")
                }
            }
        }
        
        // Fetch exercises
        if let fullLesson = await appData.contentService.fetchLesson(lessonId: lesson.id) {
            let loadedExercises = (fullLesson.exercises ?? []).sorted { $0.sortOrder < $1.sortOrder }
            
            await MainActor.run {
                self.exercises = loadedExercises
                
                // Make sure currentExerciseIndex doesn't exceed exercise count
                if self.currentExerciseIndex >= loadedExercises.count {
                    self.currentExerciseIndex = 0
                }
                
                print("✅ LessonView: Loaded \(loadedExercises.count) exercises")
                print("📍 Starting at exercise \(self.currentExerciseIndex + 1)")
            }
        } else {
            await MainActor.run {
                errorMessage = "Could not load lesson data"
                print("❌ LessonView: Failed to fetch lesson")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // MARK: - Handle Exercise Complete
    private func handleExerciseComplete(correct: Bool) {
        // Prevent multiple calls for same exercise
        let completedIndex = currentExerciseIndex
        print("📝 Exercise \(completedIndex + 1) completed - Correct: \(correct)")
        
        if correct {
            score += 1
        }
        
        // Save progress
        if let progressId = lessonProgressId {
            let nextIndex = completedIndex + 1
            let progressPercentage = Double(nextIndex) / Double(exercises.count)
            
            Task {
                await appData.progressService.updateLessonProgress(
                    progressId: progressId,
                    exerciseIndex: nextIndex,
                    exercisesCompleted: nextIndex,
                    progressPercentage: progressPercentage
                )
                print("📊 Progress saved: \(Int(progressPercentage * 100))%")
            }
        }
        
        // Move to next exercise OR mark as complete
        withAnimation(.easeOut(duration: 0.3)) {
            currentExerciseIndex = completedIndex + 1
        }
        
        print("📍 Moving to exercise index: \(currentExerciseIndex), total: \(exercises.count)")
    }
    
    // MARK: - Complete Lesson
    private func completeLesson() async {
        guard let profileId = appData.profile?.id else {
            print("❌ Cannot complete lesson: No profile")
            return
        }
        
        print("🎉 Completing lesson...")
        
        let timeSpent = Int(Date().timeIntervalSince(startTime) / 60)
        let xpEarned = lesson.xpReward
        
        // 1. Mark lesson as completed
        if let progressId = lessonProgressId {
            await appData.progressService.completeLesson(
                progressId: progressId,
                score: score,
                xpEarned: xpEarned
            )
            print("✅ Lesson progress marked complete")
        }
        
        // 2. Add XP
        await appData.profileService.addXP(amount: xpEarned)
        print("✅ Added \(xpEarned) XP")
        
        // 3. Increment lessons completed
        await appData.profileService.incrementLessonsCompleted()
        print("✅ Lessons count incremented")
        
        // 4. Update streak
        await appData.profileService.updateStreak()
        print("✅ Streak updated")
        
        // 5. Add minutes practiced
        await appData.profileService.addMinutesPracticed(minutes: max(timeSpent, 1))
        print("✅ Minutes practiced updated")
        
        // 6. Log daily activity
        await appData.progressService.logActivity(
            profileId: profileId,
            minutes: max(timeSpent, 1),
            xp: xpEarned,
            lessonsCompleted: 1
        )
        print("✅ Daily activity logged")
        
        // 7. Refresh app data
        await appData.refreshData()
        print("🎉 Lesson completion saved!")
    }
}

// MARK: - Keep all your existing code below
// (LessonHeader, ExerciseContainerView, all exercise types, LessonCompleteView, etc.)

// MARK: - Lesson Header
struct LessonHeader: View {
    let lessonTitle: String
    let progress: Double
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.wood)
                        .frame(width: 40, height: 40)
                        .background(Color.stone.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(lessonTitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.ink)
                
                Spacer()
                
                // Progress indicator
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.matcha)
                    .frame(width: 40)
            }
            
            // Progress bar
            FrencoProgressBar(progress: progress)
        }
        .padding(.horizontal, FrencoDesign.horizontalPadding)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color.paper)
    }
}

// MARK: - Exercise Container View
struct ExerciseContainerView: View {
    let exercise: Exercise
    let exerciseNumber: Int
    let totalExercises: Int
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise number
            Text("Question \(exerciseNumber) of \(totalExercises)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.wood)
                .padding(.top, 8)
            
            // Exercise content based on type
            switch exercise.exerciseType {
            case .vocabularyIntro:
                VocabularyIntroExercise(exercise: exercise, onComplete: onComplete)
            case .multipleChoice:
                MultipleChoiceExercise(exercise: exercise, onComplete: onComplete)
            case .translation:
                TranslationExercise(exercise: exercise, onComplete: onComplete)
            case .fillBlank:
                FillBlankExercise(exercise: exercise, onComplete: onComplete)
            case .matching:
                MatchingExercise(exercise: exercise, onComplete: onComplete)
            case .listening:
                ListeningExercise(exercise: exercise, onComplete: onComplete)
            case .speaking:
                SpeakingExercise(exercise: exercise, onComplete: onComplete)
            case .conversationPrompt:
                ConversationPromptExercise(exercise: exercise, onComplete: onComplete)
            }
        }
    }
}

// MARK: - Vocabulary Intro Exercise
struct VocabularyIntroExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // Word Card
            VStack(spacing: 20) {
                // French word
                Text(exercise.content.word ?? "Word")
                    .font(.system(size: 42, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.ink)
                
                // Pronunciation
                if let ipa = exercise.content.pronunciationIpa, !ipa.isEmpty {
                    Text("/\(ipa)/")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                }
                
                Rectangle()
                    .fill(Color.clay.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                
                // Translation
                Text(exercise.content.translation ?? "Translation")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.matcha)
                
                // Part of speech
                if let partOfSpeech = exercise.content.partOfSpeech, !partOfSpeech.isEmpty {
                    Text(partOfSpeech)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.sakura)
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: FrencoDesign.cornerRadius)
                    .stroke(Color.wood.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            // Example sentence
            if let example = exercise.content.exampleSentence, !example.isEmpty {
                VStack(spacing: 8) {
                    Text(example)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.ink)
                        .multilineTextAlignment(.center)
                    
                    if let translation = exercise.content.exampleTranslation, !translation.isEmpty {
                        Text(translation)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.matchaLight)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            }
            
            Spacer()
            
            // Continue button
            FrencoPrimaryButton(title: "Got it!") {
                onComplete(true)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Multiple Choice Exercise
struct MultipleChoiceExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    @State private var selectedIndex: Int?
    @State private var hasAnswered = false
    
    private var correctIndex: Int {
        exercise.content.correctIndex ?? 0
    }
    
    private var options: [String] {
        exercise.content.options ?? []
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Question
            Text(exercise.content.question ?? "Select the correct answer")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FrencoDesign.horizontalPadding)
                .padding(.top, 32)
            
            Spacer()
            
            // Options
            VStack(spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    OptionButton(
                        text: option,
                        isSelected: selectedIndex == index,
                        isCorrect: hasAnswered && index == correctIndex,
                        isWrong: hasAnswered && selectedIndex == index && index != correctIndex
                    ) {
                        if !hasAnswered {
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            Spacer()
            
            // Hint
            if let hint = exercise.hint, !hint.isEmpty, !hasAnswered {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.sakura)
                    Text(hint)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                }
                .padding()
                .background(Color.sakuraLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            }
            
            // Feedback
            if hasAnswered {
                HStack(spacing: 8) {
                    Image(systemName: selectedIndex == correctIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(selectedIndex == correctIndex ? .matcha : .sakura)
                    Text(selectedIndex == correctIndex ? "Correct!" : "Not quite. The answer is: \(options[correctIndex])")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(selectedIndex == correctIndex ? .matcha : .sakura)
                }
                .padding()
                .background(selectedIndex == correctIndex ? Color.matchaLight : Color.sakuraLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            }
            
            // Check/Continue button
            Group {
                if hasAnswered {
                    FrencoPrimaryButton(title: "Continue") {
                        onComplete(selectedIndex == correctIndex)
                    }
                } else {
                    FrencoPrimaryButton(title: "Check") {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasAnswered = true
                        }
                    }
                    .opacity(selectedIndex != nil ? 1 : 0.5)
                    .disabled(selectedIndex == nil)
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let text: String
    let isSelected: Bool
    var isCorrect: Bool = false
    var isWrong: Bool = false
    let action: () -> Void
    
    private var backgroundColor: Color {
        if isCorrect { return .matchaLight }
        if isWrong { return .sakuraLight }
        if isSelected { return .stone.opacity(0.2) }
        return .white
    }
    
    private var borderColor: Color {
        if isCorrect { return .matcha }
        if isWrong { return .sakura }
        if isSelected { return .matcha }
        return .clay.opacity(0.3)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.ink)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.matcha)
                        .font(.system(size: 22))
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.sakura)
                        .font(.system(size: 22))
                }
            }
            .padding(16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected || isCorrect || isWrong ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Translation Exercise
struct TranslationExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    @State private var userInput = ""
    @State private var hasAnswered = false
    @State private var isCorrect = false
    @FocusState private var isFocused: Bool
    
    private var acceptedAnswers: [String] {
        exercise.content.acceptedAnswers ?? []
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Translate to French")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.wood)
                .padding(.top, 32)
            
            // Source text
            Text(exercise.content.sourceText ?? "")
                .font(.system(size: 26, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            Spacer()
            
            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Type your translation...", text: $userInput)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.ink)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(hasAnswered ? (isCorrect ? Color.matcha : Color.sakura) : Color.clay.opacity(0.3), lineWidth: hasAnswered ? 2 : 1)
                    )
                    .focused($isFocused)
                    .disabled(hasAnswered)
                    .autocapitalization(.none)
                
                if hasAnswered && !isCorrect {
                    Text("Correct answer: \(acceptedAnswers.first ?? "")")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.matcha)
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            Spacer()
            
            // Check/Continue button
            Group {
                if hasAnswered {
                    FrencoPrimaryButton(title: "Continue") {
                        onComplete(isCorrect)
                    }
                } else {
                    FrencoPrimaryButton(title: "Check") {
                        checkAnswer()
                    }
                    .opacity(userInput.isEmpty ? 0.5 : 1)
                    .disabled(userInput.isEmpty)
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func checkAnswer() {
        isFocused = false
        let normalizedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        isCorrect = acceptedAnswers.contains { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedInput }
        withAnimation(.easeOut(duration: 0.3)) {
            hasAnswered = true
        }
    }
}

// MARK: - Fill in the Blank Exercise
struct FillBlankExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    @State private var selectedOption: String?
    @State private var hasAnswered = false
    
    private var options: [String] {
        exercise.content.options ?? []
    }
    
    private var correctAnswer: String {
        exercise.content.correctAnswer ?? ""
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Fill in the blank")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.wood)
                .padding(.top, 32)
            
            // Sentence with blank
            Text(exercise.content.sentence ?? "_____")
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            // Translation hint
            if let translation = exercise.content.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                    .italic()
            }
            
            Spacer()
            
            // Options
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    OptionButton(
                        text: option,
                        isSelected: selectedOption == option,
                        isCorrect: hasAnswered && option == correctAnswer,
                        isWrong: hasAnswered && selectedOption == option && option != correctAnswer
                    ) {
                        if !hasAnswered {
                            selectedOption = option
                        }
                    }
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            Spacer()
            
            // Check/Continue button
            Group {
                if hasAnswered {
                    FrencoPrimaryButton(title: "Continue") {
                        onComplete(selectedOption == correctAnswer)
                    }
                } else {
                    FrencoPrimaryButton(title: "Check") {
                        withAnimation(.easeOut(duration: 0.3)) {
                            hasAnswered = true
                        }
                    }
                    .opacity(selectedOption != nil ? 1 : 0.5)
                    .disabled(selectedOption == nil)
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Matching Exercise
struct MatchingExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    @State private var selectedLeft: String?
    @State private var matchedPairs: Set<String> = []
    @State private var shuffledRight: [String] = []
    
    private var pairs: [MatchingPair] {
        exercise.content.pairs ?? []
    }
    
    private var allMatched: Bool {
        matchedPairs.count == pairs.count
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Instruction
            Text("Match the pairs")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.wood)
                .padding(.top, 32)
            
            Spacer()
            
            // Matching columns
            HStack(alignment: .top, spacing: 16) {
                // Left column (French)
                VStack(spacing: 12) {
                    ForEach(pairs, id: \.left) { pair in
                        MatchingItemButton(
                            text: pair.left,
                            isSelected: selectedLeft == pair.left,
                            isMatched: matchedPairs.contains(pair.left)
                        ) {
                            if !matchedPairs.contains(pair.left) {
                                selectedLeft = selectedLeft == pair.left ? nil : pair.left
                            }
                        }
                    }
                }
                
                // Right column (English)
                VStack(spacing: 12) {
                    ForEach(shuffledRight, id: \.self) { right in
                        let isMatched = pairs.first(where: { $0.right == right && matchedPairs.contains($0.left) }) != nil
                        
                        MatchingItemButton(
                            text: right,
                            isSelected: false,
                            isMatched: isMatched
                        ) {
                            if let left = selectedLeft, !isMatched {
                                // Check if this is the correct match
                                if let pair = pairs.first(where: { $0.left == left }), pair.right == right {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        matchedPairs.insert(left)
                                    }
                                }
                                selectedLeft = nil
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
            
            Spacer()
            
            // Continue button
            FrencoPrimaryButton(title: allMatched ? "Continue" : "Match all pairs") {
                if allMatched {
                    onComplete(true)
                }
            }
            .opacity(allMatched ? 1 : 0.5)
            .disabled(!allMatched)
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .onAppear {
            shuffledRight = pairs.map { $0.right }.shuffled()
        }
    }
}

// MARK: - Matching Item Button
struct MatchingItemButton: View {
    let text: String
    let isSelected: Bool
    let isMatched: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isMatched ? .white : .ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(isMatched ? Color.matcha : (isSelected ? Color.matchaLight : Color.white))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.matcha : Color.clay.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isMatched)
    }
}

// MARK: - Listening Exercise (Placeholder)
struct ListeningExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.matcha)
            Text("Listening Exercise")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Text("Coming soon!")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
            Spacer()
            FrencoPrimaryButton(title: "Skip for now") {
                onComplete(true)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Speaking Exercise (Placeholder)
struct SpeakingExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "mic.fill")
                .font(.system(size: 48))
                .foregroundColor(.matcha)
            Text("Speaking Exercise")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Text("Coming soon!")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
            Spacer()
            FrencoPrimaryButton(title: "Skip for now") {
                onComplete(true)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Conversation Prompt Exercise (Placeholder)
struct ConversationPromptExercise: View {
    let exercise: Exercise
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.matcha)
            Text("Conversation Exercise")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.ink)
            Text("Coming soon!")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.wood)
            Spacer()
            FrencoPrimaryButton(title: "Skip for now") {
                onComplete(true)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
    }
}

// MARK: - Lesson Complete View
struct LessonCompleteView: View {
    let lesson: Lesson
    let score: Int
    let totalExercises: Int
    let nextLesson: Lesson?  // NEW
    let onContinue: () -> Void
    let onNextLesson: ((Lesson) -> Void)?  // NEW
    
    @Environment(\.dismiss) private var dismiss
    
    private var percentage: Int {
        totalExercises > 0 ? (score * 100) / totalExercises : 100
    }
    
    var body: some View {
        ZStack {
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Celebration icon
                ZStack {
                    Circle()
                        .fill(Color.matchaLight)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.matcha)
                }
                
                // Title
                Text("Lesson Complete!")
                    .font(.system(size: 32, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.ink)
                
                // Score
                VStack(spacing: 8) {
                    Text("\(percentage)%")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.matcha)
                    
                    Text("\(score)/\(totalExercises) correct")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                }
                
                // XP earned
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.sakura)
                    Text("+\(lesson.xpReward) XP")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.sakura)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.sakuraLight)
                .clipShape(Capsule())
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Next Lesson button (if available)
                    if let next = nextLesson {
                        FrencoPrimaryButton(title: "Next: \(next.titleFr)") {
                            dismiss()
                            onNextLesson?(next)
                        }
                    } else {
                        FrencoPrimaryButton(title: "Continue") {
                            dismiss()
                            onContinue()
                        }
                    }
                    
                    // Back to Path (secondary)
                    if nextLesson != nil {
                        Button("Back to Path") {
                            dismiss()
                            onContinue()
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.wood)
                    }
                }
                .padding(.horizontal, FrencoDesign.horizontalPadding)
                .padding(.bottom, 48)
            }
        }
        .interactiveDismissDisabled()
    }
}


// MARK: - Preview
#Preview {
    LessonView(lesson: Lesson(
        id: UUID(),
        unitId: UUID(),
        title: "Saying Hello",
        titleFr: "Dire Bonjour",
        description: "Learn to greet people",
        estimatedMinutes: 10,
        xpReward: 15,
        sortOrder: 1,
        lessonType: "standard",
        isPublished: true,
        exercises: nil,
        progress: nil
    ))
    .environmentObject(AppDataManager())
}
