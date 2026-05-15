//
//  DeliverySystem.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit
import SwiftData
import Combine

@MainActor
class DeliverySystem: GKComponentSystem<DeliveryComponent>, ObservableObject {
    private var context: ModelContext?
    
    @Published var activePackage: Request? = nil
    @Published var nearbyHouse: HouseEntity? = nil
    
    func setup(context: ModelContext) {
        self.context = context
    }
    
    func pickUpPackage(request: Request, for entity: GKEntity) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self) else { return }
        
        if !deliveryComp.isHoldingPackage {
            deliveryComp.activeRequest = request
            self.activePackage = request
            print("Paket berhasil diambil!")
        }
    }
    
    func deliverPackage(for entity: GKEntity, allRelationships: [AnimalFriendRelationship]) -> (pointsAdded: Int, isLevelUp: Bool) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self),
              let request = deliveryComp.activeRequest,
              let context = self.context else {
            return (0, false)
        }
        
        var isLevelUp = false
        
        request.isCompleted = true
        
        if let relationship = allRelationships.first(where: {
            ($0.friendOneId == request.senderId && $0.friendTwoId == request.receiverId) ||
            ($0.friendOneId == request.receiverId && $0.friendTwoId == request.senderId)
        }) {
            let oldLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoints)
            
            relationship.friendshipPoints += GameConfig.deliveryRewardPoints
            
            let newLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoints)
            relationship.friendshipLevel = newLevel.intValue
            
            if oldLevel != newLevel {
                isLevelUp = true
            }
            
            try? context.save()
        }
        
        deliveryComp.activeRequest = nil
        self.activePackage = nil
        
        return (GameConfig.deliveryRewardPoints, isLevelUp)
    }
}
