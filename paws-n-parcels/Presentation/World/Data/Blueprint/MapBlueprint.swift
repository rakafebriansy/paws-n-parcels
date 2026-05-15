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
}

let worldMap = MapBlueprint(
    groundSize: GameConfig.worldSize,
    oceanGridHeight: 3,
    beachGridHeight: 2,
    roads: [
        [
            CGPoint(x: 3, y: 6),
            CGPoint(x: 3, y: 24),
        ],
        [
            CGPoint(x: 8, y: 24),
            CGPoint(x: 3, y: 24),
        ],
        [
            CGPoint(x: 8, y: 10),
            CGPoint(x: 8, y: 16),
        ],
        [
            CGPoint(x: 3, y: 10),
            CGPoint(x: 25, y: 10),
        ],
        [
            CGPoint(x: 8, y: 26),
            CGPoint(x: 8, y: 25),
        ],
        [
            CGPoint(x: 19, y: 6),
            CGPoint(x: 14, y: 6),
        ],
        [
            CGPoint(x: 21, y: 9),
            CGPoint(x: 21, y: 6),
        ],
        [
            CGPoint(x: 21, y: 9),
            CGPoint(x: 21, y: 24),
        ],
    ],
    items: [
        ItemBlueprint(type: .house, pos: CGPoint(x: 1, y: 6)), //goldie's house
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 19, y: 7), characterName: "Joko"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 17, y: 7), characterName: "Susilo"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 15, y: 7)),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 27, y: 9), characterName: "Santoso"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 25, y: 11)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 25, y: 7)),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 6, y: 25)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 8, y: 27)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 10, y: 25), characterName: "Purnomo"),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 6, y: 15)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 8, y: 17)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 10, y: 15)),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 19, y: 23), characterName: "Capybara"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 21, y: 25)),
        ItemBlueprint(type: .house, pos: CGPoint(x: 23, y: 23)),
        
        ItemBlueprint(type: .pond(size: CGSize(width: 3, height: 2)), pos: CGPoint(x: 14, y: 16), rotation: 180),
    ] +
    ItemBlueprint.generateForest(origin: CGPoint(x: 5, y: 6), columns: 8, rows: 5, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 0, y: 26), columns: 5, rows: 5, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 0, y: 22), columns: 2, rows: 8, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 24, y: 14), columns: 6, rows: 16, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5),
)

#Preview {
    SpriteView(scene: {
        let previewScene = SKScene(size: worldMap.groundSize)
        
        previewScene.anchorPoint = CGPoint(x: 0, y: 0)
        previewScene.scaleMode = .aspectFit
        
        let builder = MapBuilder(scene: previewScene)
        builder.build(blueprint: worldMap)
        
        return previewScene
    }())
    .ignoresSafeArea()
}
