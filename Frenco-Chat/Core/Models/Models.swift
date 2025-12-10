//
//  Models.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import Foundation

// MARK: - User Profile
struct Profile: Codable, Identifiable {
    let id: UUID
    let clerkUserId: String
    var email: String?
    var displayName: String?
    var avatarUrl: String?
    
    var dailyGoalMinutes: Int
    var preferredVoice: String
    var notificationsEnabled: Bool
    var currentLevel: String
    
    let createdAt: Date
    var updatedAt: Date
    
    var onboardingCompleted: Bool
    var learningMotivation: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case clerkUserId = "clerk_user_id"
        case email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case dailyGoalMinutes = "daily_goal_minutes"
        case preferredVoice = "preferred_voice"
        case notificationsEnabled = "notifications_enabled"
        case currentLevel = "current_level"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case onboardingCompleted = "onboarding_completed"
        case learningMotivation = "learning_motivation"
    }
}

// MARK: - User Stats
struct UserStats: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date?
    
    var totalXp: Int
    var totalWordsLearned: Int
    var totalLessonsCompleted: Int
    var totalConversations: Int
    var totalMinutesPracticed: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case totalXp = "total_xp"
        case totalWordsLearned = "total_words_learned"
        case totalLessonsCompleted = "total_lessons_completed"
        case totalConversations = "total_conversations"
        case totalMinutesPracticed = "total_minutes_practiced"
    }
}

// MARK: - Daily Activity
struct DailyActivity: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let activityDate: Date
    var minutesPracticed: Int
    var xpEarned: Int
    var lessonsCompleted: Int
    var wordsReviewed: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case activityDate = "activity_date"
        case minutesPracticed = "minutes_practiced"
        case xpEarned = "xp_earned"
        case lessonsCompleted = "lessons_completed"
        case wordsReviewed = "words_reviewed"
    }
    
    // Custom decoder for flexible date handling
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        minutesPracticed = try container.decodeIfPresent(Int.self, forKey: .minutesPracticed) ?? 0
        xpEarned = try container.decodeIfPresent(Int.self, forKey: .xpEarned) ?? 0
        lessonsCompleted = try container.decodeIfPresent(Int.self, forKey: .lessonsCompleted) ?? 0
        wordsReviewed = try container.decodeIfPresent(Int.self, forKey: .wordsReviewed) ?? 0
        
        // Handle date string
        let dateString = try container.decode(String.self, forKey: .activityDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        activityDate = formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Level
struct Level: Codable, Identifiable {
    let id: UUID
    let code: String
    let name: String
    let nameFr: String
    let description: String?
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id, code, name, description
        case nameFr = "name_fr"
        case sortOrder = "sort_order"
    }
}

// MARK: - Unit
struct Unit: Codable, Identifiable {
    let id: UUID
    let levelId: UUID
    let title: String
    let titleFr: String
    let description: String?
    let iconName: String?
    let sortOrder: Int
    let isPublished: Bool
    
    // Joined data
    var lessons: [Lesson]?
    var progress: UserUnitProgress?
    
    enum CodingKeys: String, CodingKey {
        case id
        case levelId = "level_id"
        case title
        case titleFr = "title_fr"
        case description
        case iconName = "icon_name"
        case sortOrder = "sort_order"
        case isPublished = "is_published"
        case lessons
        case progress
    }
}

// MARK: - Lesson
struct Lesson: Codable, Identifiable {
    let id: UUID
    let unitId: UUID
    let title: String
    let titleFr: String
    let description: String?
    let estimatedMinutes: Int
    let xpReward: Int
    let sortOrder: Int
    let lessonType: String
    let isPublished: Bool
    
    // Joined data
    var exercises: [Exercise]?
    var progress: UserLessonProgress?
    
    enum CodingKeys: String, CodingKey {
        case id
        case unitId = "unit_id"
        case title
        case titleFr = "title_fr"
        case description
        case estimatedMinutes = "estimated_minutes"
        case xpReward = "xp_reward"
        case sortOrder = "sort_order"
        case lessonType = "lesson_type"
        case isPublished = "is_published"
        case exercises
        case progress
    }
}

// MARK: - Exercise
struct Exercise: Codable, Identifiable {
    let id: UUID
    let lessonId: UUID
    let exerciseType: ExerciseType
    let sortOrder: Int
    let xpValue: Int
    let content: ExerciseContent
    let hint: String?
    let hintFr: String?
    let audioUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case lessonId = "lesson_id"
        case exerciseType = "exercise_type"
        case sortOrder = "sort_order"
        case xpValue = "xp_value"
        case content
        case hint
        case hintFr = "hint_fr"
        case audioUrl = "audio_url"
    }
}

