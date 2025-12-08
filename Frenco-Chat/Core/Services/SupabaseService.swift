//
//  SupabaseService.swift
//  Frenco-Chat
//
// enum SupabaseConfig {
// static let url = URL(string: "https://wkxgzvuhljysvijfyctq.supabase.co")!
// static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndreGd6dnVobGp5c3ZpamZ5Y3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMDQyMjQsImV4cCI6MjA3OTg4MDIyNH0.8xOxew9XvzSqXZlH9FOrCR9gCBHNE9bvQVkqQd1Wzt0"
// }

//  Created by Shakeb . on 2025-11-27.
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase Configuration
// ⚠️ REPLACE THESE WITH YOUR ACTUAL SUPABASE CREDENTIALS
// Get them from: Supabase Dashboard → Settings → API
enum SupabaseConfig {
    static let url = URL(string: "https://wkxgzvuhljysvijfyctq.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndreGd6dnVobGp5c3ZpamZ5Y3RxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMDQyMjQsImV4cCI6MjA3OTg4MDIyNH0.8xOxew9XvzSqXZlH9FOrCR9gCBHNE9bvQVkqQd1Wzt0"
}

// MARK: - Supabase Client Singleton
let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey
)

// MARK: - Profile Service
@MainActor
class ProfileService: ObservableObject {
    @Published var profile: Profile?
    @Published var stats: UserStats?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Get or Create Profile
    func getOrCreateProfile(clerkUserId: String, email: String?, displayName: String?) async {
        isLoading = true
        defer { isLoading = false }
        
        print("📝 ProfileService: Getting/creating profile for \(clerkUserId)")
        
        do {
            // Try to fetch existing profile
            let response: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("clerk_user_id", value: clerkUserId)
                .execute()
                .value
            
            print("📝 ProfileService: Found \(response.count) existing profiles")
            
            if let existing = response.first {
                self.profile = existing
                print("✅ ProfileService: Using existing profile: \(existing.id)")
                await fetchStats()
                return
            }
            
            // Create new profile
            print("📝 ProfileService: Creating new profile...")
            let newProfile: [String: String] = [
                "clerk_user_id": clerkUserId,
                "email": email ?? "",
                "display_name": displayName ?? ""
            ]
            
            let created: [Profile] = try await supabase
                .from("profiles")
                .insert(newProfile)
                .select()
                .execute()
                .value
            
            if let createdProfile = created.first {
                self.profile = createdProfile
                print("✅ ProfileService: Created new profile: \(createdProfile.id)")
                
                // Create initial stats
                let newStats: [String: String] = ["profile_id": createdProfile.id.uuidString]
                let _: [UserStats] = try await supabase
                    .from("user_stats")
                    .insert(newStats)
                    .select()
                    .execute()
                    .value
                
                print("✅ ProfileService: Created user stats")
                await fetchStats()
            }
            
        } catch {
            self.error = error
            print("❌ ProfileService Error: \(error)")
        }
    }
    
    // MARK: - Increment Conversations
    func incrementConversations() async {
        guard let stats = stats else { return }
        
        do {
            try await supabase
                .from("user_stats")
                .update(["total_conversations": stats.totalConversations + 1])
                .eq("profile_id", value: stats.profileId.uuidString)
                .execute()
            
            // Update local state
            self.stats?.totalConversations += 1
            print("✅ Incremented total conversations")
        } catch {
            print("❌ Failed to increment conversations: \(error)")
        }
    }
    
    // MARK: - Fetch Stats
    func fetchStats() async {
        guard let profileId = profile?.id else {
            print("⚠️ ProfileService: No profile ID for fetching stats")
            return
        }
        
        do {
            let response: [UserStats] = try await supabase
                .from("user_stats")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .execute()
                .value
            
            self.stats = response.first
            print("✅ ProfileService: Fetched stats - streak: \(stats?.currentStreak ?? 0)")
        } catch {
            print("❌ ProfileService Stats Error: \(error)")
        }
    }
    
    // MARK: - Update Profile
    func updateProfile(displayName: String? = nil, dailyGoalMinutes: Int? = nil) async {
        guard let profileId = profile?.id else { return }
        
        var updates: [String: AnyJSON] = [:]
        if let name = displayName { updates["display_name"] = AnyJSON.string(name) }
        if let goal = dailyGoalMinutes { updates["daily_goal_minutes"] = AnyJSON.integer(goal) }
        
        do {
            let response: [Profile] = try await supabase
                .from("profiles")
                .update(updates)
                .eq("id", value: profileId.uuidString)
                .select()
                .execute()
                .value
            
            self.profile = response.first
            print("✅ ProfileService: Profile updated")
        } catch {
            print("❌ ProfileService Update Error: \(error)")
        }
    }
    
