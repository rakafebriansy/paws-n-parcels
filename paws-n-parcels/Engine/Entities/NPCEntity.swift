//
//  NPCEntity.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 18/05/26.
//

import GameplayKit
import SpriteKit

class NPCEntity: GKEntity {
    let name: String
    weak var house: HouseEntity?
    
    init(name: String, assetName: String, position: CGPoint, house: HouseEntity, scene: GameScene) {
        self.name = name
        self.house = house
        super.init()
        
        // Spawn sprite node for the animal character
        let node = SKSpriteNode(imageNamed: assetName)
        node.size = CGSize(width: 32, height: 32)
        node.position = position
        node.zPosition = 4 // Just below player, above terrain
        
        // Set up physics body for boundaries and obstacle mapping
        node.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.isDynamic = true
        node.physicsBody?.restitution = 0.0
        node.physicsBody?.friction = 0.0
        
        scene.addChild(node)
        
        addComponent(RenderComponent(node: node))
        addComponent(OwnerComponent(characterName: name))
        addComponent(MovementComponent())
    }
    
    required init?(coder: NSCoder) { fatalError() }
}
