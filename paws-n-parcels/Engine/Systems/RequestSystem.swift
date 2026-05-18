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
    let system = GKComponentSystem(componentClass: RequestComponent.self)
    
    var houses: [HouseEntity] = []
    var relationships: [AnimalRelationship] = []
    
    private var animalsMap: [String: Animal] = [:]
    private var reservedHouseNamesToSpawn: Set<String> = []
    
    private var activeRequestsCount: Int {
        houses.count(where: { $0.component(ofType: RequestComponent.self) != nil })
    }
    
    init() { }
    
    func triggerNewPackageSpawn(delaySeconds: Int = 0) {
        scheduleNextPackageSpawn(delaySeconds: delaySeconds)
    }
    
    func deliverRequest(_ request: Request) {
        request.isCompleted = true
        GameDataManager.shared.save()
        
        scheduleNextPackageSpawn(delaySeconds: 10)
    }
    
    func pickupRequest(_ house: HouseEntity) -> Request? {
        guard let component = house.component(ofType: RequestComponent.self)
        else { return nil }
                
        let request = component.request
        house.removeComponent(ofType: RequestComponent.self)
        system.removeComponent(component)
        
        return request
    }
    
    func fetchData() {
        self.relationships = GameDataManager.shared.fetchRelationships()
        
        let fetchedAnimals = GameDataManager.shared.fetchAnimals()
        self.animalsMap = fetchedAnimals.reduce(into: [:]) {
            dict, animal in
            dict[animal.name] = animal
        }
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
        guard let senderHouse = getRandomEligibleHouse(),
              let senderName = senderHouse.characterName,
              let chosenRel = getRandomRelationship(for: senderName),
              let recipientName = chosenRel.partner(of: senderName)
        else { return }
        
        guard let senderAnimal = animalsMap[senderName],
              let receiverAnimal = animalsMap[recipientName]
        else {
            print("[RequestSystem] Failed to find Animal objects for \(senderName) or \(recipientName)")
            return
        }
        
        reservedHouseNamesToSpawn.insert(senderName)
        defer { reservedHouseNamesToSpawn.remove(senderName) }
        
        if let letterData = await AIService.shared.generateSingleLetter(from: senderName, to: recipientName, level: chosenRel.friendshipLevel) {
            let newRequest = Request(sender: senderAnimal, receiver: receiverAnimal, letter: letterData)
            let component = RequestComponent(request: newRequest)
            
            senderHouse.addComponent(component)
            system.addComponent(component)
        }
    }
    
    private func scheduleNextPackageSpawn(delaySeconds: Int) {
        let activeCount = houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count
        
        guard activeCount < GameConfig.maxRequests
        else { return }
        
        Task {
            if delaySeconds > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
            }
            await generateAndSpawnRequestAsync()
        }
    }
    
    private func getRandomEligibleHouse() -> HouseEntity? {
        let eligibleHouses = houses.filter {
            house in
            
            guard let name = house.characterName
            else {
                return false
            }
            
            let isHoldingRequest = house.component(ofType: RequestComponent.self) != nil
            
            return !isHoldingRequest && !reservedHouseNamesToSpawn.contains(name)
        }
        return eligibleHouses.randomElement()
    }
    
    private func getRandomRelationship(for characterName: String) -> AnimalRelationship? {
        let validRelationships = relationships.filter {
            $0.friendOne.name == characterName || $0.friendTwo.name == characterName
        }
        return validRelationships.randomElement()
    }
}
