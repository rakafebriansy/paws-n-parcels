//
//  RelationshipSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 15/05/26.
//

import Foundation
import SwiftData

// MARK: - Relationship Logic System
@MainActor
class RelationshipSystem {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Finds the existing relationship between two characters.
    /// Logic: Checks both ID slots so the order of IDs doesn't matter.
    func getRelationship(between idA: UUID, and idB: UUID) -> AnimalFriendRelationship? {
        let descriptor = FetchDescriptor<AnimalFriendRelationship>(
            predicate: #Predicate<AnimalFriendRelationship> { rel in
                (rel.friendOneId == idA && rel.friendTwoId == idB) ||
                (rel.friendOneId == idB && rel.friendTwoId == idA)
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
}
