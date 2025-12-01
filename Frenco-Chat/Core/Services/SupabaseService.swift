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
            var categoryDict: [String: (total: Int, learned: Int)] = [:]
            for word in vocab {
                let cat = word.category ?? "Other"
                let current = categoryDict[cat] ?? (0, 0)
                let isLearned = userVocab.contains { $0.vocabularyId == word.id && $0.status != .new }
                categoryDict[cat] = (current.total + 1, current.learned + (isLearned ? 1 : 0))
            }
            
            // Convert to array
            self.categories = categoryDict.map { key, value in
                VocabularyCategory(
                    name: key.capitalized,
                    nameFr: key.capitalized,
                    wordCount: value.total,
                    learnedCount: value.learned,
                    iconName: categoryIcon(key)
                )
            }.sorted { $0.name < $1.name }
            
            print("✅ VocabularyService: Created \(categories.count) categories")
            
        } catch {
            print("❌ VocabularyService Categories Error: \(error)")
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
    let id = UUID()
    let name: String
    let nameFr: String
    let wordCount: Int
    let learnedCount: Int
    let iconName: String
    
    var masteryPercentage: Double {
        wordCount > 0 ? Double(learnedCount) / Double(wordCount) : 0
    }
}

// MARK: - Conversation Service
@MainActor
class ConversationService: ObservableObject {
    @Published var scenarios: [ConversationScenario] = []
    @Published var recentConversations: [UserConversation] = []
    
    // MARK: - Fetch Scenarios
    func fetchScenarios() async {
        print("💬 ConversationService: Fetching scenarios...")
        
        do {
            let response: [ConversationScenario] = try await supabase
                .from("conversation_scenarios")
                .select()
                .eq("is_published", value: true)
                .order("difficulty")
                .execute()
                .value
            
            self.scenarios = response
            print("✅ ConversationService: Fetched \(response.count) scenarios")
        } catch {
            print("❌ ConversationService Scenarios Error: \(error)")
        }
    }
    
    // MARK: - Fetch Recent Conversations
    func fetchRecentConversations(profileId: UUID, limit: Int = 10) async {
        print("💬 ConversationService: Fetching recent conversations...")
        
        do {
            let conversations: [UserConversation] = try await supabase
                .from("user_conversations")
                .select()
                .eq("profile_id", value: profileId.uuidString)
                .order("started_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            self.recentConversations = conversations
            print("✅ ConversationService: Fetched \(conversations.count) conversations")
        } catch {
            print("❌ ConversationService Recent Error: \(error)")
        }
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
}
