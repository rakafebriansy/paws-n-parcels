//
//  NPCStates.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 18/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

@MainActor
class NPCBaseState: GKState {
    weak var npc: NPCEntity?
    weak var scene: GameScene?
    
    init(npc: NPCEntity, scene: GameScene) {
        self.npc = npc
        self.scene = scene
        super.init()
    }
    
    var npcNode: SKSpriteNode? {
        return npc?.component(ofType: RenderComponent.self)?.node as? SKSpriteNode
    }
    
    var movementComponent: MovementComponent? {
        return npc?.component(ofType: MovementComponent.self)
    }
    
    var houseEntity: HouseEntity? {
        return npc?.house
    }
}

/// State: NPC is wandering randomly near their home house.
@MainActor
class NPCWanderingState: NPCBaseState {
    private var timeInCurrentDirection: TimeInterval = 0.0
    private var targetDirectionTime: TimeInterval = 2.0
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == NPCWaitingState.self || stateClass == NPCCelebratingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[NPCAI] \(npc?.name ?? "NPC") entered NPCWanderingState.")
        chooseRandomVelocity()
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        timeInCurrentDirection += seconds
        
        // Transition to WaitingState if their house has an active request to pick up
        if let house = houseEntity, house.component(ofType: RequestComponent.self) != nil {
            stateMachine?.enter(NPCWaitingState.self)
            return
        }
        
        if timeInCurrentDirection >= targetDirectionTime {
            chooseRandomVelocity()
        }
    }
    
    private func chooseRandomVelocity() {
        timeInCurrentDirection = 0.0
        targetDirectionTime = Double.random(in: 1.5...3.5)
        
        // 40% chance to stand still, 60% chance to walk
        if Double.random(in: 0...1) < 0.4 {
            movementComponent?.velocity = .zero
            npcNode?.removeAllActions()
        } else {
            // Walk randomly in a small radius around their home pos
            let angle = Double.random(in: 0...(2 * .pi))
            movementComponent?.velocity = CGPoint(x: cos(angle) * 0.5, y: sin(angle) * 0.5) // Walk slower than player
            
            // Simple bounce wiggle walk animation
            if let node = npcNode {
                node.removeAllActions()
                let hopUp = SKAction.moveBy(x: 0, y: 4, duration: 0.18)
                let hopDown = hopUp.reversed()
                let wiggleLeft = SKAction.rotate(toAngle: 0.1, duration: 0.18)
                let wiggleRight = SKAction.rotate(toAngle: -0.1, duration: 0.18)
                
                let wiggle = SKAction.sequence([wiggleLeft, wiggleRight])
                let hop = SKAction.sequence([hopUp, hopDown])
                node.run(SKAction.repeatForever(SKAction.group([wiggle, hop])))
            }
        }
    }
}

/// State: NPC is waiting in front of their home house.
/// Occurs when they have an active request to pick up.
@MainActor
class NPCWaitingState: NPCBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == NPCWanderingState.self || stateClass == NPCCelebratingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[NPCAI] \(npc?.name ?? "NPC") entered NPCWaitingState. Waiting for delivery pickup.")
        movementComponent?.velocity = .zero
        npcNode?.removeAllActions()
        
        // Float in place indicator animation above the NPC
        if let node = npcNode {
            let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 0.7)
            floatUp.timingMode = .easeInEaseOut
            let floatDown = floatUp.reversed()
            node.run(SKAction.repeatForever(SKAction.sequence([floatUp, floatDown])), withKey: "float")
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // If the request has been picked up (RequestComponent removed), return to wandering
        if let house = houseEntity, house.component(ofType: RequestComponent.self) == nil {
            npcNode?.removeAction(forKey: "float")
            stateMachine?.enter(NPCWanderingState.self)
        }
    }
}

/// State: NPC is celebrating delivery success!
/// Loops a jumping animation and emits a heart emoji floating upwards.
@MainActor
class NPCCelebratingState: NPCBaseState {
    private var celebrationTimer: TimeInterval = 0.0
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == NPCWanderingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[NPCAI] \(npc?.name ?? "NPC") entered NPCCelebratingState! Thank you, player!")
        movementComponent?.velocity = .zero
        npcNode?.removeAllActions()
        celebrationTimer = 0.0
        
        if let node = npcNode {
            // Heart-shaped jump scale animation
            let jumpUp = SKAction.moveBy(x: 0, y: 25, duration: 0.2)
            jumpUp.timingMode = .easeOut
            let jumpDown = SKAction.moveBy(x: 0, y: -25, duration: 0.15)
            jumpDown.timingMode = .easeIn
            let scaleUp = SKAction.scale(to: 1.3, duration: 0.1)
            let scaleNormal = SKAction.scale(to: 1.0, duration: 0.15)
            
            let jumpAndScale = SKAction.sequence([
                SKAction.group([jumpUp, scaleUp]),
                SKAction.group([jumpDown, scaleNormal])
            ])
            
            node.run(SKAction.repeat(jumpAndScale, count: 3))
            
            // Spawn a temporary heart icon above the NPC
            let heartLabel = SKLabelNode(text: "❤️")
            heartLabel.fontSize = 20
            heartLabel.position = CGPoint(x: 0, y: 24)
            heartLabel.zPosition = 10
            node.addChild(heartLabel)
            
            let floatUp = SKAction.moveBy(x: 0, y: 35, duration: 0.9)
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            heartLabel.run(SKAction.sequence([SKAction.group([floatUp, fadeOut]), remove]))
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        celebrationTimer += seconds
        
        // Celebrate for 2.5 seconds, then return to wandering
        if celebrationTimer >= 2.5 {
            stateMachine?.enter(NPCWanderingState.self)
        }
    }
}

/// ECS Component: Updates the AI's active FSM behavior.
@MainActor
class NPCStateComponent: GKComponent {
    var stateMachine: GKStateMachine?
    weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func didAddToEntity() {
        guard let npc = entity as? NPCEntity, let scene = scene else { return }
        
        let states = [
            NPCWanderingState(npc: npc, scene: scene),
            NPCWaitingState(npc: npc, scene: scene),
            NPCCelebratingState(npc: npc, scene: scene)
        ]
        self.stateMachine = GKStateMachine(states: states)
        self.stateMachine?.enter(NPCWanderingState.self)
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        stateMachine?.update(deltaTime: seconds)
    }
}
