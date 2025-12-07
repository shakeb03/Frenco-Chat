//
//  SoulView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct SoulView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    
    // Settings sheets
    @State private var showLearningPreferences = false
    @State private var showNotifications = false
    @State private var showVoiceSettings = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: FrencoDesign.verticalSpacing) {
                    // Profile Header
                    ProfileHeader()
                    
                    // Stats Cards
                    StatsSection()
                    
                    // Learning Progress Overview
                    LearningProgressSection()
                    
                    // Achievements
                    AchievementsSection()
                    
                    // Weekly Progress
                    WeeklyProgressSection()
                    
                    // Settings
                    SettingsSection(
                        showLearningPreferences: $showLearningPreferences,
                        showNotifications: $showNotifications,
                        showVoiceSettings: $showVoiceSettings,
                        showAbout: $showAbout
                    )
                    
                    // App Version
                    AppVersionFooter()
                    
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, FrencoDesign.horizontalPadding)
            }
            .background(Color.paper.ignoresSafeArea())
            .refreshable {
                await appData.refreshData()
            }
            .sheet(isPresented: $showLearningPreferences) {
                LearningPreferencesSheet()
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsSheet()
            }
            .sheet(isPresented: $showVoiceSettings) {
                VoiceSettingsSheet()
            }
            .sheet(isPresented: $showAbout) {
                AboutSheet()
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeader: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    
    private var levelDisplay: String {
        let level = appData.currentLevel
        let title: String
        switch level {
        case "A1": title = "Beginner"
        case "A2": title = "Elementary"
        case "B1": title = "Intermediate"
        case "B2": title = "Upper Intermediate"
        case "C1": title = "Advanced"
        case "C2": title = "Mastery"
        default: title = "Explorer"
        }
        return "LEVEL \(level) · \(title.uppercased())"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .stroke(Color.sakura, lineWidth: 3)
                    .frame(width: 96, height: 96)
                
                Circle()
                    .fill(Color.sakuraLight)
                    .frame(width: 88, height: 88)
                
                Text(appData.initials)
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .foregroundColor(.sakura)
            }
            
            // Name and Level
            VStack(spacing: 6) {
                Text(appData.displayName)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.ink)
                
                Text(levelDisplay)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
            }
            
            // Total XP Badge
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.sakura)
                
                Text("\(appData.totalXp) XP")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.sakura)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.sakuraLight)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}

// MARK: - Stats Section
struct StatsSection: View {
    @EnvironmentObject var appData: AppDataManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(appData.currentStreak)",
                    label: "Streak",
                    color: .matcha
                )
                
                StatCard(
                    icon: "book.fill",
                    value: "\(appData.totalWordsLearned)",
                    label: "Words",
                    color: .sakura
                )
                
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(appData.totalLessonsCompleted)",
                    label: "Lessons",
                    color: .wood
                )
                
                StatCard(
                    icon: "clock.fill",
                    value: appData.formatMinutes(appData.totalMinutesPracticed),
                    label: "Time",
                    color: .matcha
                )
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(1)
                .foregroundColor(.wood)
                .textCase(.uppercase)
        }
        .frame(width: 80)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.wood.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Learning Progress Section
struct LearningProgressSection: View {
    @EnvironmentObject var appData: AppDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("LEARNING PROGRESS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            FrencoCard {
                VStack(spacing: 16) {
                    // Vocabulary Progress
                    ProgressRow(
                        icon: "text.book.closed.fill",
                        title: "Vocabulary",
                        subtitle: "\(appData.totalWordsLearned) words learned",
                        progress: min(Double(appData.totalWordsLearned) / 500.0, 1.0),
                        color: .matcha
                    )
                    
                    Divider()
                    
                    // Grammar Progress
                    ProgressRow(
                        icon: "pencil.and.outline",
                        title: "Grammar",
                        subtitle: "\(appData.grammarTopics.count) topics available",
                        progress: 0.3, // Placeholder - calculate from user_grammar_progress
                        color: .sakura
                    )
                    
                    Divider()
                    
                    // Conversations
                    ProgressRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Conversations",
                        subtitle: "\(appData.totalConversations) completed",
                        progress: min(Double(appData.totalConversations) / 50.0, 1.0),
                        color: .wood
                    )
                }
            }
        }
    }
}

