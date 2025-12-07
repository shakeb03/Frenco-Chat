//
//  OnboardingView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI
import Combine

struct OnboardingView: View {
    @EnvironmentObject var appData: AppDataManager
    
    @State private var currentPage = 0
    @State private var selectedGoal: Int = 10
    @State private var selectedLevel: String = "A1"
    @State private var selectedMotivation: String? = nil
    @State private var isCompleting = false
    
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            // Background
            Color.paper.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                ProgressDots(current: currentPage, total: totalPages)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    GoalPage(selectedGoal: $selectedGoal)
                        .tag(1)
                    
                    LevelPage(selectedLevel: $selectedLevel)
                        .tag(2)
                    
                    MotivationPage(selectedMotivation: $selectedMotivation)
                        .tag(3)
                    
                    ReadyPage()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Navigation button
                Button(action: handleNext) {
                    HStack {
                        if isCompleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentPage == totalPages - 1 ? "Commencer" : "Continuer")
                                .font(.custom("ZenMaruGothic-Medium", size: 18))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.matcha)
                    .cornerRadius(16)
                }
                .disabled(isCompleting)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func handleNext() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        isCompleting = true
        Task {
            await appData.profileService.completeOnboarding(
                dailyGoalMinutes: selectedGoal,
                currentLevel: selectedLevel,
                learningMotivation: selectedMotivation
            )
            // Force AppDataManager to notify views
            await MainActor.run {
                appData.onboardingCompleted = true
            }
            
            isCompleting = false
        }
    }
}

// MARK: - Progress Dots
struct ProgressDots: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color.matcha : Color.clay.opacity(0.3))
                    .frame(width: index == current ? 10 : 8, height: index == current ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}

// MARK: - Page 1: Welcome
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "leaf.fill")
                .font(.system(size: 80))
                .foregroundColor(.matcha)
            
            Text("Bienvenue")
                .font(.custom("CormorantGaramond-SemiBold", size: 40))
                .foregroundColor(.wood)
            
            Text("Your journey to French fluency\nstarts here")
                .font(.custom("ZenMaruGothic-Regular", size: 18))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Page 2: Goal Selection
struct GoalPage: View {
    @Binding var selectedGoal: Int
    
    private let goals = [
        (minutes: 5, label: "5 min", description: "Casual"),
        (minutes: 10, label: "10 min", description: "Regular"),
        (minutes: 15, label: "15 min", description: "Committed"),
        (minutes: 20, label: "20 min", description: "Intensive")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Daily Goal")
                .font(.custom("CormorantGaramond-SemiBold", size: 36))
                .foregroundColor(.wood)
            
            Text("How much time can you\npractice each day?")
                .font(.custom("ZenMaruGothic-Regular", size: 18))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                ForEach(goals, id: \.minutes) { goal in
                    GoalOptionRow(
                        minutes: goal.minutes,
                        label: goal.label,
                        description: goal.description,
                        isSelected: selectedGoal == goal.minutes
                    ) {
                        selectedGoal = goal.minutes
                    }
                }
            }
            .padding(.top, 16)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct GoalOptionRow: View {
    let minutes: Int
    let label: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.custom("ZenMaruGothic-Medium", size: 18))
                        .foregroundColor(.wood)
                    Text(description)
                        .font(.custom("ZenMaruGothic-Regular", size: 14))
                        .foregroundColor(.clay)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .matcha : .clay.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? Color.matchaLight : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.matcha : Color.clay.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Page 3: Level Selection
struct LevelPage: View {
    @Binding var selectedLevel: String
    
    private let levels = [
        (code: "A1", title: "Complete Beginner", description: "I'm just starting out"),
        (code: "A2", title: "Some Basics", description: "I know a few words & phrases")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Your Level")
                .font(.custom("CormorantGaramond-SemiBold", size: 36))
                .foregroundColor(.wood)
            
            Text("Have you studied French before?")
                .font(.custom("ZenMaruGothic-Regular", size: 18))
                .foregroundColor(.clay)
            
            VStack(spacing: 12) {
                ForEach(levels, id: \.code) { level in
                    LevelOptionRow(
                        code: level.code,
                        title: level.title,
                        description: level.description,
                        isSelected: selectedLevel == level.code
                    ) {
                        selectedLevel = level.code
                    }
                }
            }
            .padding(.top, 16)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct LevelOptionRow: View {
    let code: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(code)
                    .font(.custom("ZenMaruGothic-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.matcha : Color.clay.opacity(0.5))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.custom("ZenMaruGothic-Medium", size: 18))
                        .foregroundColor(.wood)
                    Text(description)
                        .font(.custom("ZenMaruGothic-Regular", size: 14))
                        .foregroundColor(.clay)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .matcha : .clay.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? Color.matchaLight : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.matcha : Color.clay.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Page 4: Motivation (Optional)
struct MotivationPage: View {
    @Binding var selectedMotivation: String?
    
    private let motivations = [
        (key: "travel", icon: "airplane", label: "Travel"),
        (key: "work", icon: "briefcase.fill", label: "Work"),
        (key: "culture", icon: "book.fill", label: "Culture"),
        (key: "family", icon: "heart.fill", label: "Family"),
        (key: "fun", icon: "sparkles", label: "Just for fun")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Why French?")
                .font(.custom("CormorantGaramond-SemiBold", size: 36))
                .foregroundColor(.wood)
            
            Text("What motivates you to learn?\n(Optional)")
                .font(.custom("ZenMaruGothic-Regular", size: 18))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(motivations, id: \.key) { motivation in
                    MotivationCard(
                        icon: motivation.icon,
                        label: motivation.label,
                        isSelected: selectedMotivation == motivation.key
                    ) {
                        if selectedMotivation == motivation.key {
                            selectedMotivation = nil
                        } else {
                            selectedMotivation = motivation.key
                        }
                    }
                }
            }
            .padding(.top, 16)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct MotivationCard: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .matcha : .clay)
                
                Text(label)
                    .font(.custom("ZenMaruGothic-Medium", size: 14))
                    .foregroundColor(isSelected ? .wood : .clay)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(isSelected ? Color.matchaLight : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.matcha : Color.clay.opacity(0.2), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Page 5: Ready
struct ReadyPage: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.matcha)
            
            Text("You're Ready!")
                .font(.custom("CormorantGaramond-SemiBold", size: 36))
                .foregroundColor(.wood)
            
            Text("Let's begin your French journey.\nOne step at a time.")
                .font(.custom("ZenMaruGothic-Regular", size: 18))
                .foregroundColor(.clay)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
        .environmentObject(AppDataManager())
}
