//
//  AboutView.swift
//  Frenco-Chat
//
//  Created by Shakeb . on 2025-12-07.
//

import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // App Icon & Name
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.matchaLight)
                            .frame(width: 100, height: 100)
                        
                        Text("言")
                            .font(.system(size: 48, weight: .light, design: .serif))
                            .foregroundColor(.matcha)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Frenco")
                            .font(.system(size: 28, weight: .light, design: .serif))
                            .italic()
                            .foregroundColor(.ink)
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.wood)
                    }
                }
                .padding(.top, 24)
                
                // Tagline
                Text("Learn French with purpose and calm")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
                    .multilineTextAlignment(.center)
                
                // Info Card
                VStack(spacing: 0) {
                    AboutRow(
                        icon: "heart.fill",
                        title: "Made with love",
                        subtitle: "by Shakeb"
                    )
                    
                    Divider().padding(.leading, 48)
                    
                    AboutRow(
                        icon: "leaf.fill",
                        title: "Design Philosophy",
                        subtitle: "Ikigai — purposeful learning"
                    )
                    
                    Divider().padding(.leading, 48)
                    
                    AboutRow(
                        icon: "envelope.fill",
                        title: "Feedback",
                        subtitle: "We'd love to hear from you"
                    )
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.wood.opacity(0.1), lineWidth: 1)
                )
                
                // Footer
                VStack(spacing: 8) {
                    Text("© 2025 Frenco")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.clay)
                    
                    Text("All rights reserved")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.clay.opacity(0.7))
                }
                .padding(.top, 16)
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, FrencoDesign.horizontalPadding)
        }
        .background(Color.paper.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About Row
struct AboutRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.matcha)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.ink)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.wood)
            }
            
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
