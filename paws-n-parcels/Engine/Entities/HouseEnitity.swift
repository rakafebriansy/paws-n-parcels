//
//  HouseEnitity.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import GameplayKit
import SpriteKit

class HouseEntity: GKEntity {
    // If this is nil, it's just a decoration house!
    let characterName: String?

    init(name: String? = nil, position: CGPoint) {
        self.characterName = name
        super.init()
        
        // Everyone gets a sprite
        let sprite = SpriteComponent(texture: SKTexture(imageNamed: "house_static"), position: position)
        addComponent(sprite)
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
