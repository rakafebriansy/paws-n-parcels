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
                AnimalFriend(
                    name: "Kelinci",
                    assetName: "rabbit",
                    dialog: "Oh, you're here! I’ve been waiting to get this moving. Please deliver it in a flash, okay? Merci—now hop to it!"
                ),
                AnimalFriend(
                    name: "Kucing",
                    assetName: "cat",
                    dialog: "Meow~ About time. Handle it with care, please; I don’t want a single scratch on my package! Thanks for finally showing up."
                ),
                AnimalFriend(
                    name: "Berang-berang",
                    assetName: "beaver",
                    dialog: "Great job being on time! This package is absolutely crucial for me. Thanks for the help—I’m counting on you to get it there in one piece."
                ),
                AnimalFriend(
                    name: "Kura-kura",
                    assetName: "turtle",
                    dialog: "Thank... you... just take your time delivering it... no need to rush... the world moves fast enough as it is. Have a... lovely... stroll."
                ),
                AnimalFriend(
                    name: "Capybara",
                    assetName: "capybara",
                    dialog: "Take it easy, my friend. Thanks for stopping by to grab the package. No need to stress—it’ll get there when it gets there. Safe travels."
                )
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
                Collectible(name: "Wortel Emas", desc: "Ditemukan di kebun Kelinci."),
                Collectible(name: "Pita Merah", desc: "Pita favorit Kucing."),
                Collectible(name: "Ranting Kuat", desc: "Bahan bangunan Berang-berang."),
                Collectible(name: "Batu Lumut", desc: "Tempat kura-kura bersantai."),
                Collectible(name: "Jeruk Hangat", desc: "Cemilan Capybara saat mandi.")
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
