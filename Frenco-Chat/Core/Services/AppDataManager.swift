//
//  AppDataManager.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk
import Combine

// MARK: - App Data Manager
// Central manager that coordinates all services
@MainActor
class AppDataManager: ObservableObject {
    // Services
    let profileService = ProfileService()
    let contentService = ContentService()
    let progressService = ProgressService()
    let vocabularyService = VocabularyService()
    let conversationService = ConversationService()
    let grammarService = GrammarService()
    let chatService = ChatService()
    
    // App state
    @Published var isInitialized = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Published Data (for SwiftUI reactivity)
    @Published private(set) var profile: Profile?
    @Published private(set) var stats: UserStats?
    @Published private(set) var units: [Unit] = []
    @Published private(set) var weeklyActivity: [DailyActivity] = []
    @Published private(set) var scenarios: [ConversationScenario] = []
    @Published private(set) var recentConversations: [Conversation] = []
    @Published private(set) var vocabularyCategories: [VocabularyCategory] = []
    @Published private(set) var wordsToReview: [UserVocabulary] = []
    @Published private(set) var grammarTopics: [GrammarTopic] = []
    @Published var onboardingCompleted: Bool = false
    
    // MARK: - Computed Properties
    var currentStreak: Int { stats?.currentStreak ?? 0 }
    var totalXp: Int { stats?.totalXp ?? 0 }
    var totalWordsLearned: Int { stats?.totalWordsLearned ?? 0 }
    var totalLessonsCompleted: Int { stats?.totalLessonsCompleted ?? 0 }
    var totalMinutesPracticed: Int { stats?.totalMinutesPracticed ?? 0 }
    var totalConversations: Int { stats?.totalConversations ?? 0 }
    
    var userId: String? {
        profile?.id.uuidString
    }
    
    var allLessonsFlat: [Lesson] {
        units
            .flatMap { $0.lessons ?? [] }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    var todayActivity: DailyActivity? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return weeklyActivity.first { activity in
            formatter.string(from: activity.activityDate) == today
        }
    }
    
    var displayName: String {
        profile?.displayName?.isEmpty == false ? profile!.displayName! : "Learner"
    }
    
    var initials: String {
        String(displayName.prefix(1)).uppercased()
    }
    
    var currentLevel: String {
        profile?.currentLevel ?? "A1"
    }
    
    // Get current lesson (first incomplete lesson)
    var currentLesson: Lesson? {
        let allLessons = units
            .flatMap { $0.lessons ?? [] }
            .sorted { $0.sortOrder < $1.sortOrder }
        
        // Find first lesson that's not completed
        for lesson in allLessons {
            if lesson.progress?.status != .completed {
                return lesson
            }
        }
        
        // All completed, return last lesson for review
        return allLessons.last
    }
    
    // Get current unit
    var currentUnit: Unit? {
        units.first { $0.progress?.status != .completed } ?? units.first
    }
    
    // Calculate daily progress (based on today's activity)
    var dailyProgress: Double {
        guard let profile = profile else { return 0 }
        let dailyGoal = max(profile.dailyGoalMinutes, 1)
        let todayMinutes = todayActivity?.minutesPracticed ?? 0
        return min(Double(todayMinutes) / Double(dailyGoal), 1.0)
    }
    
    // Weekly minutes total
    var weeklyMinutesTotal: Int {
        weeklyActivity.reduce(0) { $0 + $1.minutesPracticed }
    }
    
    // Format time for display
    func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)min"
        }
        return "\(mins)min"
    }
    
    func checkOnboardingStatus() {
        onboardingCompleted = profileService.profile?.onboardingCompleted ?? false
    }
    
    // MARK: - Initialize for User
    func initializeForUser(clerkUserId: String, email: String?, displayName: String?) async {
        isLoading = true
        errorMessage = nil
        
        Log.debug("🎯 AppDataManager: Initializing for user \(clerkUserId)")
        
        defer {
            isLoading = false
            isInitialized = true
            Log.debug("🎯 AppDataManager: Initialization complete")
        }
        
        // 1. Get or create profile
        await profileService.getOrCreateProfile(
            clerkUserId: clerkUserId,
            email: email,
            displayName: displayName
        )
        
        // Sync profile data
        self.profile = profileService.profile
        self.stats = profileService.stats
        
        self.onboardingCompleted = profileService.profile?.onboardingCompleted ?? false
        
        guard let profile = self.profile else {
            errorMessage = "Failed to load profile"
            Log.debug("❌ AppDataManager: No profile created")
            return
        }
        
        Log.debug("🎯 AppDataManager: Profile loaded, fetching content...")
        
        // 2. Load content
        await contentService.fetchLevels()
        await conversationService.fetchScenarios()
        
        // 3. Load user-specific data
        await contentService.fetchUnits(levelCode: profile.currentLevel, profileId: profile.id)
        await progressService.fetchWeeklyActivity(profileId: profile.id)
        await vocabularyService.fetchCategories(profileId: profile.id)
        await vocabularyService.fetchWordsToReview(profileId: profile.id)
        await conversationService.fetchRecentConversations(profileId: profile.id)
        await grammarService.fetchTopics(levelCode: profile.currentLevel, profileId: profile.id)
        
        // Sync all data to published properties
        syncData()
        
        Log.debug("🎯 AppDataManager: All data synced")
        Log.debug("   - Units: \(units.count)")
        Log.debug("   - Scenarios: \(scenarios.count)")
        Log.debug("   - Grammar Topics: \(grammarTopics.count)")
        Log.debug("   - Vocabulary Categories: \(vocabularyCategories.count)")
    }
    
    // MARK: - Sync Data from Services
    private func syncData() {
        self.profile = profileService.profile
        self.stats = profileService.stats
        self.units = contentService.currentLevelUnits
        self.weeklyActivity = progressService.weeklyActivity
        self.scenarios = conversationService.scenarios
        self.recentConversations = conversationService.recentConversations
        self.vocabularyCategories = vocabularyService.categories
        self.wordsToReview = vocabularyService.wordsToReview
        self.grammarTopics = grammarService.topics
    }
    
    // MARK: - Refresh Data
    func refreshData() async {
        guard let profile = profile else { return }
        
        Log.debug("🔄 AppDataManager: Refreshing data...")
        
        await profileService.fetchStats()
        await contentService.fetchUnits(levelCode: profile.currentLevel, profileId: profile.id)
        await progressService.fetchWeeklyActivity(profileId: profile.id)
        await vocabularyService.fetchWordsToReview(profileId: profile.id)
        await conversationService.fetchRecentConversations(profileId: profile.id)
        
        // Sync updated data
        syncData()
        
        Log.debug("🔄 AppDataManager: Refresh complete")
    }
    
    // MARK: - Clear on Sign Out
    func clearData() {
        Log.debug("🧹 AppDataManager: Clearing all data")
        
        profileService.profile = nil
        profileService.stats = nil
        
        // Clear published properties
        profile = nil
        stats = nil
        units = []
        weeklyActivity = []
        scenarios = []
        recentConversations = []
        vocabularyCategories = []
        wordsToReview = []
        grammarTopics = []
        
        isInitialized = false
        errorMessage = nil
    }
}
