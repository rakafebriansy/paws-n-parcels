//
//  PlayerStates.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 18/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

@MainActor
class PlayerBaseState: GKState {
    weak var player: GKEntity?
    weak var scene: GameScene?
    
    init(player: GKEntity, scene: GameScene) {
        self.player = player
        self.scene = scene
        super.init()
    }
    
    var playerNode: SKSpriteNode? {
        return player?.component(ofType: RenderComponent.self)?.node as? SKSpriteNode
    }
    
    var movementComponent: MovementComponent? {
        return player?.component(ofType: MovementComponent.self)
    }
}

@MainActor
class PlayerIdleState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerWalkingState.self || stateClass == PlayerInteractingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        debugLog("[PlayerFSM] Entered PlayerIdleState.")
        movementComponent?.velocity = .zero
        
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: false)
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: false)
        }
        if let velocity = movementComponent?.velocity, velocity != .zero {
            stateMachine?.enter(PlayerWalkingState.self)
        }
    }
}

@MainActor
class PlayerWalkingState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerIdleState.self || stateClass == PlayerInteractingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        debugLog("[PlayerFSM] Entered PlayerWalkingState.")
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: true)
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: true)
        }
        if let velocity = movementComponent?.velocity, velocity == .zero {
            stateMachine?.enter(PlayerIdleState.self)
        }
    }
}

@MainActor
class PlayerInteractingState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerIdleState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        debugLog("[PlayerFSM] Entered PlayerInteractingState. Player movement locked.")
        movementComponent?.velocity = .zero
        
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: false)
        }
        
        if let node = playerNode {
            let pulseUp = SKAction.scale(to: GameConfig.playerInteractionPulseUp, duration: GameConfig.playerInteractionPulseUpDuration)
            let pulseDown = SKAction.scale(to: GameConfig.playerInteractionPulseDown, duration: GameConfig.playerInteractionPulseDownDuration)
            node.run(SKAction.sequence([pulseUp, pulseDown]))
        }
    }
}

@MainActor
class PlayerStateComponent: GKComponent {
    var stateMachine: GKStateMachine?
    weak var scene: GameScene?
    
    private var lastDirection: String = "front"
    private var lastHolding: Bool = false
    private var lastWalking: Bool = false
    private var isFirstUpdate: Bool = true
    
    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func didAddToEntity() {
        guard let entity = entity, let scene = scene else { return }
        
        let states = [
            PlayerIdleState(player: entity, scene: scene),
            PlayerWalkingState(player: entity, scene: scene),
            PlayerInteractingState(player: entity, scene: scene)
        ]
        self.stateMachine = GKStateMachine(states: states)
        self.stateMachine?.enter(PlayerIdleState.self)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        stateMachine?.update(deltaTime: seconds)
        
        let isWalking = stateMachine?.currentState is PlayerWalkingState
        updateVisuals(isWalking: isWalking)
    }
    
