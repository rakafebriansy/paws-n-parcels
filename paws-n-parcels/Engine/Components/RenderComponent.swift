//
//  RenderComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

class RenderComponent: GKComponent {
    let node: SKNode
    init(node: SKNode) {
        self.node = node
        super.init()
    }
    required init?(coder: NSCoder) { fatalError() }
}