    // MARK: - Add XP
    func addXP(amount: Int) async {
        guard let currentStats = stats else {
            print("❌ ProfileService: No stats to update")
            return
        }
        
        let newTotalXP = currentStats.totalXp + amount
        
        let updates: [String: AnyJSON] = [
            "total_xp": .integer(newTotalXP)
        ]
        
        do {
            let updatedStats: [UserStats] = try await supabase
                .from("user_stats")
                .update(updates)
                .eq("id", value: currentStats.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updated = updatedStats.first {
                self.stats = updated
                print("✅ ProfileService: XP updated to \(newTotalXP)")
            }
        } catch {
            print("❌ ProfileService Add XP Error: \(error)")
        }
    }

    // MARK: - Increment Lessons Completed
    func incrementLessonsCompleted() async {
        guard let currentStats = stats else { return }
        
        let newCount = currentStats.totalLessonsCompleted + 1
        
        let updates: [String: AnyJSON] = [
            "total_lessons_completed": .integer(newCount)
        ]
        
        do {
            let updatedStats: [UserStats] = try await supabase
                .from("user_stats")
                .update(updates)
                .eq("id", value: currentStats.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updated = updatedStats.first {
                self.stats = updated
                print("✅ ProfileService: Lessons completed: \(newCount)")
            }
        } catch {
            print("❌ ProfileService Increment Lessons Error: \(error)")
        }
    }

    // MARK: - Update Streak
    func updateStreak() async {
        guard let currentStats = stats else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var newStreak = currentStats.currentStreak
        var longestStreak = currentStats.longestStreak
        
        if let lastActive = currentStats.lastActivityDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let daysDifference = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day - don't change streak
                print("📅 ProfileService: Same day, streak unchanged")
            } else if daysDifference == 1 {
                // Consecutive day
                newStreak += 1
                longestStreak = max(longestStreak, newStreak)
                print("🔥 ProfileService: Streak incremented to \(newStreak)")
            } else {
                // Streak broken
                newStreak = 1
                print("💔 ProfileService: Streak reset to 1")
            }
        } else {
            newStreak = 1
            print("🆕 ProfileService: First activity, streak = 1")
        }
        
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        let updates: [String: AnyJSON] = [
            "current_streak": .integer(newStreak),
            "longest_streak": .integer(longestStreak),
            "last_active_at": .string(now)
        ]
        
        do {
            let updatedStats: [UserStats] = try await supabase
                .from("user_stats")
                .update(updates)
                .eq("id", value: currentStats.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updated = updatedStats.first {
                self.stats = updated
            }
        } catch {
            print("❌ ProfileService Update Streak Error: \(error)")
        }
    }

    // MARK: - Add Minutes Practiced
    func addMinutesPracticed(minutes: Int) async {
        guard let currentStats = stats else { return }
        
        let newTotal = currentStats.totalMinutesPracticed + minutes
        
        let updates: [String: AnyJSON] = [
            "total_minutes_practiced": .integer(newTotal)
        ]
        
        do {
            let updatedStats: [UserStats] = try await supabase
                .from("user_stats")
                .update(updates)
                .eq("id", value: currentStats.id.uuidString)
                .select()
                .execute()
                .value
            
            if let updated = updatedStats.first {
                self.stats = updated
            }
        } catch {
            print("❌ ProfileService Add Minutes Error: \(error)")
        }
    }
    
    // MARK: - Complete Onboarding
    func completeOnboarding(
        dailyGoalMinutes: Int,
        currentLevel: String,
        learningMotivation: String?
    ) async {
        guard let profile = profile else { return }
        
        struct OnboardingUpdate: Codable {
            let daily_goal_minutes: Int
            let current_level: String
            let learning_motivation: String?
            let onboarding_completed: Bool
        }
        
        let update = OnboardingUpdate(
            daily_goal_minutes: dailyGoalMinutes,
            current_level: currentLevel,
            learning_motivation: learningMotivation,
            onboarding_completed: true
        )
        
        do {
            try await supabase
                .from("profiles")
                .update(update)
                .eq("id", value: profile.id.uuidString)
                .execute()
            
            // Update local state
            self.profile?.dailyGoalMinutes = dailyGoalMinutes
            self.profile?.currentLevel = currentLevel
            self.profile?.learningMotivation = learningMotivation
            self.profile?.onboardingCompleted = true
            
            print("✅ Onboarding completed")
        } catch {
            print("❌ Failed to complete onboarding: \(error)")
        }
    }
}

// MARK: - Content Service
@MainActor
class ContentService: ObservableObject {
    @Published var levels: [Level] = []
    @Published var currentLevelUnits: [Unit] = []
    @Published var isLoading = false
    
    // MARK: - Fetch Levels
    func fetchLevels() async {
        isLoading = true
        defer { isLoading = false }
        
        print("📚 ContentService: Fetching levels...")
        
        do {
            let response: [Level] = try await supabase
                .from("levels")
                .select()
                .order("sort_order")
                .execute()
                .value
            
            self.levels = response
            print("✅ ContentService: Fetched \(response.count) levels")
        } catch {
            print("❌ ContentService Levels Error: \(error)")
        }
    }
    
