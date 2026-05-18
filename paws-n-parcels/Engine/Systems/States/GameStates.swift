//
//  GameStates.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 18/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

@MainActor
class GameBaseState: GKState {
    weak var scene: GameScene?
    
    init(scene: GameScene) {
        self.scene = scene
        super.init()
    }
}

/// State: The active gameplay state. Screen inputs drive the joystick, camera follows player, physics is unpaused.
@MainActor
class GamePlayingState: GameBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePausedState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[GameFlowFSM] Entered GamePlayingState. Unpausing scene.")
        scene?.isPaused = false
    }
}

/// State: Pause state. Automatically freezes physics and locks the joystick.
@MainActor
class GamePausedState: GameBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == GamePlayingState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        print("[GameFlowFSM] Entered GamePausedState. Pausing scene physics.")
        scene?.isPaused = true
        
        // Halt player velocity completely
        if let player = scene?.playerEntity, let movement = player.component(ofType: MovementComponent.self) {
            movement.velocity = .zero
            player.component(ofType: RenderComponent.self)?.node.physicsBody?.velocity = .zero
        }
    }
    
    override func willExit(to nextState: GKState) {
        print("[GameFlowFSM] Leaving GamePausedState. Resuming scene physics.")
        scene?.isPaused = false
    }
}
