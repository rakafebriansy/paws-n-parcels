//
//  MapBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SwiftUI
import SpriteKit

struct MapBlueprint: Codable {
    let groundSize: CGSize
    let oceanGridHeight: CGFloat
    let beachGridHeight: CGFloat
    let roads: [[CGPoint]]
    let items: [ItemBlueprint]
}

struct GeneratorConfig: Codable {
    let type: String
    let origin: CGPoint
    let columns: Int?
    let rows: Int?
    let count: Int?
    let spacingX: CGFloat
    let spacingY: CGFloat?
    let staggerOffsetX: CGFloat?
    let rotation: CGFloat?
}

struct LevelData: Codable {
    let groundSize: CGSize
    let oceanGridHeight: CGFloat
    let beachGridHeight: CGFloat
    let roads: [[CGPoint]]
    let items: [ItemBlueprint]
    let generators: [GeneratorConfig]
}

let rawLevelDataJSON = """
{
  "groundSize": [3000, 3000],
  "oceanGridHeight": 3,
  "beachGridHeight": 2,
  "roads": [
    [[3, 6], [3, 24]],
    [[8, 24], [3, 24]],
    [[8, 10], [8, 16]],
    [[3, 10], [25, 10]],
    [[8, 26], [8, 25]],
    [[19, 6], [14, 6]],
    [[21, 9], [21, 6]],
    [[21, 9], [21, 24]]
  ],
  "items": [
    {"type": {"type": "house"}, "pos": [1, 6], "assetName": "house_1"},
    {"type": {"type": "house"}, "pos": [15, 7], "assetName": "house_2"},
    {"type": {"type": "house"}, "pos": [25, 11], "assetName": "house_2"},
    {"type": {"type": "house"}, "pos": [25, 7], "assetName": "house_2"},
    {"type": {"type": "house"}, "pos": [6, 25], "assetName": "house_3"},
    {"type": {"type": "house"}, "pos": [8, 27], "assetName": "house_3"},
    {"type": {"type": "house"}, "pos": [6, 15], "assetName": "house_4"},
    {"type": {"type": "house"}, "pos": [8, 17], "assetName": "house_4"},
    {"type": {"type": "house"}, "pos": [10, 15], "assetName": "house_4"},
    {"type": {"type": "house"}, "pos": [21, 25], "assetName": "house_5"},
    {"type": {"type": "house"}, "pos": [23, 23], "assetName": "house_5"},
    {"type": {"type": "pond", "width": 3, "height": 2}, "pos": [12.7, 13.7], "rotation": 180}
  ],
  "generators": [
    {"type": "forest", "origin": [5, 6], "columns": 8, "rows": 5, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "forest", "origin": [0, 26], "columns": 5, "rows": 5, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "forest", "origin": [0, 22], "columns": 2, "rows": 8, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "forest", "origin": [24, 14], "columns": 6, "rows": 16, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "fence", "origin": [5, 4], "count": 8, "spacingX": 1.0},
    {"type": "fence", "origin": [15, 4], "count": 20, "spacingX": 1.0}
  ]
}
"""

func parseWorldMap() -> MapBlueprint {
    guard let data = rawLevelDataJSON.data(using: .utf8) else {
        fatalError("Failed to convert rawLevelDataJSON string to Data.")
    }
    do {
        let level = try JSONDecoder().decode(LevelData.self, from: data)
        var parsedItems = level.items
        
        let registryHouses = CharacterRegistry.all.enumerated().map { index, char in
            let houseNum = (index % 5) + 1
            return ItemBlueprint(type: .house, pos: char.housePosition, characterName: char.name, assetName: "house_\(houseNum)")
        }
        parsedItems.append(contentsOf: registryHouses)
        
        for gen in level.generators {
            if gen.type == "forest" {
                let columns = gen.columns ?? 1
                let rows = gen.rows ?? 1
                let spacingY = gen.spacingY ?? 1.0
                let stagger = gen.staggerOffsetX ?? 0.0
                let trees = ItemBlueprint.generateForest(
                    origin: gen.origin,
                    columns: columns,
                    rows: rows,
                    spacingX: gen.spacingX,
                    spacingY: spacingY,
                    staggerOffsetX: stagger
                )
                parsedItems.append(contentsOf: trees)
            } else if gen.type == "fence" {
                let count = gen.count ?? 1
                let rot = gen.rotation ?? 0.0
                let fences = ItemBlueprint.generateFence(
                    origin: gen.origin,
                    count: count,
                    spacingX: gen.spacingX,
                    rotation: rot
                )
                parsedItems.append(contentsOf: fences)
            }
        }
        
        return MapBlueprint(
            groundSize: level.groundSize,
            oceanGridHeight: level.oceanGridHeight,
            beachGridHeight: level.beachGridHeight,
            roads: level.roads,
            items: parsedItems
        )
    } catch {
        fatalError("Failed to decode rawLevelDataJSON: \(error)")
    }
}

let worldMap = parseWorldMap()

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
