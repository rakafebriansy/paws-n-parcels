//
//  GameDataManager.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 17/05/26.
//

import Foundation
import SwiftData

class GameDataManager {
    static let shared = GameDataManager()
    
    var context: ModelContext?
    
    func setup(with context: ModelContext) {
        self.context = context
        print("[GameDataManager] Context initialized.")
    }
    
    func save() {
        do {
            try context?.save()
            print("[GameDataManager] Database saved successfully.")
        } catch {
            print("[GameDataManager] Failed to save database: \(error.localizedDescription)")
        }
    }
    
    func fetchRelationships() -> [AnimalRelationship] {
        let descriptor = FetchDescriptor<AnimalRelationship>()
        return (try? context?.fetch(descriptor)) ?? []
    }
        
    func fetchAnimals() -> [Animal] {
        let descriptor = FetchDescriptor<Animal>()
        return (try? context?.fetch(descriptor)) ?? []
    }
    
    func fetchCollectibles() -> [Collectible] {
        let descriptor = FetchDescriptor<Collectible>()
        return (try? context?.fetch(descriptor)) ?? []
    }
    
    // MARK: - Player Profile
    
    func fetchPlayerProfile() -> PlayerProfile? {
        let descriptor = FetchDescriptor<PlayerProfile>()
        return (try? context?.fetch(descriptor))?.first
    }
    
    func savePlayerPosition(x: Double, y: Double) {
        if let profile = fetchPlayerProfile() {
            profile.positionX = x
            profile.positionY = y
        } else {
            let profile = PlayerProfile(positionX: x, positionY: y)
            context?.insert(profile)
        }
        save()
        print("[GameDataManager] Player position saved: (\(x), \(y))")
    }
    
    // MARK: - Pending Requests
    
    /// Fetch requests that are at houses (not picked up, not completed)
    func fetchPendingRequests() -> [Request] {
        let descriptor = FetchDescriptor<Request>(predicate: #Predicate<Request> { !$0.isCompleted && !$0.isPickedUp })
        return (try? context?.fetch(descriptor)) ?? []
    }
    
    /// Fetch the request currently being carried by the player
    func fetchPickedUpRequests() -> [Request] {
        let descriptor = FetchDescriptor<Request>(predicate: #Predicate<Request> { $0.isPickedUp && !$0.isCompleted })
        return (try? context?.fetch(descriptor)) ?? []
    }
    
    /// Delete all non-completed requests (for reset)
    func deleteAllPendingRequests() {
        let allPending = fetchPendingRequests() + fetchPickedUpRequests()
        for request in allPending {
            context?.delete(request)
        }
        save()
        print("[GameDataManager] Deleted \(allPending.count) pending requests.")
    }
    
    func saveActiveRequests(senderNames: [String]) {
        // Save the list of active sender house names so we can restore which houses had requests
        UserDefaults.standard.set(senderNames, forKey: "activeRequestSenderNames")
        print("[GameDataManager] Saved \(senderNames.count) active request sender names.")
    }
    
    func loadActiveRequestSenderNames() -> [String] {
        return UserDefaults.standard.stringArray(forKey: "activeRequestSenderNames") ?? []
    }
    
    // MARK: - Full Game State Save
    
    func saveGameState(playerX: Double, playerY: Double, activeRequestSenderNames: [String]) {
        savePlayerPosition(x: playerX, y: playerY)
        saveActiveRequests(senderNames: activeRequestSenderNames)
        print("[GameDataManager] Full game state saved.")
    }
}
