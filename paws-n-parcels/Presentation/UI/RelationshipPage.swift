//
//  RelationshipPage.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 15/05/26.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Main View
struct RelationshipPage: View {
    @Environment(\.modelContext) private var modelContext

    // Fetches all characters from SwiftData
    @Query(sort: \AnimalFriend.name) var characters: [AnimalFriend]

    @State private var selectedIndex: Int = 0

    var body: some View {
        let system = RelationshipSystem(modelContext: modelContext)

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

                    // Profile Picture Placeholder
                    // You can replace this with Image(currentCharacter.assetName) later
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(currentCharacter.name.prefix(1))
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        )

                    Spacer().frame(height: 10)

                    // 3. The Relationship Rows
                    VStack(spacing: 12) {
                        // Show every character EXCEPT the currently selected one
                        let otherCharacters = characters.filter {
                            $0.id != currentCharacter.id
                        }

                        ForEach(otherCharacters) { other in
                            if let rel = system.getRelationship(
                                between: currentCharacter.id,
                                and: other.id
                            ) {
                                RelationshipRow(
                                    iconName: other.name,
                                    level: rel.friendshipLevel,
                                    points: rel.friendshipPoints
                                )
                            } else {
                                // Fallback row if no relationship data exists yet
                                RelationshipRow(
                                    iconName: other.name,
                                    level: 0,
                                    points: 0
                                )
                            }
                        }
                    }
                    Spacer()
                }
                .frame(width: 280, height: 500)
                .offset(x: -25)

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
                                                ? Color.white.opacity(0.3)
                                                : Color.clear
                                        )

                                    Text(
                                        String(characters[index].name.prefix(1))
                                    )
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                }
                                .frame(width: 45, height: 70)
                            }
                        }
                    }
                    .padding(.trailing, 15)
                }
                .frame(width: 400, height: 500)
            } else {
                Text("No characters found.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Reusable Row View
struct RelationshipRow: View {
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
        HStack(spacing: 16) {
            // 1. Character Icon Slot
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))  // Light background tile for the icon

                Image(iconName)  // Uses "rabbit", "cat", etc. from your AnimalFriend model
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            }
            .frame(width: 40, height: 40)  // Square icon boundary

            // heart progress Bar
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        if index <= level {
                            // filled
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                                .font(.system(size: 16))
                        } else {
                            // empty state
                            Image(systemName: "heart")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 16))
                        }

                        /* NOTE: When you get your pixel art assets, replace the system images above with:
                                                Image(index <= level ? "heart_filled_asset_name" : "heart_empty_asset_name")
                                                    .resizable()
                                                    .frame(width: 18, height: 16)
                                                */
                    }
                }
                Text(statusText)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(height: 40)
    }
}

#Preview {
    RelationshipPage()
}
