//
//  HouseEnitity.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import GameplayKit
import SpriteKit

class HouseEntity: GKEntity {
    init(name: String? = nil, node: SKNode) {
        super.init()
        
        addComponent(RenderComponent(node: node))
        if let ownerName = name {
            addComponent(OwnerComponent(characterName: ownerName))
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
