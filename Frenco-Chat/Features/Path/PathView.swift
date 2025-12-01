//
//  PathView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI
import Clerk

struct PathView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var appData: AppDataManager
    @State private var selectedLesson: Lesson?
    @State private var showingLesson = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: FrencoDesign.verticalSpacing) {
                // Header
                HeaderSection(
                    userName: appData.displayName,
                    streak: appData.currentStreak
                )
                
                // Daily Lesson Card - Shows CURRENT (next incomplete) lesson
                if let currentLesson = appData.currentLesson {
                    DailyLessonCard(
                        lesson: currentLesson,
                        progress: appData.dailyProgress,
                        onContinue: {
                            selectedLesson = currentLesson
                            showingLesson = true
                        }
                    )
                }
                
                // Journey Path - Shows ALL lessons
                JourneySection(
                    lessons: appData.allLessonsFlat,
                    currentLessonId: appData.currentLesson?.id,
                    onLessonTap: { lesson in
                        selectedLesson = lesson
                        showingLesson = true
                    }
                )
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .background(Color.paper.ignoresSafeArea())
        .refreshable {
            await appData.refreshData()
        }
        .fullScreenCover(item: $selectedLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(appData)
        }
    }
}

// MARK: - Header Section (unchanged)
struct HeaderSection: View {
    let userName: String
    let streak: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(userName)")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .italic()
                        .foregroundColor(.ink)
                    
                    Text("DAY \(max(streak, 1)) OF YOUR JOURNEY")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .tracking(2)
                        .foregroundColor(.wood)
                }
                
                Spacer()
                
                FrencoStreakDisplay(days: streak)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Daily Lesson Card (unchanged)
struct DailyLessonCard: View {
    let lesson: Lesson
    let progress: Double
    let onContinue: () -> Void
    
    var body: some View {
        FrencoCard {
            VStack(alignment: .leading, spacing: 16) {
                // Status badge
                if lesson.progress?.status == .completed {
                    Text("REVIEW")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.matcha)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.matchaLight)
                        .clipShape(Capsule())
                } else if lesson.progress?.status == .inProgress {
                    Text("IN PROGRESS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundColor(.sakura)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.sakuraLight)
                        .clipShape(Capsule())
                }
                
                // Lesson Title
                Text(lesson.titleFr)
                    .font(.system(size: 24, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(.ink)
                
                Text("\(lesson.title.uppercased())")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(.wood)
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Today's Progress")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.matcha)
                    }
                    
                    FrencoProgressBar(progress: progress)
                }
                
                // Time & XP
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.wood)
                    Text("~\(lesson.estimatedMinutes) minutes")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.wood)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.sakura)
                        Text("+\(lesson.xpReward) XP")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.sakura)
                    }
                }
                
                // CTA Button
                FrencoPrimaryButton(title: lesson.progress?.status == .completed ? "Review" : "Continue") {
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Journey Section (FIXED - shows all lessons)
struct JourneySection: View {
    let lessons: [Lesson]
    let currentLessonId: UUID?
    let onLessonTap: (Lesson) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR PATH")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .tracking(2)
                .foregroundColor(.wood)
            
            if lessons.isEmpty {
                FrencoCard {
                    HStack {
                        ProgressView()
                            .tint(.matcha)
                        Text("Loading lessons...")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        LessonNode(
                            lesson: lesson,
                            isCurrent: lesson.id == currentLessonId,
                            isCompleted: lesson.progress?.status == .completed,
                            isFirst: index == 0,
                            isLast: index == lessons.count - 1,
                            onTap: {
                                onLessonTap(lesson)
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Lesson Node
struct LessonNode: View {
    let lesson: Lesson
    let isCurrent: Bool
    let isCompleted: Bool
    let isFirst: Bool
    let isLast: Bool
    let onTap: () -> Void
    
    private var isLocked: Bool {
        !isCurrent && !isCompleted
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Node and Line
            VStack(spacing: 0) {
                // Top line
                if !isFirst {
                    Rectangle()
                        .fill(isCompleted || isCurrent ? Color.matcha : Color.clay.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                // Node circle
                ZStack {
                    Circle()
                        .fill(nodeBackgroundColor)
                        .frame(width: 44, height: 44)
                    
                    if isCurrent {
                        Circle()
                            .stroke(Color.matcha, lineWidth: 2)
                            .frame(width: 52, height: 52)
                    }
                    
                    nodeIcon
                }
                
                // Bottom line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.matcha : Color.clay.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.titleFr)
                    .font(.system(size: 16, weight: isCurrent ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isLocked ? .clay : .ink)
                
                Text(lesson.title)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                
                HStack(spacing: 8) {
                    Text("\(lesson.estimatedMinutes) min")
                    Text("•")
                    Text("\(lesson.xpReward) XP")
                    
                    if isCompleted {
                        Text("•")
                        Text("✓ Done")
                            .foregroundColor(.matcha)
                    }
                }
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundColor(.clay)
            }
            .padding(.top, isFirst ? 8 : 28)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isLocked {
                onTap()
            }
        }
        .opacity(isLocked ? 0.6 : 1.0)
    }
    
    private var nodeBackgroundColor: Color {
        if isCompleted { return .matcha }
        if isCurrent { return .matchaLight }
        return .stone.opacity(0.3)
    }
    
    @ViewBuilder
    private var nodeIcon: some View {
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        } else if isCurrent {
            Image(systemName: "play.fill")
                .font(.system(size: 14))
                .foregroundColor(.matcha)
        } else {
            Image(systemName: "lock")
                .font(.system(size: 14))
                .foregroundColor(.clay)
        }
    }
}

#Preview {
    PathView()
        .environmentObject(AppDataManager())
}
