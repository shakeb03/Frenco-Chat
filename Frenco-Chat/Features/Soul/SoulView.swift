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
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: FrencoDesign.verticalSpacing) {
                // Profile Header
                ProfileHeader()
                
                // Stats Cards
                StatsSection()
                
                // Weekly Progress
                WeeklyProgressSection()
                
                // Settings
                SettingsSection()
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .background(Color.paper.ignoresSafeArea())
        .refreshable {
            await appData.refreshData()
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
                    label: "Days",
                    color: .matcha
                )
                
                StatCard(
                    icon: "book.fill",
                    value: "\(appData.totalWordsLearned)",
                    label: "Words",
                    color: .sakura
                )
                
                StatCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    value: "\(appData.totalConversations)",
                    label: "Chats",
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

// MARK: - Weekly Progress Section
struct WeeklyProgressSection: View {
    @EnvironmentObject var appData: AppDataManager
    
    private let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    // Get data for each day of the week
    private var weekData: [CGFloat] {
        let calendar = Calendar.current
        let today = Date()
        
        // Find the most minutes in the week for scaling
        let maxMinutes = max(appData.weeklyActivity.map { $0.minutesPracticed }.max() ?? 1, 1)
        
        // Create array for last 7 days
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
        FrencoCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.wood)
                
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
                    
                    // XP earned this week
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

// MARK: - Settings Section
struct SettingsSection: View {
    @Environment(\.clerk) private var clerk
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SETTINGS")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            FrencoCard {
                VStack(spacing: 0) {
                    SettingsRow(icon: "gearshape", title: "Learning Preferences")
                    
                    Divider()
                        .padding(.leading, 48)
                    
                    SettingsRow(icon: "bell", title: "Notifications")
                    
                    Divider()
                        .padding(.leading, 48)
                    
                    SettingsRow(icon: "speaker.wave.2", title: "Voice & Audio")
                    
                    Divider()
                        .padding(.leading, 48)
                    
                    SettingsRow(icon: "info.circle", title: "About Frenco")
                    
                    Divider()
                        .padding(.leading, 48)
                    
                    // Sign Out Row - Subtle styling
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
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            action?()
        } label: {
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
        }
    }
}

// MARK: - Preview
#Preview {
    SoulView()
        .environment(\.clerk, Clerk.shared)
        .environmentObject(AppDataManager())
}
