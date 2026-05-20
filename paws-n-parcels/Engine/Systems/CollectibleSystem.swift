//
//  CollectibleSystem.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 20/05/26.
//

import Foundation
import SwiftData

@MainActor
class CollectibleSystem {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    ///cari item pertama yang masih terkunci, ubah statusnya jadi isUnlocked, simpan ke database
    func unlockNextCollectible() -> Collectible? {
        let descriptor = FetchDescriptor<Collectible>(
            predicate: #Predicate {$0.isUnlocked == false}
        )
        
        if let lockedItems = try? modelContext.fetch(descriptor),
           let nextItem = lockedItems.first {
            nextItem.isUnlocked = true
            try? modelContext.save()
            return nextItem
        }
        
        // return nil kalau semua item sudah unlocked
        return nil
    }
}
