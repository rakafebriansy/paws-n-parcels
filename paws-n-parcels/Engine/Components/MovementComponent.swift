//
//  MovementComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 08/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

class MovementComponent: GKComponent {
    var velocity: CGPoint = .zero
    var speed: CGFloat {
        return 200.0 * GameConfig.playerSpeedMultiplier
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        
        guard let renderNode = entity?.component(ofType: RenderComponent.self)?.node else { return }
        
        let velocityX = velocity.x * speed
        let velocityY = velocity.y * speed
        
        renderNode.physicsBody?.velocity = CGVector(dx: velocityX, dy: velocityY)
    }
}