struct ProgressRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.ink)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(color)
                }
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.clay.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
            }
        }
    }
}

// MARK: - Achievements Section
struct AchievementsSection: View {
    @EnvironmentObject var appData: AppDataManager
    
    private var achievements: [Achievement] {
        [
            Achievement(
                icon: "flame.fill",
                title: "First Flame",
                description: "Complete your first lesson",
                isUnlocked: appData.totalLessonsCompleted >= 1,
                color: .matcha
            ),
            Achievement(
                icon: "star.fill",
                title: "Week Warrior",
                description: "7 day streak",
                isUnlocked: appData.currentStreak >= 7,
                color: .sakura
            ),
            Achievement(
                icon: "book.fill",
                title: "Word Collector",
                description: "Learn 50 words",
                isUnlocked: appData.totalWordsLearned >= 50,
                color: .wood
            ),
            Achievement(
                icon: "trophy.fill",
                title: "Century Club",
                description: "Earn 100 XP",
                isUnlocked: appData.totalXp >= 100,
                color: .matcha
            ),
            Achievement(
                icon: "moon.stars.fill",
                title: "Night Owl",
                description: "30 day streak",
                isUnlocked: appData.currentStreak >= 30,
                color: .sakura
            ),
            Achievement(
                icon: "graduationcap.fill",
                title: "Scholar",
                description: "Complete 10 lessons",
                isUnlocked: appData.totalLessonsCompleted >= 10,
                color: .wood
            )
        ]
    }
    
    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
                
                Spacer()
                
                Text("\(unlockedCount)/\(achievements.count)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.matcha)
            }
            
            // Achievement Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    let color: Color
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.15) : Color.clay.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .clay.opacity(0.4))
                
                // Lock overlay
                if !achievement.isUnlocked {
                    Circle()
                        .fill(Color.paper.opacity(0.6))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.clay)
                }
            }
            
            Text(achievement.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(achievement.isUnlocked ? .ink : .clay)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(achievement.isUnlocked ? achievement.color.opacity(0.3) : Color.clay.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Weekly Progress Section
struct WeeklyProgressSection: View {
    @EnvironmentObject var appData: AppDataManager
    
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    private var weekData: [CGFloat] {
        let calendar = Calendar.current
        let today = Date()
        let maxMinutes = max(appData.weeklyActivity.map { $0.minutesPracticed }.max() ?? 1, 1)
        
        var data: [CGFloat] = []
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                data.append(0)
                continue
            }
            
            let dayStart = calendar.startOfDay(for: date)
            if let activity = appData.weeklyActivity.first(where: {
                calendar.isDate($0.activityDate, inSameDayAs: dayStart)
            }) {
                data.append(CGFloat(activity.minutesPracticed) / CGFloat(maxMinutes))
            } else {
                data.append(0)
            }
        }
        return data
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            FrencoCard {
                VStack(spacing: 20) {
                    // Bar Chart
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.matcha, Color.matcha.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 28, height: max(weekData[index] * 80, 4))
                                
                                Text(days[index])
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.wood)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Summary
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appData.formatMinutes(appData.weeklyMinutesTotal))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.ink)
                            
                            Text("total time this week")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.wood)
                        }
                        
                        Spacer()
                        
                        let weeklyXp = appData.weeklyActivity.reduce(0) { $0 + $1.xpEarned }
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.sakura)
                            
                            Text("+\(weeklyXp) XP")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.sakura)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.sakuraLight)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection: View {
    @Environment(\.clerk) private var clerk
    @Binding var showLearningPreferences: Bool
    @Binding var showNotifications: Bool
    @Binding var showVoiceSettings: Bool
    @Binding var showAbout: Bool
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SETTINGS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            FrencoCard {
                VStack(spacing: 0) {
//                    Button {
//                        showLearningPreferences = true
//                    } label: {
//                        SettingsRow(icon: "gearshape", title: "Learning Preferences")
//                    }
//                    
//                    Divider().padding(.leading, 48)
//                    
//                    Button {
//                        showLearningPreferences = true
//                    } label: {
//                        SettingsRow(icon: "bell", title: "Notifications")
//                    }
                    
//                    Divider().padding(.leading, 48)
                    
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRow(icon: "info.circle", title: "About Frenco")
                    }
                    
                    Divider().padding(.leading, 48)
                    
                    // Sign Out
                    Button {
                        showSignOutConfirmation = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.clay)
                                .frame(width: 24)
                            
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.wood)
                            
                            Spacer()
                        }
                        .padding(.vertical, 14)
                    }
                }
            }
        }
        .confirmationDialog(
            "Sign Out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await clerk.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your progress.")
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.wood)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.ink)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.clay)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - App Version Footer
struct AppVersionFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Frenco")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.clay)
            
            Text("Version 1.0.0")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.clay.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
}

