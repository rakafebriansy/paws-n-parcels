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
            let pulseUp = SKAction.scale(to: 1.15, duration: 0.1)
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.1)
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
        
        // Check if carrying state, direction, or movement state changed
        let holdingChanged = (isHolding != lastHolding)
        let directionChanged = (currentDirection != lastDirection)
        let walkingStateChanged = (isWalking != lastWalking)
        
        if holdingChanged || directionChanged || walkingStateChanged {
            if holdingChanged {
                lastHolding = isHolding
                
                // Smooth transition effect when carrying state changes (fade out, change texture, fade back in)
                let fadeOut = SKAction.fadeAlpha(to: 0.4, duration: 0.1)
                let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
                let transitionOut = SKAction.group([fadeOut, scaleDown])
                
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
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
        
        if isWalking {
            // Load 3 walk textures for dynamic 4-directional walking
            let tex1 = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            let tex2 = SKTexture(imageNamed: "\(prefix)\(dirStr)_2")
            let tex3 = SKTexture(imageNamed: "\(prefix)\(dirStr)_3")
            
            // Loop pattern: 1 -> 2 -> 3 -> 2
            let textures = [tex1, tex2, tex3, tex2]
            let walkAnim = SKAction.animate(with: textures, timePerFrame: 0.12)
            node.run(SKAction.repeatForever(walkAnim), withKey: "player_anim")
        } else {
            // Idle state: set static first frame of the direction
            let idleTex = SKTexture(imageNamed: "\(prefix)\(dirStr)_1")
            node.texture = idleTex
            
            // Subtle premium breathing float effect for idle
            let floatUp = SKAction.moveBy(x: 0, y: 4, duration: 0.8)
            floatUp.timingMode = .easeInEaseOut
            let floatDown = SKAction.moveBy(x: 0, y: -4, duration: 0.8)
            floatDown.timingMode = .easeInEaseOut
            let breathe = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
            node.run(breathe, withKey: "player_anim")
        }
    }
}
