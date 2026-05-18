//
//  RelationshipSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 15/05/26.
//

import Foundation
import SwiftData

@MainActor
class RelationshipSystem {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getRelationship(between nameA: String, and nameB: String) -> AnimalRelationship? {
        let descriptor = FetchDescriptor<AnimalRelationship>(
            predicate: #Predicate<AnimalRelationship> { rel in
                (rel.friendOne.name == nameA && rel.friendTwo.name == nameB) ||
                (rel.friendOne.name == nameB && rel.friendTwo.name == nameA)
            }
        )
        
        return try? modelContext.fetch(descriptor).first
    }
}
