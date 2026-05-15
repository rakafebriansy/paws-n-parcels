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
    
    init() {
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
        baseNode.position = CGPoint(x: 0, y: screenBottom + 150)
        camera.addChild(baseNode)
    }
    
    func processTouchBegan(location: CGPoint, treshold: CGFloat) {
        if location.y < treshold {
            isActive = true
            baseNode.position = location
            knobNode.position = .zero
        }
    }
    func processTouchMoved(locationInBase: CGPoint) {
        guard isActive else { return }
        
        let distance = sqrt(locationInBase.x * locationInBase.x + locationInBase.y * locationInBase.y)
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
            
            let resetAction = SKAction.move(to: .zero, duration: 0.1)
            resetAction.timingMode = .easeOut
            knobNode.run(resetAction)
        }
    }
}
