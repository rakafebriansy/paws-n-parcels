//
//  SeederDatabase.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 10/05/26.
//

import SwiftData
import Foundation

@MainActor
class SeederDatabase {
    static func clearDatabase(context: ModelContext) {
        do {
            try context.delete(model: Request.self)
            try context.delete(model: AnimalRelationship.self)
            try context.delete(model: Collectible.self)
            try context.delete(model: Animal.self)
            try context.save()
            debugLog("[SeederDatabase] Successfully reset and cleared the database.")
        } catch {
            debugLog("[SeederDatabase] Failed to reset the database. Error: \(error.localizedDescription)")
        }
    }
    
    static func seedDatabaseIfNeeded(context: ModelContext) {
        let predefinedAnimals = [
            Animal(
                name: "Ms. Bunn",
                assetName: "rabbit",
                pickupDialog: "Oh, you're here! I've been waiting to get this moving. Please deliver it in a flash, okay? Merci—now hop to it!"
            ),
            Animal(
                name: "Mao",
                assetName: "cat",
                pickupDialog: "Meow~ About time. Handle it with care, please; I don't want a single scratch on my package! Thanks for finally showing up."
            ),
            Animal(
                name: "Mr. Beavey",
                assetName: "beaver",
                pickupDialog: "Great job being on time! This package is absolutely crucial for me. Thanks for the help—I'm counting on you to get it there in one piece."
            ),
            Animal(
                name: "Oogway",
                assetName: "turtle",
                pickupDialog: "Thank... you... just take your time delivering it... no need to rush... the world moves fast enough as it is. Have a... lovely... stroll."
            ),
            Animal(
                name: "Owen",
                assetName: "capybara",
                pickupDialog: "Take it easy, my friend. Thanks for stopping by to grab the package. No need to stress—it'll get there when it gets there. Safe travels."
            )
        ]
        
        let collectibles = [
            Collectible(name: "Necklace"),
            Collectible(name: "Scarf"),
            Collectible(name: "Clover Lucky Charm"),
            Collectible(name: "Sunflower"),
            Collectible(name: "Photostrips")
        ]
        
        let animalCount = (try? context.fetchCount(FetchDescriptor<Animal>())) ?? 0
        let relationshipCount = (try? context.fetchCount(FetchDescriptor<AnimalRelationship>())) ?? 0
        
        if animalCount == 0 || relationshipCount == 0 {
            debugLog("Database kosong. Memulai proses Seeding...")
            
            for animal in predefinedAnimals {
                context.insert(animal)
            }
            
            var relationCount = 0
            for i in 0..<predefinedAnimals.count {
                for j in (i + 1)..<predefinedAnimals.count {
                    let relation = AnimalRelationship(
                        friendOne: predefinedAnimals[i],
                        friendTwo: predefinedAnimals[j]
                    )
                    context.insert(relation)
                    relationCount += 1
                }
            }
            
            for item in collectibles {
                context.insert(item)
            }
            
            do {
                try context.save()
                debugLog("[SeederDatabase] Seeding successful! Inserted \(predefinedAnimals.count) animals, \(relationCount) relationships, and \(collectibles.count) collectibles.")
            } catch {
                debugLog("[SeederDatabase] Failed to save seed data. Error: \(error.localizedDescription)")
            }
        } else {
            debugLog("[SeederDatabase] Database is already populated. Auto-syncing existing properties.")
            do {
                let existingAnimals = try context.fetch(FetchDescriptor<Animal>())
                var synced = 0
                for animal in existingAnimals {
                    if let predefined = predefinedAnimals.first(where: { $0.name == animal.name }) {
                        if animal.assetName != predefined.assetName || animal.pickupDialog != predefined.pickupDialog {
                            animal.assetName = predefined.assetName
                            animal.pickupDialog = predefined.pickupDialog
                            synced += 1
                        }
                    }
                }
                if synced > 0 {
                    try context.save()
                    debugLog("[SeederDatabase] Synced \(synced) animal properties to match latest code.")
                }
            } catch {
                debugLog("[SeederDatabase] Failed to sync existing data: \(error.localizedDescription)")
            }
        }
    }
}
