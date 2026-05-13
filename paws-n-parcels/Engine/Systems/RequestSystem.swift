//
//  RequestSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import SwiftUI
import GameplayKit
import SwiftData
import Combine

class RequestSystem: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var refreshID = UUID() // Forces SwiftUI to redraw when entities change
    @Published var spawnTimer: TimeInterval = 10.0
    
    // Core Data
    var allHouses: [HouseEntity] = []
    var allFriends: [AnimalFriend] = []
    var relationships: [AnimalFriendRelationship] = []
    
    // GameplayKit
    let requestComponentSystem = GKComponentSystem(componentClass: RequestComponent.self)
    
    internal let maxRequests = 5
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchInitialData()
    }
    
    func fetchInitialData() {
        // Load Characters
        let friendDescriptor = FetchDescriptor<AnimalFriend>()
        self.allFriends = (try? modelContext.fetch(friendDescriptor)) ?? []
        
        // Load Relationships
        let relDescriptor = FetchDescriptor<AnimalFriendRelationship>()
        self.relationships = (try? modelContext.fetch(relDescriptor)) ?? []
        
        print("System Initialized: \(allFriends.count) friends, \(relationships.count) relationships.")
    }

    func update(deltaTime: TimeInterval) {
        let activeCount = requestComponentSystem.components.count
        if activeCount < maxRequests && !isGenerating {
            spawnTimer -= deltaTime
            if spawnTimer <= 0 {
                generateAndSpawnRequest()
                spawnTimer = 10.0
            }
        }
    }

    func generateAndSpawnRequest() {
        guard !isGenerating else { return }
        
        // 1. Filter for active houses without a request
        let eligibleHouses = allHouses.filter { house in
            guard house.characterName != nil else { return false }
            return house.component(ofType: RequestComponent.self) == nil
        }

        guard let senderHouse = eligibleHouses.randomElement(),
              let senderName = senderHouse.characterName else { return }

        // 2. Relationship Logic: Check both slots
        let validRels = relationships.filter {
            $0.friendOne?.name == senderName || $0.friendTwo?.name == senderName
        }
        
        guard let chosenRel = validRels.randomElement() else {
            print("No relationships found for \(senderName)")
            return
        }

        let recipientName = (chosenRel.friendOne?.name == senderName)
            ? chosenRel.friendTwo?.name
            : chosenRel.friendOne?.name

        guard let finalRecipientName = recipientName else { return }

        isGenerating = true
        
        Task {
            // Call AI Service
            if let letterData = await AIService.shared.generateSingleLetter(
                from: senderName,
                to: finalRecipientName,
                level: chosenRel.friendshipLevel
            ) {
                await MainActor.run {
                    // 3. The Bridge: Link to SwiftData Objects
                    guard let senderObj = allFriends.first(where: { $0.name == senderName }),
                          let receiverObj = allFriends.first(where: { $0.name == finalRecipientName }) else {
                        isGenerating = false
                        return
                    }

                    let newRequest = Request(sender: senderObj, receiver: receiverObj, letter: letterData)
                    let component = RequestComponent(requestData: newRequest)

                    // 4. Attach to Entity and System
                    senderHouse.addComponent(component)
                    requestComponentSystem.addComponent(component)

                    // 5. Trigger UI Refresh
                    self.refreshID = UUID()
                    self.objectWillChange.send()
                    
                    isGenerating = false
                    print("✅ Generated: \(senderName) to \(finalRecipientName)")
                }
            } else {
                await MainActor.run { isGenerating = false }
            }
        }
    }
    
    // MARK: - Persistence
    func syncToDatabase() {
        let deleteDescriptor = FetchDescriptor<Request>()
        let oldRequests = (try? modelContext.fetch(deleteDescriptor)) ?? []
        for req in oldRequests { modelContext.delete(req) }
        
        for house in allHouses {
            if let component = house.component(ofType: RequestComponent.self) {
                modelContext.insert(component.requestData)
            }
        }
        try? modelContext.save()
        print("💾 Database Synced")
    }
}
