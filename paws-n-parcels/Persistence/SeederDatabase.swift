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
        
        // Hanya jalan jika database benar-benar kosong atau relasi hilang
        if animalCount == 0 || relationshipCount == 0 {
            print("[SeederDatabase] Database is empty. Starting the seeding process...")
            
            // Seed 5 Animal
            let animals = [
                Animal(name: "Joko", assetName: "rabbit"),
                Animal(name: "Susilo", assetName: "cat"),
                Animal(name: "Santoso", assetName: "beaver"),
                Animal(name: "Purnomo", assetName: "turtle"),
                Animal(name: "Capybara", assetName: "capybara")
            ]
            
            for animal in animals {
                context.insert(animal)
            }
            
            var relationCount = 0
            for i in 0..<animals.count {
                for j in (i + 1)..<animals.count {
                    let relation = AnimalRelationship(
                        friendOneName: animals[i].name,
                        friendTwoName: animals[j].name,
                        friendshipLevel: 1
                    )
                    context.insert(relation)
                    relationCount += 1
                }
            }
            
            let collectibles = [
                Collectible(name: "Wortel Emas", desc: "Ditemukan di kebun Kelinci."),
                Collectible(name: "Pita Merah", desc: "Pita favorit Kucing."),
                Collectible(name: "Ranting Kuat", desc: "Bahan bangunan Berang-berang."),
                Collectible(name: "Batu Lumut", desc: "Tempat kura-kura bersantai."),
                Collectible(name: "Jeruk Hangat", desc: "Cemilan Capybara saat mandi.")
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
