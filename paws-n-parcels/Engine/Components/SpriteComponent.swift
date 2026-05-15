//
//  SpriteComponent.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import SpriteKit
import GameplayKit

class SpriteComponent: GKComponent {
    // This is the actual visual object that SpriteKit draws
    let node: SKSpriteNode

    init(texture: SKTexture, position: CGPoint) {
        self.node = SKSpriteNode(texture: texture)
        self.node.position = position
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