enum ExerciseType: String, Codable {
    case vocabularyIntro = "vocabulary_intro"
    case multipleChoice = "multiple_choice"
    case translation = "translation"
    case fillBlank = "fill_blank"
    case listening = "listening"
    case speaking = "speaking"
    case matching = "matching"
    case conversationPrompt = "conversation_prompt"
}

// MARK: - Exercise Content (Flexible JSON)
struct ExerciseContent: Codable {
    // Vocabulary Intro
    var word: String?
    var translation: String?
    var pronunciationIpa: String?
    var audioUrl: String?
    var imageUrl: String?
    var exampleSentence: String?
    var exampleTranslation: String?
    var gender: String?
    var partOfSpeech: String?
    
    // Multiple Choice
    var question: String?
    var questionFr: String?
    var options: [String]?
    var correctIndex: Int?
    
    // Translation
    var sourceText: String?
    var sourceLanguage: String?
    var targetLanguage: String?
    var acceptedAnswers: [String]?
    
    // Fill Blank
    var sentence: String?
    var blankIndex: Int?
    var correctAnswer: String?
    
    // Matching
    var pairs: [MatchingPair]?
    
    // Conversation Prompt
    var context: String?
    var aiMessage: String?
    var expectedResponseHint: String?
    var sampleResponse: String?
    
    // Listening/Speaking
    var text: String?
    var inputType: String?
    
    enum CodingKeys: String, CodingKey {
        case word, translation, audioUrl, imageUrl, gender, options, question, sentence, context, text, pairs
        case pronunciationIpa = "pronunciation_ipa"
        case exampleSentence = "example_sentence"
        case exampleTranslation = "example_translation"
        case partOfSpeech = "part_of_speech"
        case questionFr = "question_fr"
        case correctIndex = "correct_index"
        case sourceText = "source_text"
        case sourceLanguage = "source_language"
        case targetLanguage = "target_language"
        case acceptedAnswers = "accepted_answers"
        case blankIndex = "blank_index"
        case correctAnswer = "correct_answer"
        case aiMessage = "ai_message"
        case expectedResponseHint = "expected_response_hint"
        case sampleResponse = "sample_response"
        case inputType = "input_type"
    }
}

struct MatchingPair: Codable {
    let left: String
    let right: String
}

// MARK: - User Progress
struct UserLessonProgress: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let lessonId: UUID
    var status: LessonStatus
    var progressPercentage: Double?
    var currentExerciseIndex: Int?
    var exercisesCompleted: Int?
    var bestScore: Int
    var attempts: Int
    var xpEarned: Int
    var startedAt: Date?
    var completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case lessonId = "lesson_id"
        case status
        case progressPercentage = "progress_percentage"
        case currentExerciseIndex = "current_exercise_index"
        case exercisesCompleted = "exercises_completed"
        case bestScore = "best_score"
        case attempts
        case xpEarned = "xp_earned"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

enum LessonStatus: String, Codable {
    case locked
    case available
    case inProgress = "in_progress"
    case completed
}

struct UserUnitProgress: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let unitId: UUID
    var status: LessonStatus
    var progressPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case unitId = "unit_id"
        case status
        case progressPercentage = "progress_percentage"
    }
}

// MARK: - Vocabulary
struct Vocabulary: Codable, Identifiable {
    let id: UUID
    let word: String
    let translation: String
    let pronunciationIpa: String?
    let audioUrl: String?
    let imageUrl: String?
    let gender: String?
    let partOfSpeech: String?
    let pluralForm: String?
    let levelId: UUID?
    let category: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    
    enum CodingKeys: String, CodingKey {
        case id, word, translation, gender, category
        case pronunciationIpa = "pronunciation_ipa"
        case audioUrl = "audio_url"
        case imageUrl = "image_url"
        case partOfSpeech = "part_of_speech"
        case pluralForm = "plural_form"
        case levelId = "level_id"
        case exampleSentence = "example_sentence"
        case exampleTranslation = "example_translation"
    }
}

struct UserVocabulary: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let vocabularyId: UUID
    var easeFactor: Double
    var intervalDays: Int
    var repetitions: Int
    var nextReviewDate: Date?
    var lastReviewedAt: Date?
    var timesCorrect: Int
    var timesIncorrect: Int
    var uniqueDaysCorrect: Int?
    var lastCorrectDate: Date?
    var status: VocabularyStatus
    
    // Joined
    var vocabulary: Vocabulary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case vocabularyId = "vocabulary_id"
        case easeFactor = "ease_factor"
        case intervalDays = "interval_days"
        case repetitions
        case nextReviewDate = "next_review_date"
        case lastReviewedAt = "last_reviewed_at"
        case timesCorrect = "times_correct"
        case timesIncorrect = "times_incorrect"
        case uniqueDaysCorrect = "unique_days_correct"
        case lastCorrectDate = "last_correct_date"
        case status
        case vocabulary
    }
}

