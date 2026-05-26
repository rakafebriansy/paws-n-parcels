//
//  JoystickController.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SpriteKit
import UIKit

class JoystickController {
    let baseNode: SKSpriteNode
    let knobNode: SKSpriteNode
    var isActive: Bool = false
    var currentVelocity: CGPoint = .zero
    
    private let maxRadius: CGFloat = 50.0
    
    private let resetAction: SKAction = {
        let action = SKAction.move(to: .zero, duration: 0.1)
        action.timingMode = .easeOut
        return action
    }()
    
    init() {
        debugLog("[JoystickController] Initializing joystick nodes.")
        
        let baseDiameter = maxRadius * 2
        let rendererBase = UIGraphicsImageRenderer(size: CGSize(width: baseDiameter, height: baseDiameter))
        let baseImage = rendererBase.image { ctx in
            UIColor.black.withAlphaComponent(0.2).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: baseDiameter, height: baseDiameter))
        }
        
        let knobRadius: CGFloat = 25.0
        let knobDiameter = knobRadius * 2
        let rendererKnob = UIGraphicsImageRenderer(size: CGSize(width: knobDiameter, height: knobDiameter))
        let knobImage = rendererKnob.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: knobDiameter, height: knobDiameter))
        }
        
        baseNode = SKSpriteNode(texture: SKTexture(image: baseImage))
        baseNode.zPosition = 100
        
        knobNode = SKSpriteNode(texture: SKTexture(image: knobImage))
        knobNode.zPosition = 101
        
        baseNode.addChild(knobNode)
    }
    
    func attach(to camera: SKCameraNode, screenHeight: CGFloat) {
        let screenBottom = -(screenHeight / 2)
        let defaultYPosition = screenBottom + 150
        
        baseNode.position = CGPoint(x: 0, y: defaultYPosition)
        camera.addChild(baseNode)
        
        debugLog("[JoystickController] Attached to camera at default position Y: \(defaultYPosition).")
    }
    
    func processTouchBegan(location: CGPoint) {
        isActive = true
        baseNode.position = location
        knobNode.position = .zero
    }
    
    func processTouchMoved(locationInBase: CGPoint) {
        guard isActive
        else { return }
        
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
            knobNode.run(resetAction)
        }
    }
}
