//
//  MainTabView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-11-27.
//

import SwiftUI

// MARK: - Tab Enum
enum FrencoTab: String, CaseIterable {
    case path = "Path"
    case chat = "Chat"
    case dojo = "Dojo"
    case soul = "Soul"
    
    var icon: String {
        switch self {
        case .path: return "map"
        case .chat: return "bubble.left.and.bubble.right"
        case .dojo: return "book"
        case .soul: return "sparkles"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .path: return "map.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .dojo: return "book.fill"
        case .soul: return "sparkles"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appData: AppDataManager
    @State private var selectedTab: FrencoTab = .path
    @Namespace private var tabAnimation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color.paper
                .ignoresSafeArea()
            
            // Content
            TabContent(selectedTab: selectedTab)
            
            // Custom Tab Bar
            FrencoTabBar(selectedTab: $selectedTab, namespace: tabAnimation)
        }
    }
}

// MARK: - Tab Content
struct TabContent: View {
    let selectedTab: FrencoTab
    
    var body: some View {
        Group {
            switch selectedTab {
            case .path:
                PathView()
            case .chat:
                ChatView()
            case .dojo:
                DojoView()
            case .soul:
                SoulView()
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeOut(duration: 0.3), value: selectedTab)
    }
}

// MARK: - Custom Tab Bar
struct FrencoTabBar: View {
    @Binding var selectedTab: FrencoTab
    var namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(FrencoTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.ink.opacity(0.08), radius: 20, x: 0, y: -5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.stone.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, FrencoDesign.horizontalPadding)
        .padding(.bottom, 8)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let tab: FrencoTab
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(isSelected ? .matcha : .wood)
                
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .matcha : .wood)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Color.matchaLight)
                            .matchedGeometryEffect(id: "tabBackground", in: namespace)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AppDataManager())
}
