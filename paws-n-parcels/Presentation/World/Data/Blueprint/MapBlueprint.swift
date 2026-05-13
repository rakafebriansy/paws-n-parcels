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
    let items: [ItemBlueprint]
    let trees: [CGPoint]
}

let worldMap = MapBlueprint(
    groundSize: CGSize(width: 2000, height: 2000),
    oceanGridHeight: 3,
    beachGridHeight: 2,
    roads: [
        [
            CGPoint(x: 3, y: 6),
            CGPoint(x: 3, y: 17),
        ],
        [
            CGPoint(x: 8, y: 17),
            CGPoint(x: 3, y: 17),
        ],
        [
            CGPoint(x: 8, y: 17),
            CGPoint(x: 8, y: 18),
        ],
        [
            CGPoint(x: 3, y: 9),
            CGPoint(x: 17, y: 9),
        ],
        [
            CGPoint(x: 8, y: 12),
            CGPoint(x: 8, y: 9),
        ],
        [
            CGPoint(x: 15, y: 9),
            CGPoint(x: 15, y: 6),
        ],
        [
            CGPoint(x: 15, y: 6),
            CGPoint(x: 11, y: 6),
        ],
        [
            CGPoint(x: 15, y: 9),
            CGPoint(x: 15, y: 16),
        ],
    ],
    items: [
        ItemBlueprint(type: .house(color: .systemYellow), pos: CGPoint(x: 2, y: 6), rotation: 45), //goldie's house
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 13, y: 7)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 12, y: 7)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 11, y: 7)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 18, y: 9)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 17, y: 10)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 17, y: 8)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 7, y: 18)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 9, y: 18)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 9, y: 17)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 7, y: 12)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 9, y: 12)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 8, y: 13)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 14, y: 16)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 16, y: 16)),
        ItemBlueprint(type: .house(color: .systemBlue), pos: CGPoint(x: 15, y: 17)),
        ItemBlueprint(type: .pond, pos: CGPoint(x: 11, y: 13), rotation: 180)
    ],
    trees: (6...8).flatMap { y in
        (4...9).map { x in
            CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
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
