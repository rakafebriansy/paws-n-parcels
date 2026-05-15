//
//  RequestSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import Combine
import GameplayKit
import SwiftData
import SwiftUI

@MainActor
class RequestSystem: ObservableObject {
    @Published var refreshID = UUID()

    @Published var completedRequestToShow: Request?
    let system = GKComponentSystem(
        componentClass: RequestComponent.self
    )
    var currentActiveRequest: Request?
    var allFriends: [AnimalFriend] = []
    var modelContext: ModelContext
    var spawnTimer: TimeInterval = 10.0
    var allHouses: [HouseEntity] = []
    
    private var reservedHouseNames: Set<String> = []
    
    /// Buffer for components that need to be added to the GKComponentSystem.
    /// We queue them here and flush synchronously at the start of update()
    /// to avoid mutating the system while SpriteKit is iterating it.
    private var pendingComponents: [(house: HouseEntity, component: RequestComponent)] = []

    var relationships: [AnimalFriendRelationship] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Flush any pending component additions. Must be called from a safe
    /// synchronous context (i.e. NOT while iterating the system).
    private func flushPendingComponents() {
        guard !pendingComponents.isEmpty else { return }
        let batch = pendingComponents
        pendingComponents.removeAll()
        
        for entry in batch {
            entry.house.addComponent(entry.component)
            system.addComponent(entry.component)
            print("[DEBUG] flushPendingComponents: Attached component to \(entry.house.characterName ?? "?")")
        }
        
        self.refreshID = UUID()
        self.objectWillChange.send()
    }
    
    func update(deltaTime: TimeInterval) {
        // Safely install any components that were queued by async Tasks
        flushPendingComponents()
        
        let activeCount = allHouses.filter {
            $0.component(ofType: RequestComponent.self) != nil
        }.count

        if activeCount < GameConfig.maxRequests {
            spawnTimer -= deltaTime
            if spawnTimer <= 0 {
                generateAndSpawnRequest()
                spawnTimer = 10.0
            }
        }
    }
    
    func pickupRequest(from house: HouseEntity) -> Request? {
        if let component = house.component(ofType: RequestComponent.self) {
            let request = component.requestData
            
            house.removeComponent(ofType: RequestComponent.self)
            system.removeComponent(component)
            
            self.refreshID = UUID()
            self.objectWillChange.send()
            
            return request
        }
        return nil
    }
    
    func deliverRequest(_ request: Request) {
        request.isCompleted = true
        try? modelContext.save()
        
        self.refreshID = UUID()
        self.objectWillChange.send()
    }
    
    func removePackageFromHouse(_ house: HouseEntity) -> Request? {
        if let component = house.component(ofType: RequestComponent.self) {
            let request = component.requestData
            
            house.removeComponent(ofType: RequestComponent.self)
            system.removeComponent(component)
            
            self.refreshID = UUID()
            self.objectWillChange.send()
            return request
        }
        return nil
    }
    
    func triggerNewPackageSpawn() {
        spawnTimer = 0.0
    }
    
    func fetchRelationships() {
        let relDescriptor = FetchDescriptor<AnimalFriendRelationship>()
        self.relationships = (try? modelContext.fetch(relDescriptor)) ?? []
        
        let friendDescriptor = FetchDescriptor<AnimalFriend>()
        self.allFriends = (try? modelContext.fetch(friendDescriptor)) ?? []
        
        print("[DEBUG] fetchRelationships: \(allFriends.count) friends, \(relationships.count) relationships")
        for f in allFriends {
            print("  Friend: \(f.name) (\(f.id))")
        }
    }
    
    func initialBurstSpawn() {
        let activeCount = allHouses.filter {
            $0.component(ofType: RequestComponent.self) != nil
        }.count
        
        let needed = max(0, GameConfig.maxRequests - activeCount)
        guard needed > 0 else { return }
        
        print("[DEBUG] initialBurstSpawn: Starting burst spawn for \(needed) initial packages (sequential)")
        
        // Spawn sequentially using an async Task chain so that each AI call
        // completes and its component is queued before the next one starts.
        // This prevents multiple concurrent mutations to GKComponentSystem.
        Task {
            for i in 0..<needed {
                print("[DEBUG] initialBurstSpawn: Spawning package \(i+1)/\(needed)")
                await generateAndSpawnRequestAsync()
            }
            print("[DEBUG] initialBurstSpawn: All \(needed) packages spawned.")
        }
    }
    
