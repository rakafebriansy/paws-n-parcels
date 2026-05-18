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
class DeliverySystem {
    let system = GKComponentSystem(componentClass: DeliveryComponent.self)
        
    var activePackage: Request? = nil
    var nearbyHouse: HouseEntity? = nil
    
    // Finite State Machine
    var stateMachine: GKStateMachine?
    weak var scene: GameScene?
    
    func setupStateMachine(requestSystem: RequestSystem, scene: GameScene) {
        self.scene = scene
        
        let states = [
            NoActiveRequestState(deliverySystem: self, requestSystem: requestSystem),
            WaitingForPickupState(deliverySystem: self, requestSystem: requestSystem),
            CarryingState(deliverySystem: self, requestSystem: requestSystem),
            DeliveryCompletedState(deliverySystem: self, requestSystem: requestSystem)
        ]
        
        self.stateMachine = GKStateMachine(states: states)
        self.stateMachine?.enter(NoActiveRequestState.self)
    }
    
    func registerEntity(_ entity: GKEntity) {
        system.addComponent(foundIn: entity)
    }
    
    func update(deltaTime: TimeInterval) {
        system.update(deltaTime: deltaTime)
        stateMachine?.update(deltaTime: deltaTime)
    }
    
    func pickUpPackage(request: Request, for entity: GKEntity) {
        guard let component = entity.component(ofType: DeliveryComponent.self)
        else {
            print("[DeliverySystem] Error: Entity does not have a DeliveryComponent. Pickup aborted.")
            return
        }
        
        guard !component.isHoldingPackage
        else {
            print("[DeliverySystem] Warning: Entity is already holding a package. Cannot pick up another one.")
            return
        }
        
        component.activeRequest = request
        self.activePackage = request
        print("[DeliverySystem] Package picked up successfully. Sender: \(request.sender.name), Receiver: \(request.receiver.name).")
    }
    
    func deliverPackage(for entity: GKEntity, relationships: [AnimalRelationship]) -> (pointsAdded: Int, isLevelUp: Bool) {
        guard let component = entity.component(ofType: DeliveryComponent.self),
              let request = component.activeRequest
        else {
            print("[DeliverySystem] Error: Entity is not holding any active request to deliver.")
            return (0, false)
        }
        
        request.isCompleted = true
        
        let rewardResult = processDeliveryReward(for: request, in: relationships)
        
        component.activeRequest = nil
        self.activePackage = nil
        
        return rewardResult
    }
    
    private func processDeliveryReward(for request: Request, in relationships: [AnimalRelationship]) -> (pointsAdded: Int, isLevelUp: Bool) {
        guard let relationship = relationships.first(where: {
            $0.involves(request.sender.name, and: request.receiver.name)
        })
        else {
            print("[DeliverySystem] Warning: No relationship found between \(request.sender.name) and \(request.receiver.name). Package delivered but no points awarded.")
            GameDataManager.shared.save()
            return (0, false)
        }
        
        let oldLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoint)
        relationship.friendshipPoint += GameConfig.deliveryRewardPoints
        
        let newLevel = FriendshipLevel.getLevel(from: relationship.friendshipPoint)
        relationship.friendshipLevel = newLevel.intValue
        
        let isLevelUp = (oldLevel != newLevel)
        
        if isLevelUp {
            print("[DeliverySystem] Level Up! Friendship between \(relationship.friendOne.name) and \(relationship.friendTwo.name) reached level \(newLevel.intValue).")
        }
        
        GameDataManager.shared.save()
        print("[DeliverySystem] Package delivered. \(GameConfig.deliveryRewardPoints) points added. Database saved.")
        
        return (GameConfig.deliveryRewardPoints, isLevelUp)
    }
}
