//
//  JoystickController.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SpriteKit

class JoystickController {
    let baseNode: SKShapeNode
    let knobNode: SKShapeNode
    var isActive: Bool = false
    var currentVelocity: CGPoint = .zero
    
    private let maxRadius: CGFloat = 50.0
    
    private let resetAction: SKAction = {
        let action = SKAction.move(to: .zero, duration: 0.1)
        action.timingMode = .easeOut
        return action
    }()
    
    init() {
        print("[JoystickController] Initializing joystick nodes.")
        
        baseNode = SKShapeNode(circleOfRadius: maxRadius)
        baseNode.fillColor = UIColor.black.withAlphaComponent(0.2)
        baseNode.strokeColor = .clear
        baseNode.zPosition = 100
        
        knobNode = SKShapeNode(circleOfRadius: 25)
        knobNode.fillColor = .white
        knobNode.strokeColor = .clear
        knobNode.zPosition = 101
        
        baseNode.addChild(knobNode)
    }
    
    func attach(to camera: SKCameraNode, screenHeight: CGFloat) {
        let screenBottom = -(screenHeight / 2)
        let defaultYPosition = screenBottom + 150
        
        baseNode.position = CGPoint(x: 0, y: defaultYPosition)
        camera.addChild(baseNode)
        
        print("[JoystickController] Attached to camera at default position Y: \(defaultYPosition).")
    }
    
    func processTouchBegan(location: CGPoint, treshold: CGFloat) {
        if location.y < treshold {
            isActive = true
            baseNode.position = location
            knobNode.position = .zero
            
            print("[JoystickController] Touch began. Joystick activated at \(location).")
        }
    }
    
    func processTouchMoved(locationInBase: CGPoint) {
        guard isActive else { return }
        
        let distance = hypot(locationInBase.x, locationInBase.y)
        var newPosition = locationInBase
        
        if distance > maxRadius {
            let ratio: CGFloat = maxRadius / distance
            newPosition.x *= ratio
            newPosition.y *= ratio
        }
        
        knobNode.position = newPosition
        currentVelocity = CGPoint(x: newPosition.x / maxRadius, y: newPosition.y / maxRadius)
    }
    
    func processTouchEnded() {
        if isActive {
            isActive = false
            currentVelocity = .zero
            
            print("[JoystickController] Touch ended. Joystick deactivated, resetting to center.")
            
            knobNode.run(resetAction)
        }
    }
}
