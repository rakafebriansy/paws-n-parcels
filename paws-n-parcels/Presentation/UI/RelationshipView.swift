//
//  RelationshipView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 15/05/26.
//

import Foundation
import SwiftData
import SwiftUI

struct RelationshipView: View {
    @State private var characters: [Animal] = []
    @State private var relationships: [AnimalRelationship] = []
    
    @State private var selectedIndex: Int = 0
    var onClose: (() -> Void)? = nil

    var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                Image("buat menu")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 400)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if onClose != nil {
                    Button(action: {
                        onClose?()
                    }) {
                        Image("back_button")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    }
                    .padding(.top, 40)
                    .padding(.leading, 45)
                }
            }

            if !characters.isEmpty {
                let currentCharacter = characters[selectedIndex]

                VStack(spacing: 12) {
                    Text(currentCharacter.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.darkGray)
                        .padding(.top, 40)

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cream.opacity(0.75))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        
                        Image(currentCharacter.assetName)
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                    }
                    .frame(width: 90, height: 90)

                    Spacer().frame(height: 8)

                    VStack(spacing: 10) {
                        let otherCharacters = characters.filter {
                            $0.name != currentCharacter.name
                        }

                        ForEach(otherCharacters, id: \.name) { other in
                            let rel = relationships.first(where: {
                                $0.involves(currentCharacter.name, and: other.name)
                            })
                            RelationshipRow(
                                characterName: other.name,
                                iconName: other.assetName,
                                level: rel?.friendshipLevel ?? 0,
                                points: rel?.friendshipPoint ?? 0
                            )
                        }
                    }
                    Spacer()
                }
                .frame(width: 360, height: 480)
                
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        ForEach(0..<characters.count, id: \.self) { index in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedIndex = index
                                }
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            selectedIndex == index
                                            ? Color.orange
                                            : Color.cream
                                        )
                                        .shadow(color: Color.black.opacity(0.12), radius: 3, x: 2, y: 1)

                                    Text(String(characters[index].name.prefix(1)))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedIndex == index ? .cream : .darkGray)
                                }
                                .frame(width: 32, height: 60)
                                .offset(x: selectedIndex == index ? 4 : 0)
                            }
                        }
                    }
                    .padding(.trailing, 10)
                }
                .frame(width: 400, height: 480)
                .offset(x: 28)
            } else {
                Text("No characters found.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
            }

        }
        .scaleEffect(0.85)
        .onAppear {
            self.characters = GameDataManager.shared.fetchAnimals().sorted { $0.name < $1.name }
            self.relationships = GameDataManager.shared.fetchRelationships()
        }
    }
}

struct RelationshipRow: View {
    let characterName: String
    let iconName: String
    let level: Int
    let points: Int

    private var statusText: String {
        let friendshipLevel = FriendshipLevel.getLevel(from: points)
        switch friendshipLevel {
        case .stranger: return "Strangers"
        case .acquaintance: return "Acquaintance"
        case .friend: return "Good Friend"
        case .closeFriend: return "Close Friend"
        case .bestFriend: return "Besties"
        }
    }

    private func getFillAmount(forIndex index: Int, points: Int) -> Double {
        let t1 = GameConfig.pointsForAcquaintance
        let t2 = GameConfig.pointsForFriend
        let t3 = GameConfig.pointsForCloseFriend
        let t4 = GameConfig.pointsForBestFriend
        let t5 = t4 + 500
        
        switch index {
        case 1:
            if points <= 0 { return 0.0 }
            if points >= t1 { return 1.0 }
            return Double(points) / Double(t1)
            
        case 2:
            if points <= t1 { return 0.0 }
            if points >= t2 { return 1.0 }
            return Double(points - t1) / Double(t2 - t1)
            
        case 3:
            if points <= t2 { return 0.0 }
            if points >= t3 { return 1.0 }
            return Double(points - t2) / Double(t3 - t2)
            
        case 4:
            if points <= t3 { return 0.0 }
            if points >= t4 { return 1.0 }
            return Double(points - t3) / Double(t4 - t3)
            
        case 5:
            if points <= t4 { return 0.0 }
            if points >= t5 { return 1.0 }
            return Double(points - t4) / Double(t5 - t4)
            
        default:
            return 0.0
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.12)) 

                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(characterName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.darkGray)
                
                Text(statusText)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.darkGray.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { index in
                    FractionalHeartView(fillAmount: getFillAmount(forIndex: index, points: points))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.cream.opacity(0.65))
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 20)
    }
}

struct FractionalHeartView: View {
    let fillAmount: Double

    var body: some View {
        ZStack(alignment: .leading) {
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.darkGray.opacity(0.12))
            
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.pink)
                .mask(
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geometry.size.width * CGFloat(fillAmount))
                            Spacer(minLength: 0)
                        }
                    }
                )
            
            Image(systemName: "heart")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.darkGray)
        }
        .frame(width: 15, height: 13)
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
