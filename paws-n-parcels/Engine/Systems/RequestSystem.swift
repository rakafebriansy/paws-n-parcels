//
//  RequestSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import GameplayKit
import SwiftData

@MainActor
class RequestSystem {
    let system = GKComponentSystem(
        componentClass: RequestComponent.self
    )
    
    var houses: [HouseEntity] = []
    var modelContext: ModelContext
    var relationships: [AnimalRelationship] = []

    private var reservedHouseNamesToSpawn: Set<String> = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func triggerNewPackageSpawn() {
        scheduleNextPackageSpawn(delaySeconds: 0)
    }
    
    func deliverRequest(_ request: Request) {
        request.isCompleted = true
        try? modelContext.save()
        
        scheduleNextPackageSpawn(delaySeconds: 10)
    }
    
    func pickupRequest(_ house: HouseEntity) -> Request? {
        if let component = house.component(ofType: RequestComponent.self) {
            let request = component.request
            
            house.removeComponent(ofType: RequestComponent.self)
            system.removeComponent(component)
            
            return request
        }
        return nil
    }
    
    func fetchRelationships() {
        let relDescriptor = FetchDescriptor<AnimalRelationship>()
        self.relationships = (try? modelContext.fetch(relDescriptor)) ?? []
    }
    
    func initialBurstSpawn() {
        let activeCount = houses.lazy.filter { $0.component(ofType: RequestComponent.self) != nil }.count
        let needed = max(0, GameConfig.maxRequests - activeCount)
        
        guard needed > 0 else { return }
        
        Task {
            for _ in 0..<needed {
                await generateAndSpawnRequestAsync()
            }
        }
    }
    
    private func generateAndSpawnRequestAsync() async {
        let eligibleHouses = houses.filter { house in
            guard let name = house.characterName else { return false }
            let hasComponent = house.component(ofType: RequestComponent.self) != nil
            return !hasComponent && !reservedHouseNamesToSpawn.contains(name)
        }

        guard let senderHouse = eligibleHouses.randomElement(),
              let senderName = senderHouse.characterName else { return }

        let validRelationships = relationships.filter { rel in
            return rel.friendOneName == senderName || rel.friendTwoName == senderName
        }

        guard let chosenRel = validRelationships.randomElement() else { return }

        reservedHouseNamesToSpawn.insert(senderName)
        
        defer {
            reservedHouseNamesToSpawn.remove(senderName)
        }

        let recipientName = (chosenRel.friendOneName == senderName) ? chosenRel.friendTwoName : chosenRel.friendOneName
        let friendshipLevel = chosenRel.friendshipLevel

        if let letterData = await AIService.shared.generateSingleLetter(from: senderName, to: recipientName, level: friendshipLevel) {
            let newRequest = Request(senderName: senderName, receiverName: recipientName, letter: letterData)
            let component = RequestComponent(request: newRequest)

            senderHouse.addComponent(component)
            system.addComponent(component)
        }
    }
    
    private func scheduleNextPackageSpawn(delaySeconds: Int) {
        let activeCount = houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count
        guard activeCount < GameConfig.maxRequests else { return }
        
        Task {
            if delaySeconds > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
            }
            await generateAndSpawnRequestAsync()
        }
    }

//    func syncToDatabase() {
//        let deleteDescriptor = FetchDescriptor<Request>()
//        let oldRequests = (try? modelContext.fetch(deleteDescriptor)) ?? []
//
//        for oldRequest in oldRequests {
//            modelContext.delete(oldRequest)
//        }
//
//        for house in houses {
//            if let component = house.component(ofType: RequestComponent.self) {
//                let requestToSave = component.request
//                requestToSave.isCompleted = false
//                modelContext.insert(requestToSave)
//            }
//        }
//
//        try? modelContext.save()
//        print("Sync complete.")
//    }
//    
//    func loadFromDatabase() {
//        let descriptor = FetchDescriptor<Request>(
//            predicate: #Predicate { $0.isCompleted == false }
//        )
//        let savedRequests = (try? modelContext.fetch(descriptor)) ?? []
//
//        for request in savedRequests {
//            let senderName = friends.first(where: { $0.id == request.senderId })?.name ?? ""
//
//            if let targetHouse = houses.first(where: {
//                $0.characterName == senderName
//            }) {
//                let component = RequestComponent(request: request)
//                targetHouse.addComponent(component)
//
//                system.addComponent(component)
//            }
//        }
//        print("Restored \(savedRequests.count) active requests.")
//    }
}

