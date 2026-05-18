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
    
    // FUNGSI RESET: Menghapus semua data
    static func clearDatabase(context: ModelContext) {
        do {
            try context.delete(model: AnimalFriend.self)
            try context.delete(model: AnimalFriendRelationship.self)
            try context.delete(model: Collectible.self)
            try context.delete(model: Requests.self)
            try context.save()
            print("Database berhasil direset (dikosongkan).")
        } catch {
            print("Gagal mereset database: \(error)")
        }
    }
    
    // FUNGSI SEEDER: Mengisi data awal
    static func seedDatabaseIfNeeded(context: ModelContext) {
        let fetchDescriptor = FetchDescriptor<AnimalFriend>()
        let existingAnimals = (try? context.fetch(fetchDescriptor)) ?? []
        
        // Hanya jalan jika database benar-benar kosong
        if existingAnimals.isEmpty {
            print("Database kosong. Memulai proses Seeding...")
            
            // Seed 5 AnimalFriend
            let animals = [
                AnimalFriend(name: "Kelinci", assetName: "rabbit", dialog:"Wow, thanks a ton! Please deliver it in a flash!"),
                AnimalFriend(name: "Kucing", assetName: "cat", dialog:"Meow~ About time it got picked up. Handle it with care, I don't want a single scratch on my package!"),
                AnimalFriend(name: "Berang-berang", assetName: "beaver", dialog:"Great job! This package is absolutely crucial!"),
                AnimalFriend(name: "Kura-kura", assetName: "turtle", dialog:"Thank... you... just take your time delivering it... no need to rush..."),
                AnimalFriend(name: "Capybara", assetName: "capybara", dialog:"Take it easy, my friend. Thanks for stopping by to grab the package.")
            ]
            
            for animal in animals {
                context.insert(animal)
            }
            
            // Seed 10 Relasi
            var allRelationships: [AnimalFriendRelationship] = []
            for i in 0..<animals.count {
                for j in (i + 1)..<animals.count {
                    let relation = AnimalFriendRelationship(friendOne: animals[i], friendTwo: animals[j])
                    context.insert(relation)
                    allRelationships.append(relation)
                }
            }
            
            // Seed 5 Collectibles
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
            
            // Seed 5 Requests Pertama
            for _ in 1...5 {
                if let randomRelation = allRelationships.randomElement() {
                    let isReversed = Bool.random()
                    let sender = isReversed ? randomRelation.friendTwo : randomRelation.friendOne
                    let receiver = isReversed ? randomRelation.friendOne : randomRelation.friendTwo
                    
                    let newRequest = Requests(sender: sender, receiver: receiver)
                    context.insert(newRequest)
                }
            }
            
            do {
                try context.save()
                print("Seeding sukses! 5 Hewan, 10 Relasi, 5 Collectibles, 5 Requests.")
            } catch {
                print("Gagal menyimpan hasil seeding: \(error)")
            }
        }
    }
}
