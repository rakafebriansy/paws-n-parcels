//
//  MapBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SwiftUI
import SpriteKit

struct MapBlueprint {
    let groundSize: CGSize
    
    let oceanGridHeight: CGFloat
    let beachGridHeight: CGFloat
    
    let roads: [[CGPoint]]
    let homes: [(pos: CGPoint, color: UIColor)]
    let obstacles: [CGPoint]
}

let worldMap = MapBlueprint(
    groundSize: CGSize(width: 2000, height: 2000),
    oceanGridHeight: 3,
    beachGridHeight: 2,
    roads: [
        [
            CGPoint(x: 2, y: -10),
            CGPoint(x: 2, y: 15),
        ],
        [
            CGPoint(x: 2, y: 8),
            CGPoint(x: 12, y: 8),
        ],
    ],
    homes: [
        (pos: CGPoint(x: 1, y: 12), color: .systemOrange),
        (pos: CGPoint(x: 12, y: 10), color: .systemBlue),
        (pos: CGPoint(x: 8, y: 4), color: .systemRed),
    ],
    obstacles: [
        CGPoint(x: 6, y: 14),
        CGPoint(x: 2, y: 2),
    ]
)

#Preview {
    SpriteView(scene: {
        let previewScene = SKScene(size: worldMap.groundSize)
        
        previewScene.anchorPoint = CGPoint(x: 0, y: 0)
        previewScene.scaleMode = .aspectFit
        
        let builder = MapBuilder(scene: previewScene, gridSize: 100)
        builder.build(blueprint: worldMap)
        
        return previewScene
    }())
    .ignoresSafeArea()
}
