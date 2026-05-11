//
//  DeliverySystem.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit
import SwiftData

class DeliverySystem: GKComponentSystem<DeliveryComponent> {
    private var context: ModelContext?
    
    func setup(context: ModelContext) {
        self.context = context
    }
    
    // Fungsi untuk mengambil paket
    func pickUpPackage(request: Requests, for entity: GKEntity) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self) else { return }
        
        if !deliveryComp.isHoldingPackage {
            deliveryComp.activeRequest = request
            print("Paket dari \(request.sender.name) berhasil diambil!")
        }
    }
    
    // Fungsi untuk mengantar paket
    func deliverPackage(for entity: GKEntity, allRelationships: [AnimalFriendRelationship]) -> (pointsAdded: Int, isLevelUp: Bool) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self),
              let request = deliveryComp.activeRequest,
              let context = self.context else {
            return (0, false)
        }
        
        var isLevelUp = false
        
        // Tandai request selesai
        request.isCompleted = true
        
        // Cari relasi di database
        if let relationship = allRelationships.first(where: {
            ($0.friendOne.id == request.sender.id && $0.friendTwo.id == request.receiver.id) ||
            ($0.friendOne.id == request.receiver.id && $0.friendTwo.id == request.sender.id)
        }) {
            // Cek level lama
            let oldLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoints)
            
            // Tambah poin
            relationship.friendshipPoints += GameConfig.deliveryRewardPoints
            
            // Cek level baru
            let newLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoints)
            if oldLevel != newLevel {
                isLevelUp = true
            }
            
            // Save ke database
            do {
                try context.save()
            } catch {
                print("Gagal menyimpan data pengantaran: \(error)")
            }
        }
        
        // Hapus kondisi membawa paket
        deliveryComp.activeRequest = nil
        
        // Kembalikan hasil agar UI bisa memunculkan Alert yang sesuai
        return (GameConfig.deliveryRewardPoints, isLevelUp)
    }
}
