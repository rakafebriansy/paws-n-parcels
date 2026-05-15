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
            try context.delete(model: Request.self)
            try context.delete(model: AnimalFriendRelationship.self)
            try context.delete(model: Collectible.self)
            try context.delete(model: AnimalFriend.self)
            try context.save()
            print("Database berhasil direset (dikosongkan).")
        } catch {
            print("Gagal mereset database: \(error)")
        }
    }
    
    // FUNGSI SEEDER: Mengisi data awal
    static func seedDatabaseIfNeeded(context: ModelContext) {
        let animalDescriptor = FetchDescriptor<AnimalFriend>()
        let existingAnimals = (try? context.fetch(animalDescriptor)) ?? []
        
        let relDescriptor = FetchDescriptor<AnimalFriendRelationship>()
        let existingRelationships = (try? context.fetch(relDescriptor)) ?? []
        
        // Hanya jalan jika database benar-benar kosong atau relasi hilang
        if existingAnimals.isEmpty || existingRelationships.isEmpty {
            print("Database kosong. Memulai proses Seeding...")
            
            // Seed 5 AnimalFriend
            let animals = [
                AnimalFriend(name: "Joko", assetName: "rabbit"),
                AnimalFriend(name: "Susilo", assetName: "cat"),
                AnimalFriend(name: "Santoso", assetName: "beaver"),
                AnimalFriend(name: "Purnomo", assetName: "turtle"),
                AnimalFriend(name: "Capybara", assetName: "capybara")
            ]
            
            for animal in animals {
                context.insert(animal)
            }
            
            // Seed 10 Relasi
            var allRelationships: [AnimalFriendRelationship] = []
            for i in 0..<animals.count {
                for j in (i + 1)..<animals.count {
                    let relation = AnimalFriendRelationship(friendOneId: animals[i].id, friendTwoId: animals[j].id)
                    context.insert(relation)
                    allRelationships.append(relation)
                }
            }
            
            // Seed 5 Collectibles
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
                print("Seeding berhasil! \(animals.count) animals, \(allRelationships.count) relationships, \(collectibles.count) collectibles.")
            } catch {
                print("Gagal menyimpan seed data: \(error)")
            }
        } else {
            print("Database sudah terisi: \(existingAnimals.count) animals, \(existingRelationships.count) relationships.")
        }
    }
}