    // MARK: - Fetch Units for Level
    func fetchUnits(levelCode: String, profileId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        print("📚 ContentService: Fetching units for level \(levelCode)...")
        
        // Ensure levels are loaded
        if levels.isEmpty {
            await fetchLevels()
        }
        
        guard let level = levels.first(where: { $0.code == levelCode }) else {
            print("⚠️ ContentService: Level \(levelCode) not found")
            return
        }
        
        do {
            // Fetch units with nested lessons
            var units: [Unit] = try await supabase
                .from("units")
                .select("*, lessons(*)")
                .eq("level_id", value: level.id.uuidString)
                .eq("is_published", value: true)
                .order("sort_order")
                .execute()
                .value
            
            print("✅ ContentService: Fetched \(units.count) units")
            
            // Collect all lesson IDs
            let allLessonIds = units.flatMap { $0.lessons ?? [] }.map { $0.id.uuidString }
            
            if !allLessonIds.isEmpty {
                // Fetch lesson progress for all lessons
                let lessonProgress: [UserLessonProgress] = try await supabase
                    .from("user_lesson_progress")
                    .select()
                    .eq("profile_id", value: profileId.uuidString)
                    .in("lesson_id", values: allLessonIds)
                    .execute()
                    .value
                
                print("✅ ContentService: Fetched progress for \(lessonProgress.count) lessons")
                
                // Merge progress into lessons
                for i in 0..<units.count {
                    if var lessons = units[i].lessons {
                        for j in 0..<lessons.count {
                            lessons[j].progress = lessonProgress.first {
                                $0.lessonId == lessons[j].id
                            }
                        }
                        units[i].lessons = lessons
                    }
                }
            }
            
            // Also fetch unit progress
            if !units.isEmpty {
                let unitIds = units.map { $0.id.uuidString }
                let unitProgress: [UserUnitProgress] = try await supabase
                    .from("user_unit_progress")
                    .select()
                    .eq("profile_id", value: profileId.uuidString)
                    .in("unit_id", values: unitIds)
                    .execute()
                    .value
                
                for i in 0..<units.count {
                    units[i].progress = unitProgress.first { $0.unitId == units[i].id }
                }
            }
            
            self.currentLevelUnits = units
            
        } catch {
            print("❌ ContentService Units Error: \(error)")
        }
    }
    
    // MARK: - Fetch Lesson with Exercises
    func fetchLesson(lessonId: UUID) async -> Lesson? {
        do {
            let lessons: [Lesson] = try await supabase
                .from("lessons")
                .select("*, exercises(*)")
                .eq("id", value: lessonId.uuidString)
                .execute()
                .value
            
            return lessons.first
        } catch {
            print("❌ ContentService Lesson Error: \(error)")
            return nil
        }
    }
}

// MARK: - Progress Service
@MainActor
class ProgressService: ObservableObject {
    @Published var lessonProgress: [UserLessonProgress] = []
    @Published var weeklyActivity: [DailyActivity] = []
    
    // MARK: - Fetch Weekly Activity
    func fetchWeeklyActivity(profileId: UUID) async {
        let calendar = Calendar.current
        let today = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let weekAgoString = formatter.string(from: weekAgo)
        
        print("📊 ProgressService: Fetching weekly activity since \(weekAgoString)...")
        
        do {
            let activities: [DailyActivity] = try await supabase
                .from("daily_activity")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .gte("activity_date", value: weekAgoString)
                .order("activity_date")
                .execute()
                .value
            
            self.weeklyActivity = activities
            print("✅ ProgressService: Fetched \(activities.count) daily activities")
        } catch {
            print("❌ ProgressService Weekly Error: \(error)")
        }
    }
    
    // MARK: - Check if User Practiced Today
    func hasActivityToday(profileId: UUID) async -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        do {
            let activity: [DailyActivity] = try await supabase
                .from("daily_activity")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .eq("activity_date", value: today)
                .execute()
                .value
            
            return !activity.isEmpty
            
        } catch {
            print("❌ ProgressService Activity Check Error: \(error)")
            return false
        }
    }
    
