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
        print("[PlayerFSM] Entered PlayerIdleState.")
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
        print("[PlayerFSM] Entered PlayerWalkingState.")
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
        print("[PlayerFSM] Entered PlayerInteractingState. Player movement locked.")
        movementComponent?.velocity = .zero
        
        if let component = player?.component(ofType: PlayerStateComponent.self) {
            component.updateVisuals(isWalking: false)
        }
        
        // Show a brief premium pop pulse during interactions
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
    
    private var lastDirection: String = "down"
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
        
        // Keep visuals synchronized
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
        
        // Determine current direction based on movement velocity
        var currentDirection = lastDirection
        if velocity != .zero {
            if abs(velocity.x) > abs(velocity.y) {
                currentDirection = velocity.x > 0 ? "right" : "left"
            } else {
                currentDirection = velocity.y > 0 ? "up" : "down"
            }
        }
        
        // Check if carrying state, direction, or movement state changed, or if it is the first update
        let holdingChanged = (isHolding != lastHolding)
        let directionChanged = (currentDirection != lastDirection)
        let walkingStateChanged = (isWalking != lastWalking)
        
        if holdingChanged || directionChanged || walkingStateChanged || isFirstUpdate {
            isFirstUpdate = false
            
            if holdingChanged {
                lastHolding = isHolding
                
                // Smooth transition effect when carrying state changes (fade out, change texture, fade back in)
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
        
        // Reset scale factors to 1.0 first to cleanly apply the base size change
        node.xScale = 1.0
        node.yScale = 1.0
        
        // Dynamic base size according to movement direction (up/down are vertical)
        let isVertical = (dirStr == "up" || dirStr == "down")
        node.size = isVertical ? GameConfig.playerVerticalSize : GameConfig.playerHorizontalSize
        
        if isWalking {
            // Load 3 walk textures for dynamic 4-directional walking
            let tex1 = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            let tex2 = SKTexture(imageNamed: "\(prefix)\(dirStr)_2")
            let tex3 = SKTexture(imageNamed: "\(prefix)\(dirStr)_3")
            
            // Loop pattern: 1 -> 2 -> 3 -> 2
            let textures = [tex1, tex2, tex3, tex2]
            let walkAnim = SKAction.animate(with: textures, timePerFrame: GameConfig.playerWalkFrameDuration)
            let walkAnimLoop = SKAction.repeatForever(walkAnim)
            
            // Gentle bouncy squash and stretch animation for walking
            let squashX = isVertical ? GameConfig.playerWalkVerticalSquash.x : GameConfig.playerWalkHorizontalSquash.x
            let squashY = isVertical ? GameConfig.playerWalkVerticalSquash.y : GameConfig.playerWalkHorizontalSquash.y
            let stretchX = isVertical ? GameConfig.playerWalkVerticalStretch.x : GameConfig.playerWalkHorizontalStretch.x
            let stretchY = isVertical ? GameConfig.playerWalkVerticalStretch.y : GameConfig.playerWalkHorizontalStretch.y
            
            let squash = SKAction.scaleX(to: squashX, y: squashY, duration: GameConfig.playerWalkBounceDuration)
            squash.timingMode = .easeInEaseOut
            let stretch = SKAction.scaleX(to: stretchX, y: stretchY, duration: GameConfig.playerWalkBounceDuration)
            stretch.timingMode = .easeInEaseOut
            let bounce = SKAction.repeatForever(SKAction.sequence([squash, stretch]))
            
            node.run(SKAction.group([walkAnimLoop, bounce]), withKey: "player_anim")
        } else {
            // Idle state: set static first frame of the direction
            let idleTex = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            node.texture = idleTex
            
            // Gentle flat breathing squash effect for idle
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
}
