//
//  UserView.swift
//  fifth
//
//  Created by Norbert on 08/11/2025.
//

import SwiftUI

struct UserView: View {
    @State private var username = "Norbert"
    @State private var level = 4
    @State private var exp: Double = 350
    @State private var expNeeded: Double = 500
    @State private var rank = "Explorer"
    @State private var achievements = 12
    @State private var streakDays = 5
    
    private var expProgress: Double {
        exp / expNeeded
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.green.opacity(0.6), .blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - User Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.white)
                            .shadow(radius: 5)
                        
                        Text(username)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Level \(level) • \(rank)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 50)
                    
                    // MARK: - EXP Bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Experience")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ProgressView(value: expProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .clipShape(Capsule())
                        
                        Text("\(Int(exp)) / \(Int(expNeeded)) XP")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                   
                    
                    // MARK: - Actions
                    VStack(spacing: 16) {
                        Button(action: {
                            // TODO: Add edit logic
                        }) {
                            Label("Edit Profile", systemImage: "pencil")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                        
                        Button(role: .destructive, action: {
                            // TODO: Add logout logic
                        }) {
                            Label("Log Out", systemImage: "arrow.backward.circle.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 60)
                }
            }
        }
    }
}

#Preview {
    UserView()
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
