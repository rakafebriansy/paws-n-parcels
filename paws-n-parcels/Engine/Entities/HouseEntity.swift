//
//  HouseEnitity.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import GameplayKit
import SpriteKit

class HouseEntity: GKEntity {
    let characterName: String?

    init(name: String? = nil, node: SKNode) {
        self.characterName = name
        super.init()
        
        addComponent(RenderComponent(node: node))
    }

    // testing usage
    init(name: String? = nil, position: CGPoint) {
        self.characterName = name
        super.init()
        
        let logicalNode = SKNode()
        logicalNode.position = position
        
        addComponent(RenderComponent(node: logicalNode))
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
