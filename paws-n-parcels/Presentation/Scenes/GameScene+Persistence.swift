//
//  GameScene+Persistence.swift
//  paws-n-parcels
//
//  Save/load game state management extracted from GameScene for modularity.
//

import SpriteKit
import GameplayKit
import SwiftData

extension GameScene {
    
    func saveGameState() {
        guard let playerNode = playerEntity?.component(ofType: RenderComponent.self)?.node else {
            debugLog("[GameScene] Cannot save: player node not available.")
            return
        }
        
        let playerX = Double(playerNode.position.x)
        let playerY = Double(playerNode.position.y)
        
        var activeRequestSenderNames: [String] = []
        if let mapBuilder = mapBuilder {
            for entity in mapBuilder.environmentEntities {
                if let house = entity as? HouseEntity,
                   let requestComp = house.component(ofType: RequestComponent.self),
                   let ownerName = house.component(ofType: OwnerComponent.self)?.characterName {
                    let request = requestComp.request
                    if !request.isCompleted {
                        activeRequestSenderNames.append(ownerName)
                    }
                }
            }
        }
        
        GameDataManager.shared.saveGameState(
            playerX: playerX,
            playerY: playerY,
            activeRequestSenderNames: activeRequestSenderNames
        )
    }
    
    func restoreGameState() {
        if let profile = GameDataManager.shared.fetchPlayerProfile() {
            let savedX = CGFloat(profile.positionX)
            let savedY = CGFloat(profile.positionY)
            
            if savedX != 0 || savedY != 0 {
                if let playerNode = playerEntity?.component(ofType: RenderComponent.self)?.node {
                    playerNode.position = CGPoint(x: savedX, y: savedY)
                    debugLog("[GameScene] Player position restored to (\(savedX), \(savedY))")
                }
            }
        }
    }
    
    func restoreActiveRequests() {
        let pendingRequests = GameDataManager.shared.fetchPendingRequests()
        let savedSenderNames = GameDataManager.shared.loadActiveRequestSenderNames()
        
        var restoredCount = 0
        if let mapBuilder = mapBuilder, !pendingRequests.isEmpty {
            for request in pendingRequests {
                let senderName = request.sender.name
                
                guard savedSenderNames.contains(senderName) else {
                    GameDataManager.shared.context?.delete(request)
                    continue
                }
                
                if let house = mapBuilder.environmentEntities.first(where: {
                    ($0 as? HouseEntity)?.component(ofType: OwnerComponent.self)?.characterName == senderName
                }) as? HouseEntity {
                    guard house.component(ofType: RequestComponent.self) == nil else { continue }
                    
                    let component = RequestComponent(request: request)
                    house.addComponent(component)
                    requestSystem?.system.addComponent(component)
                    restoredCount += 1
                }
            }
            GameDataManager.shared.save()
        }
        
        if let pickedUpRequest = GameDataManager.shared.fetchPickedUpRequests().first {
            deliverySystem?.pickUpPackage(request: pickedUpRequest, for: playerEntity)
            deliverySystem?.stateMachine?.enter(CarryingState.self)
            debugLog("[GameScene] Restored carried request from \(pickedUpRequest.sender.name) to \(pickedUpRequest.receiver.name).")
        }
        
        debugLog("[GameScene] Restored \(restoredCount) active requests from saved state.")
    }
    
    func startAutoSaveTimer() {
        let autoSaveAction = SKAction.sequence([
            SKAction.wait(forDuration: 30.0),
            SKAction.run { [weak self] in
                self?.saveGameState()
            }
        ])
        self.run(SKAction.repeatForever(autoSaveAction), withKey: "autoSave")
        debugLog("[GameScene] Auto-save timer started (every 30 seconds).")
    }
}