// MARK: - Settings Sheets

struct LearningPreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dailyGoal") private var dailyGoal: Int = 10
    @AppStorage("difficultyLevel") private var difficultyLevel: String = "adaptive"
    
    var body: some View {
        NavigationView {
            List {
                Section("Daily Goal") {
                    Picker("Minutes per day", selection: $dailyGoal) {
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                        Text("15 minutes").tag(15)
                        Text("20 minutes").tag(20)
                        Text("30 minutes").tag(30)
                    }
                }
                
                Section("Difficulty") {
                    Picker("Level", selection: $difficultyLevel) {
                        Text("Easy").tag("easy")
                        Text("Adaptive").tag("adaptive")
                        Text("Challenging").tag("hard")
                    }
                }
            }
            .navigationTitle("Learning Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = true
    @AppStorage("reminderHour") private var reminderHour: Int = 9
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Daily Reminder", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Picker("Reminder Time", selection: $reminderHour) {
                            ForEach(6..<23) { hour in
                                Text("\(hour):00").tag(hour)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Streak Alerts", isOn: .constant(true))
                    Toggle("Achievement Alerts", isOn: .constant(true))
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct VoiceSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("audioSpeed") private var audioSpeed: Double = 1.0
    @AppStorage("autoPlayAudio") private var autoPlayAudio: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Playback") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Audio Speed: \(String(format: "%.1fx", audioSpeed))")
                        Slider(value: $audioSpeed, in: 0.5...1.5, step: 0.1)
                    }
                    .padding(.vertical, 4)
                    
                    Toggle("Auto-play Audio", isOn: $autoPlayAudio)
                }
                
                Section(footer: Text("Audio files are played from our servers. Ensure you have an internet connection.")) {
                    HStack {
                        Text("Audio Quality")
                        Spacer()
                        Text("High")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Voice & Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.matchaLight)
                                    .frame(width: 80, height: 80)
                                
                                Text("文")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundColor(.matcha)
                            }
                            
                            Text("Frenco")
                                .font(.system(size: 24, weight: .light, design: .serif))
                                .italic()
                            
                            Text("Learn French, Naturally")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                }
                
                Section {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                }
                
                Section {
                    Link(destination: URL(string: "https://frenco.app/privacy")!) {
                        Text("Privacy Policy")
                    }
                    Link(destination: URL(string: "https://frenco.app/terms")!) {
                        Text("Terms of Service")
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Text("Made with ❤️ for language learners")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SoulView()
        .environment(\.clerk, Clerk.shared)
        .environmentObject(AppDataManager())
}
