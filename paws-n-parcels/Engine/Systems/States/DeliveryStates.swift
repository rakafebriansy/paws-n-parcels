//
//  DeliveryStates.swift
//  paws-n-parcels
//
//  Created by Antigravity on 18/05/26.
//

import Foundation
import GameplayKit

@MainActor
class DeliveryBaseState: GKState {
    unowned let deliverySystem: DeliverySystem
    unowned let requestSystem: RequestSystem
    
    init(deliverySystem: DeliverySystem, requestSystem: RequestSystem) {
        self.deliverySystem = deliverySystem
        self.requestSystem = requestSystem
        super.init()
    }
}

/// State: Player has no active request en-route, waiting for requests to be available.
@MainActor
class NoActiveRequestState: DeliveryBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == WaitingForPickupState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[DeliveryFSM] Entered NoActiveRequestState. Checking for available package requests.")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let hasActiveRequests = requestSystem.houses.contains(where: { $0.component(ofType: RequestComponent.self) != nil })
        if hasActiveRequests {
            stateMachine?.enter(WaitingForPickupState.self)
        }
    }
}

/// State: At least one package request has spawned on the map. Waiting for player pickup.
@MainActor
class WaitingForPickupState: DeliveryBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == CarryingState.self || stateClass == NoActiveRequestState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[DeliveryFSM] Entered WaitingForPickupState. Active package is waiting to be picked up.")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        let hasActiveRequests = requestSystem.houses.contains(where: { $0.component(ofType: RequestComponent.self) != nil })
        if !hasActiveRequests {
            stateMachine?.enter(NoActiveRequestState.self)
        }
    }
    
    func pickUp(request: Request, player: GKEntity) {
        deliverySystem.pickUpPackage(request: request, for: player)
        stateMachine?.enter(CarryingState.self)
    }
}

/// State: Player has picked up a package and is en-route carrying it to the recipient.
@MainActor
class CarryingState: DeliveryBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == DeliveryCompletedState.self || stateClass == NoActiveRequestState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[DeliveryFSM] Entered CarryingState. Player is carrying package to \(deliverySystem.activePackage?.receiver.name ?? "Target").")
    }
    
    func deliver() {
        stateMachine?.enter(DeliveryCompletedState.self)
    }
}

/// State: Player has successfully delivered the package. Awards relationships points and triggers UI alerts.
@MainActor
class DeliveryCompletedState: DeliveryBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == NoActiveRequestState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[DeliveryFSM] Entered DeliveryCompletedState. Processing rewards and alerts...")
        
        guard let scene = deliverySystem.scene else {
            print("[DeliveryFSM] Error: GameScene reference is nil in DeliverySystem!")
            stateMachine?.enter(NoActiveRequestState.self)
            return
        }
        
        // Process reward calculations
        let result = deliverySystem.deliverPackage(for: scene.playerEntity, relationships: requestSystem.relationships)
        
        // Trigger delivery success callback on the scene to show UI
        scene.onDeliverySuccess?(result.pointsAdded)
        
        // Trigger background scheduler to spawn next package
        requestSystem.triggerNewPackageSpawn(delaySeconds: GameConfig.newRequestSpawnDelay)
        
        // Go back to idle/no active request state
        stateMachine?.enter(NoActiveRequestState.self)
    }
}