    /// Async version of generateAndSpawnRequest that awaits the AI letter
    /// generation and queues the component, rather than firing a detached Task.
    private func generateAndSpawnRequestAsync() async {
        let eligibleHouses = allHouses.filter { house in
            guard let name = house.characterName else { return false }
            let hasComponent = house.component(ofType: RequestComponent.self) != nil
            let hasPending = pendingComponents.contains(where: { $0.house === house })
            return !hasComponent && !hasPending && !reservedHouseNames.contains(name)
        }

        guard let senderHouse = eligibleHouses.randomElement(),
              let senderName = senderHouse.characterName
        else {
            print("[DEBUG] generateAndSpawnRequestAsync: No eligible houses! Total houses: \(allHouses.count), with names: \(allHouses.compactMap { $0.characterName })")
            return
        }

        let validRelationships = relationships.filter { rel in
            let f1 = allFriends.first(where: { $0.id == rel.friendOneId })
            let f2 = allFriends.first(where: { $0.id == rel.friendTwoId })
            return f1?.name == senderName || f2?.name == senderName
        }

        guard let chosenRel = validRelationships.randomElement() else {
            print("[DEBUG] generateAndSpawnRequestAsync: No valid relationships for \(senderName)!")
            return
        }

        reservedHouseNames.insert(senderName)

        let f1Name = allFriends.first(where: { $0.id == chosenRel.friendOneId })?.name ?? ""
        let f2Name = allFriends.first(where: { $0.id == chosenRel.friendTwoId })?.name ?? ""
        let recipientName = (f1Name == senderName) ? f2Name : f1Name
        let friendshipLevel = chosenRel.friendshipLevel

        print("[DEBUG] generateAndSpawnRequestAsync: Requesting letter from \(senderName) to \(recipientName) (level \(friendshipLevel))")

        if let letterData = await AIService.shared.generateSingleLetter(from: senderName, to: recipientName, level: friendshipLevel) {
            guard let senderObj = allFriends.first(where: { $0.name == senderName }),
                  let receiverObj = allFriends.first(where: { $0.name == recipientName }) else {
                reservedHouseNames.remove(senderName)
                return
            }

            let newRequest = Request(senderId: senderObj.id, receiverId: receiverObj.id, letter: letterData)
            let component = RequestComponent(requestData: newRequest)

            // Queue component addition instead of directly mutating the system
            pendingComponents.append((house: senderHouse, component: component))
            reservedHouseNames.remove(senderName)

            print("Queued Level \(friendshipLevel) letter from \(senderName) to \(recipientName)")
        } else {
            reservedHouseNames.remove(senderName)
        }
    }
    
    /// Fire-and-forget version for the periodic timer-based spawning.
    func generateAndSpawnRequest() {
        Task {
            await generateAndSpawnRequestAsync()
        }
    }

    func syncToDatabase() {
        let deleteDescriptor = FetchDescriptor<Request>()
        let oldRequests = (try? modelContext.fetch(deleteDescriptor)) ?? []

        for oldRequest in oldRequests {
            modelContext.delete(oldRequest)
        }

        for house in allHouses {
            if let component = house.component(ofType: RequestComponent.self) {
                let requestToSave = component.requestData
                requestToSave.isCompleted = false
                modelContext.insert(requestToSave)
            }
        }

        try? modelContext.save()
        print("Sync complete.")
    }
    
    func loadFromDatabase() {
        let descriptor = FetchDescriptor<Request>(
            predicate: #Predicate { $0.isCompleted == false }
        )
        let savedRequests = (try? modelContext.fetch(descriptor)) ?? []

        for request in savedRequests {
            let senderName = allFriends.first(where: { $0.id == request.senderId })?.name ?? ""

            if let targetHouse = allHouses.first(where: {
                $0.characterName == senderName
            }) {
                let component = RequestComponent(requestData: request)
                targetHouse.addComponent(component)

                system.addComponent(component)
            }
        }
        print("Restored \(savedRequests.count) active requests.")
    }
}

