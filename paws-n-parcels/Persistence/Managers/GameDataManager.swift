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
}