enum VocabularyStatus: String, Codable {
    case new
    case learning
    case mastered
}

// MARK: - Grammar
struct GrammarTopic: Codable, Identifiable {
    let id: UUID
    let levelId: UUID?
    let title: String
    let titleFr: String
    let description: String?
    let explanation: String?
    let examples: [GrammarExample]?
    let iconName: String?
    let sortOrder: Int
    
    var progress: UserGrammarProgress?
    
    enum CodingKeys: String, CodingKey {
        case id
        case levelId = "level_id"
        case title
        case titleFr = "title_fr"
        case description
        case explanation
        case examples
        case iconName = "icon_name"
        case sortOrder = "sort_order"
        case progress
    }
}

struct GrammarExample: Codable {
    let french: String
    let english: String
}

struct UserGrammarProgress: Codable, Identifiable {
    let id: UUID
    let profileId: UUID
    let grammarTopicId: UUID
    var masteryPercentage: Double
    var exercisesCompleted: Int
    var uniqueDaysCorrect: Int?
    var lastCorrectDate: String?
    var lastPracticedAt: Date?
    let createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case grammarTopicId = "grammar_topic_id"
        case masteryPercentage = "mastery_percentage"
        case exercisesCompleted = "exercises_completed"
        case uniqueDaysCorrect = "unique_days_correct"
        case lastCorrectDate = "last_correct_date"
        case lastPracticedAt = "last_practiced_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Conversation Scenarios
struct ConversationScenario: Codable, Identifiable {
    let id: UUID
    let title: String
    let titleFr: String
    let description: String
    let iconName: String
    let level: String
    let aiRole: String
    let openingMessage: String
    let goalDescription: String
    let targetVocabulary: [String]
    let systemPrompt: String
    let sortOrder: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, level
        case titleFr = "title_fr"
        case iconName = "icon_name"
        case aiRole = "ai_role"
        case openingMessage = "opening_message"
        case goalDescription = "goal_description"
        case targetVocabulary = "target_vocabulary"
        case systemPrompt = "system_prompt"
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

struct KeyPhrase: Codable {
    let french: String
    let english: String
}


enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

struct GrammarTopicWithProgress: Identifiable {
    let id: UUID
    let title: String
    let titleFr: String
    let description: String
    let explanation: String
    let sortOrder: Int
    var masteryPercentage: Double
    var uniqueDaysCorrect: Int
    var exercisesCompleted: Int
    var lastPracticedAt: Date?
}

// MARK: - Grammar Exercise
struct GrammarExercise: Codable, Identifiable {
    let id: UUID
    let grammarTopicId: UUID
    let exerciseType: String
    let difficulty: Int
    let content: ExerciseContent
    let hint: String?
    let hintFr: String?
    let isActive: Bool?
    let timesServed: Int?
    let timesCorrect: Int?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, difficulty, content, hint, isActive
        case grammarTopicId = "grammar_topic_id"
        case exerciseType = "exercise_type"
        case hintFr = "hint_fr"
        case timesServed = "times_served"
        case timesCorrect = "times_correct"
        case createdAt = "created_at"
    }
}

// MARK: - Conversation
struct Conversation: Codable, Identifiable {
    let id: UUID
    let userId: String
    let scenarioId: UUID
    var status: ConversationStatus
    let startedAt: Date?
    var completedAt: Date?
    var messageCount: Int
    var correctionsCount: Int
    var vocabularyPracticed: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case scenarioId = "scenario_id"
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case messageCount = "message_count"
        case correctionsCount = "corrections_count"
        case vocabularyPracticed = "vocabulary_practiced"
    }
}

enum ConversationStatus: String, Codable {
    case active
    case completed
    case abandoned
}

// MARK: - Conversation Message
struct ConversationMessage: Codable, Identifiable {
    let id: UUID
    let conversationId: UUID
    let role: MessageRole
    let content: String
    let correction: String?
    let vocabularyUsed: [String]?
    let isGoalComplete: Bool
    let createdAt: Date?
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role, content, correction
        case vocabularyUsed = "vocabulary_used"
        case isGoalComplete = "is_goal_complete"
        case createdAt = "created_at"
        case sortOrder = "sort_order"
    }
}


// MARK: - Chat API Response (from Edge Function)
struct ChatAPIResponse: Codable {
    let success: Bool
    let data: ChatResponseData?
    let error: String?
}

struct ChatResponseData: Codable {
    let message: String
    let correction: String?
    let isGoalComplete: Bool
    let vocabularyUsed: [String]
    
    enum CodingKeys: String, CodingKey {
        case message, correction
        case isGoalComplete = "is_goal_complete"
        case vocabularyUsed = "vocabulary_used"
    }
}
