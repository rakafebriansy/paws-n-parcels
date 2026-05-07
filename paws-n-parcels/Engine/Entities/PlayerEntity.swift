//
//  GoldieEntity.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

class PlayerEntity: GKEntity {
    init(node: SKNode) {
        super.init()
        addComponent(RenderComponent(node: node))
        addComponent(MovementComponent())
    }
    required init?(coder: NSCoder) { fatalError() }
}
