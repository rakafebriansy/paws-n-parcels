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


    var relationships: [AnimalFriendRelationship] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func update(deltaTime: TimeInterval) {
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
    }
    
    func initialBurstSpawn() {
        let activeCount = allHouses.filter {
            $0.component(ofType: RequestComponent.self) != nil
        }.count
        
        let needed = GameConfig.maxRequests - activeCount
        if needed > 0 {
            print("Starting burst spawn for \(needed) initial package")
            for _ in 0..<needed {
                generateAndSpawnRequest()
            }
        }
    }
    
    func generateAndSpawnRequest() {
        let eligibleHouses = allHouses.filter {
            house in
            guard let name = house.characterName else {
                return false
            }
            let hasComponent = house.component(ofType: RequestComponent.self) != nil
            return !hasComponent && !reservedHouseNames.contains(name)
        }

        guard let senderHouse = eligibleHouses.randomElement(),
            let senderName = senderHouse.characterName
        else {
            return
        }

        let validRelationships = relationships.filter {
            rel in
            let f1 = allFriends.first(where: { $0.id == rel.friendOneId })
            let f2 = allFriends.first(where: { $0.id == rel.friendTwoId })
            return f1?.name == senderName || f2?.name == senderName
        }

        guard let chosenRel = validRelationships.randomElement() else {
            reservedHouseNames.remove(senderName)
            return
        }

        let f1Name = allFriends.first(where: { $0.id == chosenRel.friendOneId })?.name ?? ""
        let f2Name = allFriends.first(where: { $0.id == chosenRel.friendTwoId })?.name ?? ""
        
        let recipientName = (f1Name == senderName) ? f2Name : f1Name
        let friendshipLevel = chosenRel.friendshipLevel
        
        Task {
            if let letterData = await AIService.shared.generateSingleLetter(from: senderName, to: recipientName, level: friendshipLevel) {
                _ = await MainActor.run {
                    guard let senderObj = allFriends.first(where: {
                        $0.name == senderName
                    }),
                          let receiverObj = allFriends.first(where: {
                              $0.name == recipientName
                          }) else {
                        reservedHouseNames.remove(senderName)
                        return
                    }
        
                    let newRequest = Request(senderId: senderObj.id, receiverId: receiverObj.id, letter: letterData)
                    let component = RequestComponent(requestData: newRequest)

                    senderHouse.addComponent(component)
                    system.addComponent(component)
                    
                    reservedHouseNames.remove(senderName)

                    self.refreshID = UUID()
                    self.objectWillChange.send()

                    print(
                        "Generated a Level \(friendshipLevel) letter from \(senderName) to \(recipientName)!"
                    )
                }
            } else {
                _ = await MainActor.run {
                    reservedHouseNames.remove(senderName)
                }
            }
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
