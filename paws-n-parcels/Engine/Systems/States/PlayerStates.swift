//
//  PlayerStates.swift
//  paws-n-parcels
//
//  Created by Antigravity on 18/05/26.
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
    
    var playerNode: SKShapeNode? {
        return player?.component(ofType: RenderComponent.self)?.node as? SKShapeNode
    }
    
    var movementComponent: MovementComponent? {
        return player?.component(ofType: MovementComponent.self)
    }
}

/// State: Player character is idle. Displays a breathing bounce animation.
@MainActor
class PlayerIdleState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerWalkingState.self || stateClass == PlayerInteractingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[PlayerFSM] Entered PlayerIdleState.")
        movementComponent?.velocity = .zero
        
        if let node = playerNode {
            node.removeAllActions()
            let scaleUp = SKAction.scale(to: 1.05, duration: 0.8)
            scaleUp.timingMode = .easeInEaseOut
            let scaleDown = SKAction.scale(to: 0.95, duration: 0.8)
            scaleDown.timingMode = .easeInEaseOut
            let breathe = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
            node.run(breathe, withKey: "breathe")
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let velocity = movementComponent?.velocity, velocity != .zero {
            stateMachine?.enter(PlayerWalkingState.self)
        }
    }
}

/// State: Player character is walking based on joystick input. Displays a dynamic rotation wiggle walk animation.
@MainActor
class PlayerWalkingState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerIdleState.self || stateClass == PlayerInteractingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[PlayerFSM] Entered PlayerWalkingState.")
        
        if let node = playerNode {
            node.removeAllActions()
            let rotateLeft = SKAction.rotate(toAngle: 0.12, duration: 0.15)
            let rotateRight = SKAction.rotate(toAngle: -0.12, duration: 0.15)
            let walkAction = SKAction.repeatForever(SKAction.sequence([rotateLeft, rotateRight]))
            node.run(walkAction, withKey: "walk")
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        if let velocity = movementComponent?.velocity, velocity == .zero {
            stateMachine?.enter(PlayerIdleState.self)
        }
    }
}

/// State: Player character is currently interacting (carrying out pickup or delivery alerts).
/// Bypasses/ignores joystick inputs and anchors the player temporarily.
@MainActor
class PlayerInteractingState: PlayerBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == PlayerIdleState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[PlayerFSM] Entered PlayerInteractingState. Player movement locked.")
        movementComponent?.velocity = .zero
        
        if let node = playerNode {
            node.removeAllActions()
            let pulseUp = SKAction.scale(to: 1.2, duration: 0.15)
            let pulseDown = SKAction.scale(to: 1.0, duration: 0.1)
            node.run(SKAction.sequence([pulseUp, pulseDown]))
        }
    }
}

/// ECS Component: Holds the Player's state machine to control active movement/animation states.
@MainActor
class PlayerStateComponent: GKComponent {
    var stateMachine: GKStateMachine?
    weak var scene: GameScene?
    
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
    }
}