    // MARK: - Get Lesson Progress
    func fetchLessonProgress(profileId: UUID, lessonId: UUID) async -> UserLessonProgress? {
        do {
            let progress: [UserLessonProgress] = try await supabase
                .from("user_lesson_progress")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .eq("lesson_id", value: lessonId.uuidString)
                .execute()
                .value
            
            return progress.first
        } catch {
            print("❌ ProgressService Lesson Progress Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Start Lesson
    func startLesson(profileId: UUID, lessonId: UUID) async -> UserLessonProgress? {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        let newProgress: [String: String] = [
            "profile_id": profileId.uuidString,
            "lesson_id": lessonId.uuidString,
            "status": "in_progress",
            "started_at": now
        ]
        
        do {
            let progress: [UserLessonProgress] = try await supabase
                .from("user_lesson_progress")
                .upsert(newProgress)
                .select()
                .execute()
                .value
            
            return progress.first
        } catch {
            print("❌ ProgressService Start Lesson Error: \(error)")
            return nil
        }
    }
    
    // MARK: - Complete Lesson
    func completeLesson(progressId: UUID, score: Int, xpEarned: Int) async {
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        
        let updates: [String: AnyJSON] = [
            "status": .string("completed"),
            "progress_percentage": .double(100.0),
            "best_score": .integer(score),
            "xp_earned": .integer(xpEarned),
            "completed_at": .string(now)
        ]
        
        do {
            let _: [UserLessonProgress] = try await supabase
                .from("user_lesson_progress")
                .update(updates)
                .eq("id", value: progressId.uuidString)
                .select()
                .execute()
                .value
            print("✅ ProgressService: Lesson completed")
        } catch {
            print("❌ ProgressService Complete Lesson Error: \(error)")
        }
    }
    
    // MARK: - Log Daily Activity
    func logActivity(profileId: UUID, minutes: Int, xp: Int, lessonsCompleted: Int = 0) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        let activity: [String: AnyJSON] = [
            "profile_id": .string(profileId.uuidString),
            "activity_date": .string(today),
            "minutes_practiced": .integer(minutes),
            "xp_earned": .integer(xp),
            "lessons_completed": .integer(lessonsCompleted)
        ]
        
        do {
            let _: [DailyActivity] = try await supabase
                .from("daily_activity")
                .upsert(activity)
                .select()
                .execute()
                .value
            print("✅ ProgressService: Activity logged")
        } catch {
            print("❌ ProgressService Log Activity Error: \(error)")
        }
    }
    
    // MARK: - Update Lesson Progress
    func updateLessonProgress(
        progressId: UUID,
        exerciseIndex: Int,
        exercisesCompleted: Int,
        progressPercentage: Double
    ) async {
        let updates: [String: AnyJSON] = [
            "current_exercise_index": .integer(exerciseIndex),
            "exercises_completed": .integer(exercisesCompleted),
            "progress_percentage": .double(progressPercentage * 100)
        ]
        
        do {
            let _: [UserLessonProgress] = try await supabase
                .from("user_lesson_progress")
                .update(updates)
                .eq("id", value: progressId.uuidString)
                .select()
                .execute()
                .value
            print("✅ ProgressService: Progress updated to \(Int(progressPercentage * 100))%")
        } catch {
            print("❌ ProgressService Update Error: \(error)")
        }
    }
}

// MARK: - Vocabulary Service
@MainActor
class VocabularyService: ObservableObject {
    @Published var categories: [VocabularyCategory] = []
    @Published var wordsToReview: [UserVocabulary] = []
    
    // MARK: - Fetch Categories with Counts
    func fetchCategories(profileId: UUID) async {
        print("📖 VocabularyService: Fetching categories...")
        
        do {
            // Get all vocabulary grouped by category
            let vocab: [Vocabulary] = try await supabase
                .from("vocabulary")
                .select()
                .execute()
                .value
            
            print("✅ VocabularyService: Fetched \(vocab.count) vocabulary words")
            
            // Get user's vocabulary progress
            let userVocab: [UserVocabulary] = try await supabase
                .from("user_vocabulary")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .execute()
                .value
            
            // Group by category
            var categoryDict: [String: (total: Int, learned: Int, mastered: Int)] = [:]
            for word in vocab {
                let cat = word.category ?? "Other"
                let current = categoryDict[cat] ?? (0, 0, 0)
                let isLearned = userVocab.contains { $0.vocabularyId == word.id && $0.status != .new }
                let isMastered = userVocab.contains { $0.vocabularyId == word.id && $0.status == .mastered }
                categoryDict[cat] = (
                    current.total + 1,
                    current.learned + (isLearned ? 1 : 0),
                    current.mastered + (isMastered ? 1 : 0)
                )
            }
            
            // Convert to array
            self.categories = categoryDict.map { key, value in
                VocabularyCategory(
                    id: key,
                    name: key.capitalized,
                    nameFr: key.capitalized,
                    wordCount: value.total,
                    learnedCount: value.learned,
                    masteredCount: value.mastered,
                    iconName: categoryIcon(key)
                )
            }.sorted { $0.name < $1.name }
            
            print("✅ VocabularyService: Created \(categories.count) categories")
            
        } catch {
            print("❌ VocabularyService Categories Error: \(error)")
        }
    }
    
    // MARK: - Fetch Vocabulary Categories with Stats
    func fetchVocabularyCategories(profileId: UUID) async -> [VocabularyCategory] {
        print("📖 VocabularyService: Fetching vocabulary categories...")
        
        do {
            // 1. Get all vocabulary grouped by category
            let allVocab: [Vocabulary] = try await supabase
                .from("vocabulary")
                .select()
                .execute()
                .value
            
            // 2. Get user's vocabulary progress
            let userVocab: [UserVocabulary] = try await supabase
                .from("user_vocabulary")
                .select("*, vocabulary(*)")
                .eq("profile_id", value: profileId.uuidString)
                .execute()
                .value
            
            // 3. Group vocabulary by category
            var categoryDict: [String: (total: Int, learned: Int, mastered: Int)] = [:]
            
            for vocab in allVocab {
                let category = vocab.category ?? "Uncategorized"
                if categoryDict[category] == nil {
                    categoryDict[category] = (total: 0, learned: 0, mastered: 0)
                }
                categoryDict[category]?.total += 1
            }
            
            // 4. Count learned and mastered per category
            for uv in userVocab {
                guard let vocab = uv.vocabulary else { continue }
                let category = vocab.category ?? "Uncategorized"
                
                if categoryDict[category] != nil {
                    categoryDict[category]?.learned += 1
                    if uv.status == .mastered {
                        categoryDict[category]?.mastered += 1
                    }
                }
            }
            
            // 5. Convert to array
            let categories = categoryDict.map { (key, value) in
                VocabularyCategory(
                    id: key,
                    name: key,
                    nameFr: key,  // Same for now, can localize later
                    wordCount: value.total,
                    learnedCount: value.learned,
                    masteredCount: value.mastered,
                    iconName: "book.fill"  // Default icon
                )
            }.sorted { $0.name < $1.name }
            
            print("✅ VocabularyService: Found \(categories.count) categories")
            return categories
            
        } catch {
            print("❌ VocabularyService Categories Error: \(error)")
            return []
        }
    }

    // MARK: - Fetch Words Due by Category
    func fetchWordsDueByCategory(profileId: UUID, category: String) async -> [UserVocabulary] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        print("📖 VocabularyService: Fetching words due for category: \(category)")
        
        do {
            let words: [UserVocabulary] = try await supabase
                .from("user_vocabulary")
                .select("*, vocabulary!inner(*)")
                .eq("profile_id", value: profileId.uuidString)
                .lte("next_review_date", value: today)
                .eq("vocabulary.category", value: category)
                .limit(20)
                .execute()
                .value
            
            print("✅ VocabularyService: \(words.count) words due in \(category)")
            return words
            
        } catch {
            print("❌ VocabularyService Words Due Error: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Words to Review
    func fetchWordsToReview(profileId: UUID, limit: Int = 20) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        
        print("📖 VocabularyService: Fetching words to review...")
        
        do {
            let words: [UserVocabulary] = try await supabase
                .from("user_vocabulary")
                .select("*, vocabulary(*)")
                .eq("profile_id", value: profileId.uuidString)
                .lte("next_review_date", value: today)
                .limit(limit)
                .execute()
                .value
            
            self.wordsToReview = words
            print("✅ VocabularyService: \(words.count) words to review")
        } catch {
            print("❌ VocabularyService Words to Review Error: \(error)")
        }
    }
    
    // MARK: - Add Vocabulary From Completed Lesson
    func addVocabularyFromLesson(profileId: UUID, lessonId: UUID) async {
        print("📖 VocabularyService: Adding vocabulary from lesson...")
        
        do {
            // 1. Get all vocabulary_intro exercises from this lesson
            let exercises: [Exercise] = try await supabase
                .from("exercises")
                .select()
                .eq("lesson_id", value: lessonId.uuidString)
                .eq("exercise_type", value: "vocabulary_intro")
                .execute()
                .value
            
            print("📖 Found \(exercises.count) vocabulary exercises")
            
            // 2. For each exercise, extract word and find in vocabulary table
            for exercise in exercises {
                guard let word = exercise.content.word else {
                    continue
                }
                
                // 3. Find vocabulary record by word
                let vocabRecords: [Vocabulary] = try await supabase
                    .from("vocabulary")
                    .select()
                    .eq("word", value: word)
                    .limit(1)
                    .execute()
                    .value
                
                guard let vocab = vocabRecords.first else {
                    print("⚠️ Vocabulary not found for word: \(word)")
                    continue
                }
                
                // 4. Check if user already has this word
                let existing: [UserVocabulary] = try await supabase
                    .from("user_vocabulary")
                    .select()
                    .eq("profile_id", value: profileId.uuidString)
                    .eq("vocabulary_id", value: vocab.id.uuidString)
                    .execute()
                    .value
                
                if existing.isEmpty {
                    // 5. Insert new user_vocabulary with initial SM-2 values
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let nextReviewDate = formatter.string(from: tomorrow)
                    
                    let newUserVocab: [String: AnyJSON] = [
                        "profile_id": .string(profileId.uuidString),
                        "vocabulary_id": .string(vocab.id.uuidString),
                        "ease_factor": .double(2.5),
                        "interval_days": .integer(1),
                        "repetitions": .integer(0),
                        "next_review_date": .string(nextReviewDate),
                        "times_correct": .integer(0),
                        "times_incorrect": .integer(0),
                        "unique_days_correct": .integer(0),
                        "status": .string("new")
                    ]
                    
                    try await supabase
                        .from("user_vocabulary")
                        .insert(newUserVocab)
                        .execute()
                    
                    print("✅ Added vocabulary: \(word)")
                } else {
                    print("⏭️ Already has vocabulary: \(word)")
                }
            }
            
            print("✅ VocabularyService: Finished adding vocabulary from lesson")
            
        } catch {
            print("❌ VocabularyService Add Vocabulary Error: \(error)")
        }
    }
    
    // MARK: - Update Review (SM-2 Algorithm with Mastery)
    func updateReview(userVocabId: UUID, isCorrect: Bool) async {
        print("📖 VocabularyService: Updating review...")
        
        do {
            // 1. Fetch current user_vocabulary record
            let records: [UserVocabulary] = try await supabase
                .from("user_vocabulary")
                .select()
                .eq("id", value: userVocabId.uuidString)
                .limit(1)
                .execute()
                .value
            
            guard var vocab = records.first else {
                print("❌ UserVocabulary not found")
                return
            }
            
            // 2. Get current values
            var easeFactor = vocab.easeFactor
            var interval = vocab.intervalDays
            var repetitions = vocab.repetitions
            var timesCorrect = vocab.timesCorrect
            var timesIncorrect = vocab.timesIncorrect
            var uniqueDaysCorrect = vocab.uniqueDaysCorrect ?? 0
            let lastCorrectDate = vocab.lastCorrectDate
            
            // 3. Today's date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.string(from: Date())
            let today = formatter.date(from: todayString)!
            
            // 4. Apply SM-2 algorithm
            if isCorrect {
                timesCorrect += 1
                
                // Check if this is a new day for correct answer
                if let lastDate = lastCorrectDate {
                    let lastDateOnly = formatter.string(from: lastDate)
                    if lastDateOnly != todayString {
                        uniqueDaysCorrect += 1
                    }
                } else {
                    uniqueDaysCorrect += 1
                }
                
                // SM-2: Correct response
                if repetitions == 0 {
                    interval = 1
                } else if repetitions == 1 {
                    interval = 6
                } else {
                    interval = Int(Double(interval) * easeFactor)
                }
                repetitions += 1
                
                // Ease factor adjustment (quality = 4 for correct)
                let quality = 4.0
                let qualityDiff = 5.0 - quality
                let adjustment = 0.1 - qualityDiff * (0.08 + qualityDiff * 0.02)
                easeFactor = easeFactor + adjustment
                
            } else {
                timesIncorrect += 1
                
                // SM-2: Incorrect response - reset
                repetitions = 0
                interval = 1
                
                // Ease factor adjustment (quality = 2 for incorrect)
                let quality = 2.0
                let qualityDiff = 5.0 - quality
                let adjustment = 0.1 - qualityDiff * (0.08 + qualityDiff * 0.02)
                easeFactor = easeFactor + adjustment
            }
            
            // 5. Ease factor floor
            easeFactor = max(1.3, easeFactor)
            
            // 6. Calculate next review date
            let nextReview = Calendar.current.date(byAdding: .day, value: interval, to: today)!
            let nextReviewString = formatter.string(from: nextReview)
            
            // 7. Determine status
            var status = "learning"
            if uniqueDaysCorrect >= 5 {
                status = "mastered"
            }
            
            // 8. Build update payload
            var updates: [String: AnyJSON] = [
                "ease_factor": .double(easeFactor),
                "interval_days": .integer(interval),
                "repetitions": .integer(repetitions),
                "next_review_date": .string(nextReviewString),
                "times_correct": .integer(timesCorrect),
                "times_incorrect": .integer(timesIncorrect),
                "unique_days_correct": .integer(uniqueDaysCorrect),
                "status": .string(status),
                "last_reviewed_at": .string(ISO8601DateFormatter().string(from: Date()))
            ]
            
            if isCorrect {
                updates["last_correct_date"] = .string(todayString)
            }
            
            // 9. Update database
            try await supabase
                .from("user_vocabulary")
                .update(updates)
                .eq("id", value: userVocabId.uuidString)
                .execute()
            
            print("✅ VocabularyService: Review updated - Next: \(nextReviewString), Status: \(status)")
            
        } catch {
            print("❌ VocabularyService Update Review Error: \(error)")
        }
    }
    
    private func categoryIcon(_ name: String) -> String {
        switch name.lowercased() {
        case "greetings": return "hand.wave"
        case "food": return "fork.knife"
        case "family": return "person.3"
        case "numbers": return "number"
        case "colors": return "paintpalette"
        case "travel": return "airplane"
        case "politeness": return "heart"
        default: return "book"
        }
    }
}

// Helper struct for categories
struct VocabularyCategory: Identifiable {
    let id: String  // Changed from UUID() to String (category name as ID)
    let name: String
    let nameFr: String
    let wordCount: Int
    let learnedCount: Int
    let masteredCount: Int
    let iconName: String
    
    var masteryPercentage: Double {
        wordCount > 0 ? Double(masteredCount) / Double(wordCount) * 100 : 0
    }
}


// MARK: - Conversation Service
@MainActor
class ConversationService {
    
    // MARK: - Published Data (for AppDataManager to sync)
    var scenarios: [ConversationScenario] = []
    var recentConversations: [Conversation] = []
    
    // MARK: - Insert/Update Structs
    private struct NewConversation: Codable {
        let user_id: String
        let scenario_id: String
        let status: String
        let message_count: Int
        let corrections_count: Int
    }
    
    private struct ConversationUpdate: Codable {
        var status: String?
        var completed_at: String?
        var message_count: Int?
        var corrections_count: Int?
        var vocabulary_practiced: [String]?
    }
    
    private struct NewMessage: Codable {
        let conversation_id: String
        let role: String
        let content: String
        let correction: String?
        let vocabulary_used: [String]?
        let is_goal_complete: Bool
        let sort_order: Int
    }
    
    // MARK: - Fetch Scenarios
    func fetchScenarios() async {
        do {
            let response: [ConversationScenario] = try await supabase
                .from("conversation_scenarios")
                .select()
                .eq("is_active", value: true)
                .order("sort_order", ascending: true)
                .execute()
                .value
            
            self.scenarios = response
            print("✅ Fetched \(response.count) scenarios")
        } catch {
            print("❌ Fetch scenarios error: \(error)")
        }
    }
    
    // MARK: - Fetch Recent Conversations
    func fetchRecentConversations(profileId: UUID) async {
        do {
            let response: [Conversation] = try await supabase
                .from("conversations")
                .select()
                .eq("user_id", value: profileId.uuidString)
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value
            
            self.recentConversations = response
            print("✅ Fetched \(response.count) recent conversations")
        } catch {
            print("❌ Fetch recent conversations error: \(error)")
        }
    }
    
    // MARK: - Create Conversation
    func createConversation(userId: String, scenarioId: UUID) async throws -> Conversation {
        let newConversation = NewConversation(
            user_id: userId,
            scenario_id: scenarioId.uuidString,
            status: "active",
            message_count: 0,
            corrections_count: 0
        )
        
        let response: Conversation = try await supabase
            .from("conversations")
            .insert(newConversation)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Update Conversation
    func updateConversation(
        conversationId: UUID,
        status: ConversationStatus? = nil,
        messageCount: Int? = nil,
        correctionsCount: Int? = nil,
        vocabularyPracticed: [String]? = nil
    ) async throws {
        var update = ConversationUpdate()
        
        if let status = status {
            update.status = status.rawValue
            if status == .completed {
                update.completed_at = ISO8601DateFormatter().string(from: Date())
            }
        }
        update.message_count = messageCount
        update.corrections_count = correctionsCount
        update.vocabulary_practiced = vocabularyPracticed
        
        try await supabase
            .from("conversations")
            .update(update)
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
    
    // MARK: - Save Message
    func saveMessage(
        conversationId: UUID,
        role: MessageRole,
        content: String,
        correction: String? = nil,
        vocabularyUsed: [String]? = nil,
        isGoalComplete: Bool = false,
        sortOrder: Int
    ) async throws -> ConversationMessage {
        let newMessage = NewMessage(
            conversation_id: conversationId.uuidString,
            role: role.rawValue,
            content: content,
            correction: correction,
            vocabulary_used: vocabularyUsed,
            is_goal_complete: isGoalComplete,
            sort_order: sortOrder
        )
        
        let response: ConversationMessage = try await supabase
            .from("conversation_messages")
            .insert(newMessage)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Fetch Messages for Conversation
    func fetchMessages(conversationId: UUID) async throws -> [ConversationMessage] {
        let response: [ConversationMessage] = try await supabase
            .from("conversation_messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("sort_order", ascending: true)
            .execute()
            .value
        
        return response
    }
}

// MARK: - Grammar Service
@MainActor
class GrammarService: ObservableObject {
    @Published var topics: [GrammarTopic] = []
    
    // MARK: - Fetch Grammar Topics
    func fetchTopics(levelCode: String, profileId: UUID) async {
        print("📝 GrammarService: Fetching grammar topics...")
        
        do {
            let response: [GrammarTopic] = try await supabase
                .from("grammar_topics")
                .select()
                .eq("is_published", value: true)
                .order("sort_order")
                .execute()
                .value
            
            print("✅ GrammarService: Fetched \(response.count) topics")
            
            // Fetch user progress
            if !response.isEmpty {
                let topicIds = response.map { $0.id.uuidString }
                let progress: [UserGrammarProgress] = try await supabase
                    .from("user_grammar_progress")
                    .select()
                    .eq("profile_id", value: profileId.uuidString)
                    .in("grammar_topic_id", values: topicIds)
                    .execute()
                    .value
                
                // Merge progress
                var topicsWithProgress = response
                for i in 0..<topicsWithProgress.count {
                    topicsWithProgress[i].progress = progress.first { $0.grammarTopicId == topicsWithProgress[i].id }
                }
                
                self.topics = topicsWithProgress
            } else {
                self.topics = response
            }
            
        } catch {
            print("❌ GrammarService Topics Error: \(error)")
        }
    }
    
    // MARK: - Fetch Grammar Topics with User Progress
    func fetchGrammarTopicsWithProgress(profileId: UUID) async -> [GrammarTopicWithProgress] {
        print("📖 GrammarService: Fetching grammar topics with progress...")
        
        do {
            // 1. Get all grammar topics
            let topics: [GrammarTopic] = try await supabase
                .from("grammar_topics")
                .select()
                .eq("is_published", value: true)
                .order("sort_order")
                .execute()
                .value
            
            // 2. Get user's grammar progress
            let userProgress: [UserGrammarProgress] = try await supabase
                .from("user_grammar_progress")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .execute()
                .value
            
            // 3. Create lookup dictionary
            var progressDict: [UUID: UserGrammarProgress] = [:]
            for progress in userProgress {
                progressDict[progress.grammarTopicId] = progress
            }
            
            // 4. Combine topics with progress
            let topicsWithProgress = topics.map { topic in
                let progress = progressDict[topic.id]
                return GrammarTopicWithProgress(
                    id: topic.id,
                    title: topic.title,
                    titleFr: topic.titleFr,
                    description: topic.description ?? "",
                    explanation: topic.explanation ?? "",
                    sortOrder: topic.sortOrder,
                    masteryPercentage: progress?.masteryPercentage ?? 0,
                    uniqueDaysCorrect: progress?.uniqueDaysCorrect ?? 0,
                    exercisesCompleted: progress?.exercisesCompleted ?? 0,
                    lastPracticedAt: progress?.lastPracticedAt
                )
            }
            
            print("✅ GrammarService: Found \(topicsWithProgress.count) topics")
            return topicsWithProgress
            
        } catch {
            print("❌ GrammarService Topics with Progress Error: \(error)")
            return []
        }
    }

    // MARK: - Fetch Grammar Exercises for Topic
    func fetchGrammarExercises(topicId: UUID, difficulty: ClosedRange<Int>? = nil, limit: Int = 10) async -> [GrammarExercise] {
        print("📖 GrammarService: Fetching exercises for topic...")
        
        do {
            var query = supabase
                .from("grammar_exercises")
                .select()
                .eq("grammar_topic_id", value: topicId.uuidString)
                .eq("is_active", value: true)
            
            if let diff = difficulty {
                query = query
                    .gte("difficulty", value: diff.lowerBound)
                    .lte("difficulty", value: diff.upperBound)
            }
            
            let exercises: [GrammarExercise] = try await query
                .limit(limit)
                .execute()
                .value
            
            print("✅ GrammarService: Found \(exercises.count) exercises")
            return exercises
            
        } catch {
            print("❌ GrammarService Exercises Error: \(error)")
            return []
        }
    }

    // MARK: - Update Grammar Progress
    func updateGrammarProgress(profileId: UUID, topicId: UUID, isCorrect: Bool) async {
        print("📖 GrammarService: Updating grammar progress...")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        
        do {
            // 1. Check if progress record exists
            let existing: [UserGrammarProgress] = try await supabase
                .from("user_grammar_progress")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .eq("grammar_topic_id", value: topicId.uuidString)
                .execute()
                .value
            
            if var progress = existing.first {
                // 2a. Update existing progress
                var uniqueDaysCorrect = progress.uniqueDaysCorrect ?? 0
                let lastCorrectDate = progress.lastCorrectDate
                
                if isCorrect {
                    // Check if new day
                    if let lastDate = lastCorrectDate {
                        let lastDateString = formatter.string(from: lastDate)
                        if lastDateString != todayString {
                            uniqueDaysCorrect += 1
                        }
                    } else {
                        uniqueDaysCorrect += 1
                    }
                }
                
                // Calculate mastery percentage (5 unique days = 100%)
                let masteryPercentage = min(Double(uniqueDaysCorrect) / 5.0 * 100, 100)
                
                var updates: [String: AnyJSON] = [
                    "exercises_completed": .integer(progress.exercisesCompleted + 1),
                    "mastery_percentage": .double(masteryPercentage),
                    "unique_days_correct": .integer(uniqueDaysCorrect),
                    "last_practiced_at": .string(ISO8601DateFormatter().string(from: Date()))
                ]
                
                if isCorrect {
                    updates["last_correct_date"] = .string(todayString)
                }
                
                try await supabase
                    .from("user_grammar_progress")
                    .update(updates)
                    .eq("id", value: progress.id.uuidString)
                    .execute()
                
                print("✅ GrammarService: Progress updated")
                
            } else {
                // 2b. Create new progress record
                let newProgress: [String: AnyJSON] = [
                    "profile_id": .string(profileId.uuidString),
                    "grammar_topic_id": .string(topicId.uuidString),
                    "mastery_percentage": .double(isCorrect ? 20 : 0),
                    "exercises_completed": .integer(1),
                    "unique_days_correct": .integer(isCorrect ? 1 : 0),
                    "last_correct_date": isCorrect ? .string(todayString) : .null,
                    "last_practiced_at": .string(ISO8601DateFormatter().string(from: Date()))
                ]
                
                try await supabase
                    .from("user_grammar_progress")
                    .insert(newProgress)
                    .execute()
                
                print("✅ GrammarService: Progress created")
            }
            
        } catch {
            print("❌ GrammarService Update Progress Error: \(error)")
        }
    }
}