    func updateVisuals(isWalking: Bool) {
        guard let entity = entity,
              let node = entity.component(ofType: RenderComponent.self)?.node as? SKSpriteNode,
              let movement = entity.component(ofType: MovementComponent.self),
              let delivery = entity.component(ofType: DeliveryComponent.self) else { return }
              
        let isHolding = delivery.isHoldingPackage
        let velocity = movement.velocity
        
        var currentDirection = lastDirection
        if velocity != .zero {
            if abs(velocity.x) > abs(velocity.y) {
                currentDirection = velocity.x > 0 ? "right" : "left"
            } else {
                currentDirection = velocity.y > 0 ? "up" : "front"
            }
        }
        
        let holdingChanged = (isHolding != lastHolding)
        let directionChanged = (currentDirection != lastDirection)
        let walkingStateChanged = (isWalking != lastWalking)
        
        if holdingChanged || directionChanged || walkingStateChanged || isFirstUpdate {
            isFirstUpdate = false
            
            if holdingChanged {
                lastHolding = isHolding
                
                let fadeOut = SKAction.fadeAlpha(to: GameConfig.playerCarryingTransitionAlpha, duration: GameConfig.playerCarryingTransitionDuration)
                let scaleDown = SKAction.scale(to: GameConfig.playerCarryingTransitionScale, duration: GameConfig.playerCarryingTransitionDuration)
                let transitionOut = SKAction.group([fadeOut, scaleDown])
                
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: GameConfig.playerCarryingTransitionDuration)
                let scaleUp = SKAction.scale(to: 1.0, duration: GameConfig.playerCarryingTransitionDuration)
                let transitionIn = SKAction.group([fadeIn, scaleUp])
                
                let changeTextureAction = SKAction.run { [weak self] in
                    guard let self = self else { return }
                    self.applyAnimation(node: node, direction: currentDirection, isHolding: isHolding, isWalking: isWalking)
                }
                
                node.run(SKAction.sequence([transitionOut, changeTextureAction, transitionIn]))
            } else {
                applyAnimation(node: node, direction: currentDirection, isHolding: isHolding, isWalking: isWalking)
            }
            
            lastDirection = currentDirection
            lastWalking = isWalking
        }
    }
    
    private func applyAnimation(node: SKSpriteNode, direction: String, isHolding: Bool, isWalking: Bool) {
        node.removeAction(forKey: "player_anim")
        
        let prefix = isHolding ? "goldie_package_" : "goldie_"
        let dirStr = direction
        
        
        node.xScale = 1.0
        node.yScale = 1.0
        
        
        let isVertical = (dirStr == "up" || dirStr == "front")
        if dirStr == "up" {
            node.size = GameConfig.playerUpSize
        } else if dirStr == "front" {
            node.size = GameConfig.playerFrontSize
        } else {
            node.size = GameConfig.playerHorizontalSize
        }
        
        if isWalking {
            let tex1 = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            let tex2 = SKTexture(imageNamed: "\(prefix)\(dirStr)_2")
            let tex3 = SKTexture(imageNamed: "\(prefix)\(dirStr)_3")
            
            let textures = [tex1, tex2, tex3, tex2]
            let walkAnim = SKAction.animate(with: textures, timePerFrame: GameConfig.playerWalkFrameDuration)
            let walkAnimLoop = SKAction.repeatForever(walkAnim)
            
            let squashX = isVertical ? GameConfig.playerWalkVerticalSquash.x : GameConfig.playerWalkHorizontalSquash.x
            let squashY = isVertical ? GameConfig.playerWalkVerticalSquash.y : GameConfig.playerWalkHorizontalSquash.y
            let stretchX = isVertical ? GameConfig.playerWalkVerticalStretch.x : GameConfig.playerWalkHorizontalStretch.x
            let stretchY = isVertical ? GameConfig.playerWalkVerticalStretch.y : GameConfig.playerWalkHorizontalStretch.y
            
            let squash = SKAction.scaleX(to: squashX, y: squashY, duration: GameConfig.playerWalkBounceDuration)
            squash.timingMode = .easeInEaseOut
            let stretch = SKAction.scaleX(to: stretchX, y: stretchY, duration: GameConfig.playerWalkBounceDuration)
            stretch.timingMode = .easeInEaseOut
            let bounce = SKAction.repeatForever(SKAction.sequence([squash, stretch]))
            
            let footstepAction = SKAction.run { [weak self] in
                self?.playFootstepSound()
            }
            let footstepWait = SKAction.wait(forDuration: GameConfig.playerWalkFrameDuration * 2.0)
            let footstepLoop = SKAction.repeatForever(SKAction.sequence([footstepAction, footstepWait]))
            
            node.run(SKAction.group([walkAnimLoop, bounce, footstepLoop]), withKey: "player_anim")
        } else {
            let idleTex = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            node.texture = idleTex
            
            let breatheSquashX = isVertical ? GameConfig.playerIdleVerticalSquash.x : GameConfig.playerIdleHorizontalSquash.x
            let breatheSquashY = isVertical ? GameConfig.playerIdleVerticalSquash.y : GameConfig.playerIdleHorizontalSquash.y
            let breatheStretchX = isVertical ? GameConfig.playerIdleVerticalStretch.x : GameConfig.playerIdleHorizontalStretch.x
            let breatheStretchY = isVertical ? GameConfig.playerIdleVerticalStretch.y : GameConfig.playerIdleHorizontalStretch.y
            
            let breatheSquash = SKAction.scaleX(to: breatheSquashX, y: breatheSquashY, duration: GameConfig.playerIdleBreatheDuration)
            breatheSquash.timingMode = .easeInEaseOut
            let breatheStretch = SKAction.scaleX(to: breatheStretchX, y: breatheStretchY, duration: GameConfig.playerIdleBreatheDuration)
            breatheStretch.timingMode = .easeInEaseOut
            let breathe = SKAction.repeatForever(SKAction.sequence([breatheSquash, breatheStretch]))
            
            node.run(breathe, withKey: "player_anim")
        }
    }
    
    private var isAlternateFootstep = false
    
    private func playFootstepSound() {
        guard let scene = scene, let node = entity?.component(ofType: RenderComponent.self)?.node as? SKSpriteNode else { return }
        
        let roadMap = scene.childNode(withName: "roadMap") as? SKTileMapNode
        let position = node.position
        
        var isOnGravel = false
        if let roadMap = roadMap {
            let column = roadMap.tileColumnIndex(fromPosition: position)
            let row = roadMap.tileRowIndex(fromPosition: position)
            if column >= 0, column < roadMap.numberOfColumns, row >= 0, row < roadMap.numberOfRows {
                if let _ = roadMap.tileDefinition(atColumn: column, row: row) {
                    isOnGravel = true
                }
            }
        }
        
        isAlternateFootstep.toggle()
        if isOnGravel {
            SoundManager.shared.play(isAlternateFootstep ? .gravel6 : .gravel8)
        } else {
            SoundManager.shared.play(isAlternateFootstep ? .grass7 : .grass6)
        }
    }
}
