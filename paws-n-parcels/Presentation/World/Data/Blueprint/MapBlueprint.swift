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
        ItemBlueprint(type: .house, pos: CGPoint(x: 1, y: 6), assetName: "house_1"), //goldie's house
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 15, y: 7), assetName: "house_2"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 25, y: 11), assetName: "house_2"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 25, y: 7), assetName: "house_2"),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 6, y: 25), assetName: "house_3"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 8, y: 27), assetName: "house_3"),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 6, y: 15), assetName: "house_4"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 8, y: 17), assetName: "house_4"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 10, y: 15), assetName: "house_4"),
        
        ItemBlueprint(type: .house, pos: CGPoint(x: 21, y: 25), assetName: "house_5"),
        ItemBlueprint(type: .house, pos: CGPoint(x: 23, y: 23), assetName: "house_5"),

        ItemBlueprint(type: .pond(size: CGSize(width: 3, height: 2)), pos: CGPoint(x: 12.7, y: 13.7), rotation: 180),
    ]
    +
    CharacterRegistry.all.enumerated().map { index, char in
        let houseNum = (index % 5) + 1
        return ItemBlueprint(type: .house, pos: char.housePosition, characterName: char.name, assetName: "house_\(houseNum)")
    }
    +
    ItemBlueprint.generateForest(origin: CGPoint(x: 5, y: 6), columns: 8, rows: 5, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 0, y: 26), columns: 5, rows: 5, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 0, y: 22), columns: 2, rows: 8, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateForest(origin: CGPoint(x: 24, y: 14), columns: 6, rows: 16, spacingX: 1.0, spacingY: 0.5, staggerOffsetX: 0.5) +
    ItemBlueprint.generateFence(origin: CGPoint(x: 5, y: 4), count: 8, spacingX: 1.0) +
    ItemBlueprint.generateFence(origin: CGPoint(x: 15, y: 4), count: 20, spacingX: 1.0),
)

#Preview {
    SpriteView(scene: {
        let previewScene = SKScene(size: worldMap.groundSize)
        
        previewScene.anchorPoint = CGPoint(x: 0, y: 0)
        previewScene.scaleMode = .aspectFit
        
        let builder = MapBuilder(scene: previewScene)
        builder.build(worldMap)
        
        return previewScene
    }())
    .ignoresSafeArea()
}
