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
    let speed: CGFloat = 200.0
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let renderNode = entity?.component(ofType: RenderComponent.self)?.node else { return }
        
        let dx = velocity.x * speed * CGFloat(seconds)
        let dy = velocity.y * speed * CGFloat(seconds)
        
        renderNode.position = CGPoint(x: renderNode.position.x + dx, y: renderNode.position.y + dy)
    }
}
