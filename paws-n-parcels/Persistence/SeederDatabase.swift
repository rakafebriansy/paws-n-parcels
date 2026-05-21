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
            print("[SeederDatabase] Successfully reset and cleared the database.")
        } catch {
            print("[SeederDatabase] Failed to reset the database. Error: \(error.localizedDescription)")
        }
    }
    
    static func seedDatabaseIfNeeded(context: ModelContext) {
        let animalCount = (try? context.fetchCount(FetchDescriptor<Animal>())) ?? 0
        let relationshipCount = (try? context.fetchCount(FetchDescriptor<AnimalRelationship>())) ?? 0
        
        if animalCount == 0 || relationshipCount == 0 {
            print("Database kosong. Memulai proses Seeding...")
            
            let animals = [
                Animal(
                    name: "Joko",
                    assetName: "rabbit",
                    pickupDialog: "Oh, you're here! I've been waiting to get this moving. Please deliver it in a flash, okay? Merci—now hop to it!"
                ),
                Animal(
                    name: "Susilo",
                    assetName: "cat",
                    pickupDialog: "Meow~ About time. Handle it with care, please; I don't want a single scratch on my package! Thanks for finally showing up."
                ),
                Animal(
                    name: "Santoso",
                    assetName: "beaver",
                    pickupDialog: "Great job being on time! This package is absolutely crucial for me. Thanks for the help—I'm counting on you to get it there in one piece."
                ),
                Animal(
                    name: "Purnomo",
                    assetName: "turtle",
                    pickupDialog: "Thank... you... just take your time delivering it... no need to rush... the world moves fast enough as it is. Have a... lovely... stroll."
                ),
                Animal(
                    name: "Capybara",
                    assetName: "capybara",
                    pickupDialog: "Take it easy, my friend. Thanks for stopping by to grab the package. No need to stress—it'll get there when it gets there. Safe travels."
                )
            ]
            
            for animal in animals {
                context.insert(animal)
            }
            
            var relationCount = 0
            for i in 0..<animals.count {
                for j in (i + 1)..<animals.count {
                    let relation = AnimalRelationship(
                        friendOne: animals[i],
                        friendTwo: animals[j]
                    )
                    context.insert(relation)
                    relationCount += 1
                }
            }
            
            let collectibles = [
                Collectible(name: "Necklace"),
                Collectible(name: "Scarf"),
                Collectible(name: "Clover Lucky Charm"),
                Collectible(name: "Sunflower"),
                Collectible(name: "Photostrip")
            ]
            
            for item in collectibles {
                context.insert(item)
            }
            
            do {
                try context.save()
                print("[SeederDatabase] Seeding successful! Inserted \(animals.count) animals, \(relationCount) relationships, and \(collectibles.count) collectibles.")
            } catch {
                print("[SeederDatabase] Failed to save seed data. Error: \(error.localizedDescription)")
            }
        } else {
            print("[SeederDatabase] Database is already populated. Found \(animalCount) animals and \(relationshipCount) relationships.")
        }
    }
}
