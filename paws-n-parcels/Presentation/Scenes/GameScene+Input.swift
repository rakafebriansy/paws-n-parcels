//
//  GameScene+Input.swift
//  paws-n-parcels
//
//  Touch handling extracted from GameScene for modularity.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase != .backgroundStory else { return }
        guard gameStateMachine?.currentState is GamePlayingState else { return }

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }

        let location = touch.location(in: cameraNode)
        joystick.processTouchBegan(location: location)
        
        if currentPhase == .tutorial {
            updateJoystickTutorialBubblePosition()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase != .backgroundStory else { return }
        guard gameStateMachine?.currentState is GamePlayingState else { return }

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }

        let locationInBase = touch.location(in: joystick.baseNode)

        joystick.processTouchMoved(locationInBase: locationInBase)

        if let movement = playerEntity.component(ofType: MovementComponent.self)
        {
            movement.velocity = joystick.currentVelocity
        }
        
        if currentPhase == .tutorial && joystick.currentVelocity != .zero {
            onFirstJoystickUse()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.processTouchEnded()

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        if isInteracting {
            if let movement = playerEntity.component(
                ofType: MovementComponent.self
            ) {
                movement.velocity = .zero
            }
            return
        }

        guard gameStateMachine?.currentState is GamePlayingState else {
            if let movement = playerEntity.component(
                ofType: MovementComponent.self
            ) {
                movement.velocity = .zero
            }
            return
        }

        if let movement = playerEntity.component(ofType: MovementComponent.self)
        {
            movement.velocity = joystick.currentVelocity
        }

        guard let touch = touches.first
        else { return }

        let locationInMap = touch.location(in: self)
        let tappedNodes = nodes(at: locationInMap)

        for node in tappedNodes {
            let name = node.name
            if name == "indicator_sender" || name == "indicator_receiver" {
                SoundManager.shared.play(.appearOnline)
                if let house = findHouseEntity(for: node) {
                    interactWithHouse(house)
                }
                break
            }
        }
    }
    
    func onFirstJoystickUse() {
        guard !hasStartedFirstMove else { return }
        hasStartedFirstMove = true
        
        debugLog("[GameScene] First joystick use detected.")
        requestSystem?.fetchData()
        
        if currentPhase == .tutorial && !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            UserDefaults.standard.set(true, forKey: "hasSeenJoystickTutorial")
            onJoystickBubbleUpdate?(nil)
            
            let activeCount = requestSystem?.houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count ?? 0
            let hasHeldPackage = deliverySystem?.activePackage != nil
            
            if activeCount == 0 && !hasHeldPackage {
                Task {
                    await requestSystem?.spawnTutorialRequestAsync()
                }
            }
            debugLog("[GameScene] Joystick tutorial dismissed by movement. Spawned tutorial request.")
        }
    }
}
