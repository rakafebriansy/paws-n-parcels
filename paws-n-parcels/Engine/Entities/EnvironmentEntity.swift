//
//  EnvironmentEntity.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import SpriteKit
import GameplayKit

class EnvironmentEntity: GKEntity {
    init(node: SKNode) {
        super.init()
        addComponent(RenderComponent(node: node))
    }
    required init?(coder: NSCoder) { fatalError() }
}
