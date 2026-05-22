//
//  MapBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SwiftUI
import SpriteKit
import GameplayKit

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
  "groundSize": [4000, 4000],
  "oceanGridHeight": 3,
  "beachGridHeight": 2,
  "roads": [
     [[3, 6], [3, 30]],
        [[8, 30], [3, 30]],
        [[8, 10], [8, 21]],
        [[3, 10], [35, 10]],
        [[8, 36], [8, 30]],
        [[29, 6], [24, 6]],
        [[31, 9], [31, 6]],
        [[31, 9], [31, 34]]
  ],
  "items": [
  {"type": {"type": "house"}, "pos": [1, 6], "assetName": "house_1"},
      {"type": {"type": "house"}, "pos": [25, 7], "assetName": "house_2"},
      {"type": {"type": "house"}, "pos": [35, 11], "assetName": "house_2"},
      {"type": {"type": "house"}, "pos": [35, 7], "assetName": "house_2"},
      {"type": {"type": "house"}, "pos": [6, 35], "assetName": "house_3"},
      {"type": {"type": "house"}, "pos": [8, 37], "assetName": "house_3"},
      {"type": {"type": "house"}, "pos": [6, 20], "assetName": "house_4"},
      {"type": {"type": "house"}, "pos": [8, 22], "assetName": "house_4"},
      {"type": {"type": "house"}, "pos": [10, 20], "assetName": "house_4"},
      {"type": {"type": "house"}, "pos": [31, 35], "assetName": "house_5"},
      {"type": {"type": "house"}, "pos": [33, 33], "assetName": "house_5"},
    {"type": {"type": "pond", "width": 8, "height": 6}, "pos": [22.6, 18.0]},

    {"type": {"type": "decoration"}, "pos": [0.4, 4.2], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [0.6, 13.4], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [0.5, 4.8], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [0.65, 4.55], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [0.8, 4.3], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [0.8, 13.7], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [1.0, 17.5], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [1.1, 4.8], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [1.0, 13.5], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [1.2, 13.7], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [1.2, 17.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [1.4, 17.5], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [2.0, 19.3], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [2.3, 13.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [2.3, 5.1], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [2.3, 19.0], "assetName": "big_rock_2"},
    {"type": {"type": "decoration"}, "pos": [2.6, 13.6], "assetName": "rock_1"},
    
    {"type": {"type": "decoration"}, "pos": [33.3, 6.2], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [33.3, 6.7], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [33.5, 6.5], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [33.7, 6.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [33.7, 6.3], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [34.0, 8.4], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [34.2, 8.7], "assetName": "sunflower"},
    
    {"type": {"type": "decoration"}, "pos": [36.0, 5.2], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [36.0, 25.0], "assetName": "lavender"},
   
    {"type": {"type": "decoration"}, "pos": [37.8, 5.4], "assetName": "big_rock_3"},
    {"type": {"type": "decoration"}, "pos": [37.2, 6.0], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [37.6, 5.2], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [38.2, 11.2], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [38.8, 4.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [38.8, 11.6], "assetName": "big_rock_2"},
    {"type": {"type": "decoration"}, "pos": [39.0, 4.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [39.3, 11.3], "assetName": "rose"}
  ],
  "generators": [
     {"type": "forest", "origin": [-0.5, 8], "columns": 1, "rows": 38, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [-0.5, 39], "columns": 41, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [10.5, 38.5], "columns": 25, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [-0.5, 38.5], "columns": 17, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [11, 38], "columns": 23, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [12.5, 37.5], "columns": 19, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [13, 37], "columns": 17, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [13.5, 36.5], "columns": 16, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [5, 6], "columns": 18, "rows": 5, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [-0.5, 32], "columns": 5, "rows": 15, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [-0.5, 26], "columns": 2, "rows": 28, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [34, 14], "columns": 6, "rows": 34, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [13, 14], "columns": 7, "rows": 10, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "fence", "origin": [0, 3.2], "count": 3, "spacingX": 1.0},
    {"type": "fence", "origin": [22.5, 17.0], "count": 8, "spacingX": 1.0},
    {"type": "fence", "origin": [5, 3.2], "count": 18, "spacingX": 1.0},
    {"type": "fence", "origin": [25.5, 3.2], "count": 25, "spacingX": 1.0},
    {"type": "fence", "origin": [5.0, 10.8], "count": 3, "spacingX": 1.0},
    {"type": "fence", "origin": [12.2, 10.8], "count": 7, "spacingX": 1.0},
    {"type": "fence", "origin": [21.0, 10.8], "count": 10, "spacingX": 1.0}
  ]
}
"""

///rect dalam grid-space yang tidak boleh diisi asset decorations
private struct ExclusionRect {
    let minX: CGFloat
    let maxX: CGFloat
    let minY: CGFloat
    let maxY: CGFloat
    func contains(_ p: CGPoint) -> Bool {
        p.x >= minX && p.x <= maxX && p.y >= minY && p.y <= maxY
    }
}

///kumpulan exclusion rect untuk jalan dan area rumah
private let sharedExclusionZones: [ExclusionRect] = [
    // ── ROADS (Jalanan) ──
    ExclusionRect(minX: 2.2,  maxX: 3.8,  minY: 5.2,  maxY: 30.8),  // Vertikal kiri
    ExclusionRect(minX: 2.2,  maxX: 8.8,  minY: 29.2, maxY: 30.8),  // Horizontal atas-kiri
    ExclusionRect(minX: 7.2,  maxX: 8.8,  minY: 9.2,  maxY: 21.8),  // Vertikal tengah-kiri
    ExclusionRect(minX: 2.2,  maxX: 35.8, minY: 9.2,  maxY: 10.8),  // Horizontal utama panjang
    ExclusionRect(minX: 7.2,  maxX: 8.8,  minY: 29.2, maxY: 36.8),  // Vertikal ujung kiri atas
    ExclusionRect(minX: 23.2, maxX: 29.8, minY: 5.2,  maxY: 6.8),   // Horizontal kanan bawah
    ExclusionRect(minX: 30.2, maxX: 31.8, minY: 5.2,  maxY: 9.8),   // Vertikal kecil kanan bawah
    ExclusionRect(minX: 30.2, maxX: 31.8, minY: 8.2,  maxY: 34.8),  // Vertikal utama kanan
    
    // ── HOUSES (Dari JSON Items) ──
    ExclusionRect(minX: 0.5,  maxX: 2.5,  minY: 5.5,  maxY: 7.5),
    ExclusionRect(minX: 24.5, maxX: 26.5, minY: 6.5,  maxY: 8.5),
    ExclusionRect(minX: 34.5, maxX: 36.5, minY: 10.5, maxY: 12.5),
    ExclusionRect(minX: 34.5, maxX: 36.5, minY: 6.5,  maxY: 8.5),
    ExclusionRect(minX: 5.5,  maxX: 7.5,  minY: 34.5, maxY: 36.5),
    ExclusionRect(minX: 7.5,  maxX: 9.5,  minY: 36.5, maxY: 38.5),
    ExclusionRect(minX: 5.5,  maxX: 7.5,  minY: 19.5, maxY: 21.5),
    ExclusionRect(minX: 7.5,  maxX: 9.5,  minY: 21.5, maxY: 23.5),
    ExclusionRect(minX: 9.5,  maxX: 11.5, minY: 19.5, maxY: 21.5),
    ExclusionRect(minX: 30.5, maxX: 32.5, minY: 34.5, maxY: 36.5),
    ExclusionRect(minX: 32.5, maxX: 34.5, minY: 32.5, maxY: 34.5),
    
    // ── HOUSES (Dari Character Registry) ──
    ExclusionRect(minX: 28.5, maxX: 30.5, minY: 6.5,  maxY: 8.5),
    ExclusionRect(minX: 26.5, maxX: 28.5, minY: 6.5,  maxY: 8.5),
    ExclusionRect(minX: 36.5, maxX: 38.5, minY: 8.5,  maxY: 10.5),
    ExclusionRect(minX: 9.5,  maxX: 11.5, minY: 34.5, maxY: 36.5),
    ExclusionRect(minX: 28.5, maxX: 30.5, minY: 32.5, maxY: 34.5),
    
    // ── POND (Kolam) ──
    // Origin [22.6, 18.0], ukuran 8x6 grid
    ExclusionRect(minX: 22.1, maxX: 31.1, minY: 17.5, maxY: 24.5),
    
    // ── FENCES (Pagar) ──
        ExclusionRect(minX: -0.5, maxX: 3.5,  minY: 2.7, maxY: 4.2), // origin [0, 3.2], count 3
        ExclusionRect(minX: 22.0, maxX: 31.0, minY: 16.5, maxY: 18.0), // origin [22.5, 17.0], count 8
        ExclusionRect(minX: 4.5,  maxX: 23.5, minY: 2.7, maxY: 4.2), // origin [5, 3.2], count 18
        ExclusionRect(minX: 25.0, maxX: 51.0, minY: 2.7, maxY: 4.2), // origin [25.5, 3.2], count 25
        ExclusionRect(minX: 4.5,  maxX: 8.5,  minY: 10.3, maxY: 11.8), // origin [5.0, 10.8], count 3
        ExclusionRect(minX: 11.7, maxX: 14.7, minY: 10.3, maxY: 11.8), // origin [12.2, 10.8], count 2
        ExclusionRect(minX: 15.5, maxX: 21.5, minY: 10.3, maxY: 11.8) // origin [16.0, 10.8], count 5
]

/// Scatter dekorasi secara padat dalam sebuah bounding rect,
/// menghindari exclusion zones dan titik yang sudah terisi.
///
/// - Parameters:
///   - minX/maxX/minY/maxY : batas area populasi (grid units)
///   - count               : jumlah dekorasi yang ingin ditempatkan
///   - minDist             : jarak minimum antar dekorasi (grid units)
///   - assets              : array nama asset yang bisa dipilih
///   - weights             : bobot pemilihan asset (harus sama panjang dengan `assets`).
///   Jika nil, semua asset dipilih dengan probabilitas sama.
///   - seed                : seed untuk GKLinearCongruentialRandomSource
///   - parsedItems         : array yang akan diisi
func scatterDense(
    minX: CGFloat, maxX: CGFloat,
    minY: CGFloat, maxY: CGFloat,
    count: Int,
    minDist: CGFloat = 0.20,
    assets: [String],
    weights: [Int]? = nil,
    seed: UInt64 = 12345,
    parsedItems: inout [ItemBlueprint]
) {
    var weightedPool: [String] = []
    if let w = weights, w.count == assets.count {
        for (asset, weight) in zip(assets, w) {
            weightedPool.append(contentsOf: repeatElement(asset, count: weight))
        }
    } else {
        weightedPool = assets
    }

    var occupiedPoints: [CGPoint] = []
    let rng = GKLinearCongruentialRandomSource(seed: seed)

    for _ in 0..<count {
        var placed: CGPoint? = nil

        for _ in 0..<200 {
            let rx = minX + CGFloat(rng.nextUniform()) * (maxX - minX)
            let ry = minY + CGFloat(rng.nextUniform()) * (maxY - minY)
            let candidate = CGPoint(x: rx, y: ry)

            let blocked = sharedExclusionZones.contains { $0.contains(candidate) }
            if blocked { continue }

            let tooClose = occupiedPoints.contains {
                hypot($0.x - candidate.x, $0.y - candidate.y) < minDist
            }
            if tooClose { continue }

            placed = candidate
            break
        }

        guard let pos = placed else { continue }
        occupiedPoints.append(pos)

        let idx = Int(abs(rng.nextInt())) % weightedPool.count
        let chosenAsset = weightedPool[idx]
        parsedItems.append(ItemBlueprint(type: .decoration, pos: pos, assetName: chosenAsset))
    }
}
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
        
        let flowerAssets = ["sunflower", "rose", "lavender"]
                let rockAssets = ["big_rock_2", "big_rock_3", "big_rock_4", "rock_1", "rock_2", "rock_3"]
                let allAssets = flowerAssets + rockAssets
               
        //tengah atas
        scatterDense(
            minX: 12.5, maxX: 27.5,
            minY: 33.0, maxY: 35.9,
            count: 400,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2"],
            weights: [5, 5, 5, 1, 1],
            seed: 11111,
            parsedItems: &parsedItems
        )
        
        //tengah tengah
        scatterDense(
            minX: 10.5, maxX: 27.5,
            minY: 28.0, maxY: 33.5,
            count: 630,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
               
        //tengah bawah
        scatterDense(
            minX: 5.0, maxX: 30.0,
            minY: 23.0, maxY: 28.5,
            count: 850,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        
      
        //tengah bawah sebelah pond
        scatterDense(
            minX: 11.5, maxX: 21.0,
            minY: 12.0, maxY: 23.5,
            count: 100,
            minDist: 0.2,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        scatterDense(
            minX: 20.5, maxX: 30.0,
            minY: 12.0, maxY: 16.5,
            count: 80,
            minDist: 0.2,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        
        //tengah big area
        scatterDense(
            minX: 12.5, maxX: 27.5,
            minY: 23.0, maxY: 34.0,
            count: 400,
            minDist: 0.2,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        
          //kiri seberang jalan
          scatterDense(
              minX: 4.5, maxX: 8.0,
              minY: 11.0, maxY: 18.5,
              count: 50,
              minDist: 0.2,
              assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
              weights: [4, 4, 4, 1, 1, 1],
              seed: 22222,
              parsedItems: &parsedItems
          )
        
        //pojok kanan atas
        scatterDense(
            minX: 35.0, maxX: 39.5,
            minY: 32.0, maxY: 38.0,
            count: 190,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3", "big_rock_2", "big_rock_3"],
            weights: [3, 3, 3, 3, 3, 2, 1, 1],
            seed: 33333,
            parsedItems: &parsedItems
        )
        
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
