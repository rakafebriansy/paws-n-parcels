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
    
    deinit {
        print("[RequestSystem] DEALLOCATED! This should NOT happen during gameplay.")
    }
    
    func triggerNewPackageSpawn(delaySeconds: Int = 0) {
        scheduleNextPackageSpawn(delaySeconds: delaySeconds)
    }
    
    func deliverRequest(_ request: Request) {
        request.isCompleted = true
        GameDataManager.shared.context?.delete(request)
        GameDataManager.shared.save()
        
        scheduleNextPackageSpawn(delaySeconds: 10)
    }
    
    func pickupRequest(_ house: HouseEntity) -> Request? {
        guard let component = house.component(ofType: RequestComponent.self)
        else { return nil }
                
        let request = component.request
        request.isPickedUp = true
        GameDataManager.shared.save()
        
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
        let houseRequestCount = houses.lazy.filter { $0.component(ofType: RequestComponent.self) != nil }.count
        let pickedUpCount = GameDataManager.shared.fetchPickedUpRequests().count
        let totalActive = houseRequestCount + pickedUpCount
        let needed = max(0, GameConfig.maxRequests - totalActive)
        
        guard needed > 0 else { return }
        
        print("[RequestSystem] initialBurstSpawn: spawning \(needed) requests (active: \(totalActive), max: \(GameConfig.maxRequests))")
        
        Task {
            for i in 0..<needed {
                if i > 0 {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                }
                print("[RequestSystem] initialBurstSpawn: generating request \(i+1)/\(needed)")
                await generateAndSpawnRequestAsync()
            }
            print("[RequestSystem] initialBurstSpawn: COMPLETED all \(needed) requests")
        }
    }
    
    private func generateAndSpawnRequestAsync() async {
        guard let senderHouse = getRandomEligibleHouse(),
              let senderName = senderHouse.component(ofType: OwnerComponent.self)?.characterName,
              let chosenRel = getRandomRelationship(for: senderName),
              let recipientName = chosenRel.partner(of: senderName)
        else {
            print("[RequestSystem] generateAndSpawnRequestAsync: FAILED at guard (no eligible house or relationship)")
            return
        }
        
        guard let senderAnimal = animalsMap[senderName],
              let receiverAnimal = animalsMap[recipientName]
        else {
            print("[RequestSystem] Failed to find Animal objects for \(senderName) or \(recipientName)")
            return
        }
        
        reservedHouseNamesToSpawn.insert(senderName)
        defer { reservedHouseNamesToSpawn.remove(senderName) }
        
        print("[RequestSystem] Generating letter from \(senderName) to \(recipientName)...")
        if let letterData = await AIService.shared.generateSingleLetter(from: senderName, to: recipientName, level: chosenRel.friendshipLevel) {
            let newRequest = Request(sender: senderAnimal, receiver: receiverAnimal, letter: letterData)
            
            GameDataManager.shared.context?.insert(newRequest)
            GameDataManager.shared.save()
            
            let component = RequestComponent(request: newRequest)
            
            senderHouse.addComponent(component)
            system.addComponent(component)
            print("[RequestSystem] SUCCESS: Request created at \(senderName)'s house -> \(recipientName)")
        } else {
            print("[RequestSystem] FAILED: AI letter generation returned nil for \(senderName) -> \(recipientName)")
        }
    }
    
    private func scheduleNextPackageSpawn(delaySeconds: Int) {
        let houseRequestCount = houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count
        let pickedUpCount = GameDataManager.shared.fetchPickedUpRequests().count
        let totalActive = houseRequestCount + pickedUpCount
        
        guard totalActive < GameConfig.maxRequests
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
            
            guard let name = house.component(ofType: OwnerComponent.self)?.characterName
            else {
                return false
            }
            
            guard animalsMap[name] != nil else { return false }
            guard relationships.contains(where: { $0.friendOne.name == name || $0.friendTwo.name == name }) else { return false }
            
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
