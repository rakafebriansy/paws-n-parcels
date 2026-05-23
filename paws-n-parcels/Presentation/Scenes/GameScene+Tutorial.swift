//
//  GameScene+Tutorial.swift
//  paws-n-parcels
//
//  Tutorial flow management extracted from GameScene for modularity.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func startTutorialIfNeeded() {
        currentPhase = .tutorial
        debugLog("[GameScene] Phase changed to tutorial.")
        hasStartedFirstMove = false
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            debugLog("[Tutorial] Showing joystick tutorial bubble.")
            updateJoystickTutorialBubblePosition()
        } else {
            debugLog("[GameScene] Joystick tutorial already seen.")
            
            let activeCount = requestSystem?.houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count ?? 0
            let hasHeldPackage = deliverySystem?.activePackage != nil
            
            if activeCount == 0 && !hasHeldPackage {
                debugLog("[GameScene] Spawning tutorial request immediately since none exist.")
                Task {
                    await requestSystem?.spawnTutorialRequestAsync()
                }
            } else {
                debugLog("[GameScene] Tutorial request already exists. Waiting for player action.")
            }
        }
    }
    
    func updateJoystickTutorialBubblePosition() {
        guard !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") else { return }
        let viewWidth  = self.view?.bounds.width  ?? size.width
        let viewHeight = self.view?.bounds.height ?? size.height
        let screenX = joystick.baseNode.position.x + (viewWidth / 2)
        let screenY = -joystick.baseNode.position.y + (viewHeight / 2)
        
        let clampedX = min(max(screenX, 70), viewWidth - 70)
        let clampedY = screenY - 190
        
        let data = TutorialBubbleData(
            text: "Move Goldie using this joystick.",
            position: CGPoint(x: clampedX, y: clampedY),
            isInTopZone: false
        )
        onJoystickBubbleUpdate?(data)
    }
}
