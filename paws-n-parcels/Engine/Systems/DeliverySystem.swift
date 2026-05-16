//
//  DeliverySystem.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit
import SwiftData

@MainActor
class DeliverySystem: GKComponentSystem<DeliveryComponent> {
    private var context: ModelContext?
    
    var activePackage: Request? = nil
    var nearbyHouse: HouseEntity? = nil
    
    func setup(context: ModelContext) {
        self.context = context
        print("[DeliverySystem] Initialized and linked with ModelContext.")
    }
    
    func pickUpPackage(request: Request, for entity: GKEntity) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self) else {
            print("[DeliverySystem] Error: Entity does not have a DeliveryComponent. Pickup aborted.")
            return
        }
        
        if !deliveryComp.isHoldingPackage {
            deliveryComp.activeRequest = request
            self.activePackage = request
            print("[DeliverySystem] Package picked up successfully. Sender: \(request.senderName), Receiver: \(request.receiverName).")
        } else {
            print("[DeliverySystem] Warning: Entity is already holding a package. Cannot pick up another one.")
        }
    }
    
    func deliverPackage(for entity: GKEntity, relationships: [AnimalRelationship]) -> (pointsAdded: Int, isLevelUp: Bool) {
        guard let deliveryComp = entity.component(ofType: DeliveryComponent.self) else {
            print("[DeliverySystem] Error: Entity does not have a DeliveryComponent. Delivery aborted.")
            return (0, false)
        }
        
        guard let request = deliveryComp.activeRequest else {
            print("[DeliverySystem] Error: Entity is not holding any active request to deliver.")
            return (0, false)
        }
        
        guard let context = self.context else {
            print("[DeliverySystem] Error: ModelContext is missing. Have you called setup(context:)?")
            return (0, false)
        }
        
        var isLevelUp = false
        request.isCompleted = true
        
        if let relationship = relationships.first(where: {
            ($0.friendOneName == request.senderName && $0.friendTwoName == request.receiverName) ||
            ($0.friendOneName == request.receiverName && $0.friendTwoName == request.senderName)
        }) {
            let oldLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoint)
            
            relationship.friendshipPoint += GameConfig.deliveryRewardPoints
            
            let newLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoint)
            relationship.friendshipLevel = newLevel.intValue
            
            if oldLevel != newLevel {
                isLevelUp = true
                print("[DeliverySystem] Level Up! Friendship between \(relationship.friendOneName) and \(relationship.friendTwoName) reached level \(newLevel.intValue).")
            }
            
            do {
                try context.save()
                print("[DeliverySystem] Package delivered. \(GameConfig.deliveryRewardPoints) points added. Database saved.")
            } catch {
                print("[DeliverySystem] Error: Failed to save relationship data after delivery. Details: \(error.localizedDescription)")
            }
        } else {
            print("[DeliverySystem] Warning: No relationship found between \(request.senderName) and \(request.receiverName). Package delivered but no points awarded.")
        }
        
        deliveryComp.activeRequest = nil
        self.activePackage = nil
        
        return (GameConfig.deliveryRewardPoints, isLevelUp)
    }
}
