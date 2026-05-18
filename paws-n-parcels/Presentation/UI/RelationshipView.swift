//
//  RelationshipView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 15/05/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Main View
struct RelationshipView: View {
    @State private var characters: [Animal] = []
    @State private var relationships: [AnimalRelationship] = []
    
    @State private var selectedIndex: Int = 0

    var body: some View {
        ZStack {
            // 1. Background Board Asset
            Image("buat menu")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)

            if !characters.isEmpty {
                let currentCharacter = characters[selectedIndex]

                // 2. The Content Layer
                VStack(spacing: 15) {
                    // Header: Selected Animal's Name
                    Text(currentCharacter.name)
                        .font(
                            .system(size: 24, weight: .bold, design: .rounded)
                        )
                        .padding(.top, 45)

                    Image(currentCharacter.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)

                    Spacer().frame(height: 10)

                    // 3. The Relationship Rows
                    VStack(spacing: 12) {
                        // Show every character EXCEPT the currently selected one
                        let otherCharacters = characters.filter {
                            $0.name != currentCharacter.name
                        }

                        ForEach(otherCharacters, id: \.name) { other in
                            if let rel = relationships.first(where: {
                                $0.involves(currentCharacter.name, and: other.name)
                            }) {
                                RelationshipRow(
                                    characterName: other.name,
                                    iconName: other.assetName,
                                    level: rel.friendshipLevel,
                                    points: rel.friendshipPoint
                                )
                            } else {
                                // Fallback row if no relationship data exists yet
                                RelationshipRow(
                                    characterName: other.name,
                                    iconName: other.assetName,
                                    level: 0,
                                    points: 0
                                )
                            }
                        }
                    }
                    Spacer()
                }
                .frame(width: 380, height: 500)
                
                // 4. Tab Buttons (The side switchers)
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ForEach(0..<characters.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    selectedIndex = index
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            selectedIndex == index
                                            ? Color.white.opacity(0.7)
                                            : Color.white
                                        )

                                    Text(
                                        String(characters[index].name.prefix(1))
                                    )
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                }
                                .frame(width: 38, height: 70)
                            }
                        }
                    }
                    .padding(.trailing, 15)
                }
                .frame(width: 400, height: 500)
                .offset(x:30)
            } else {
                Text("No characters found.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            self.characters = GameDataManager.shared.fetchAnimals().sorted { $0.name < $1.name }
            self.relationships = GameDataManager.shared.fetchRelationships()
        }
    }
}

// MARK: - Reusable Row View
struct RelationshipRow: View {
    let characterName: String
    let iconName: String
    let level: Int
    let points: Int

    private var statusText: String {
        switch level {
        case 0: return "Strangers"
        case 1...2: return "Acquaintance"
        case 3...4: return "Good Friend"
        case 5: return "Besties"
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 25) {
            // 1. Character Icon Slot
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))  // Light background tile for the icon

                Image(iconName)  // Uses "rabbit", "cat", etc. from your Animal model
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            }
            .frame(width: 40, height: 40)  // Square icon boundary

            // heart progress Bar & Character Name
            VStack(alignment: .leading, spacing: 2) {
                Text(characterName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        if index <= level {
                            // filled
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.system(size: 12))
                        } else {
                            // empty state
                            Image(systemName: "heart")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 12))
                        }
                    }
                }
                
                Text(statusText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(height: 60)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Animal.self, AnimalRelationship.self, Collectible.self, Request.self, PlayerProfile.self, configurations: config)
    let context = container.mainContext
    
    GameDataManager.shared.setup(with: context)
    SeederDatabase.seedDatabaseIfNeeded(context: context)
    
    return RelationshipView()
        .modelContainer(container)
}
