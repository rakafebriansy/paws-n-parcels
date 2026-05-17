//
//  DebugDatabaseView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 10/05/26.
//

import SwiftUI
import SwiftData

struct DebugDatabaseView: View {
    @Environment(\.modelContext) private var context
    
    @Query private var animals: [Animal]
    @Query private var relationships: [AnimalRelationship]
    @Query private var collectibles: [Collectible]
    @Query private var requests: [Request]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Isi Database") {
                    Text("Total Hewan: \(animals.count)")
                    Text("Total Relasi: \(relationships.count)")
                    Text("Total Collectibles: \(collectibles.count)")
                    Text("Total Requests Aktif: \(requests.filter { !$0.isCompleted }.count)")
                }
                
                Section("Daftar Active Requests") {
                    ForEach(requests.filter { !$0.isCompleted }) { req in
                        Text("Dari: \(req.sender.name) ➡️ Ke: \(req.receiver.name)")
                    }
                }
                
                Section("Relationships Points") {
                    ForEach(relationships) { relationship in
                        Text("\(relationship.friendOne.name) & \(relationship.friendTwo.name) = \(relationship.friendshipPoint)")
                    }
                }
                
                Section("Kontrol Database") {
                    Button(action: {
                        SeederDatabase.seedDatabaseIfNeeded(context: context)
                    }) {
                        Text("Jalankan Seeder")
                            .foregroundColor(.blue)
                    }
                    
                    Button(role: .destructive, action: {
                        SeederDatabase.clearDatabase(context: context)
                    }) {
                        Text("Reset (Hapus Semua Data)")
                    }
                }
                
            }
            .navigationTitle("Debug Database")
            .onAppear {
                SeederDatabase.seedDatabaseIfNeeded(context: context)
            }
        }
    }
}

#Preview {
    DebugDatabaseView()
        .modelContainer(for: [
            Animal.self,
            AnimalRelationship.self,
            Collectible.self,
            Request.self
        ], inMemory: true)
}
