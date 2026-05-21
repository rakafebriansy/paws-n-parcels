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
    {"type": {"type": "pond", "width": 8, "height": 6}, "pos": [12.6, 11.9]},

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
    {"type": {"type": "decoration"}, "pos": [5.0, 18.2], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [5.2, 20.2], "assetName": "big_rock_3"},
    {"type": {"type": "decoration"}, "pos": [5.5, 18.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [5.9, 20.5], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [6.0, 18.2], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [6.3, 21.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [6.4, 18.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [6.8, 20.2], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [7.0, 21.0], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [7.2, 19.4], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [7.5, 20.6], "assetName": "lavender"},

    {"type": {"type": "decoration"}, "pos": [10.2, 18.1], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [10.8, 12.5], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [10.8, 13.0], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [10.8, 18.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [10.9, 19.2], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [11.0, 12.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [11.2, 22.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [11.4, 12.9], "assetName": "big_rock_2"},
    {"type": {"type": "decoration"}, "pos": [11.4, 18.0], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [11.5, 19.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [11.4, 12.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [11.8, 20.5], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [11.8, 22.8], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [12.0, 18.5], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [12.1, 19.1], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [12.2, 21.9], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [12.4, 20.9], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [12.4, 23.0], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [12.6, 18.1], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [12.7, 19.7], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [12.8, 22.1], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [12.8, 24.0], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [13.0, 20.4], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [13.0, 21.0], "assetName": "big_rock_2"},
    {"type": {"type": "decoration"}, "pos": [13.0, 23.2], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.2, 18.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [13.3, 19.2], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.3, 20.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [13.3, 22.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [13.4, 22.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.4, 24.3], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [13.5, 19.9], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.5, 21.9], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.6, 21.0], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [13.6, 23.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [13.8, 18.2], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [13.9, 19.8], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [13.9, 20.4], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [13.9, 22.4], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [14.0, 19.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.0, 21.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.0, 21.8], "assetName": "big_rock_4"},
    {"type": {"type": "decoration"}, "pos": [14.0, 24.5], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [14.1, 23.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [14.2, 20.5], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.2, 23.2], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.2, 24.1], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [14.3, 22.8], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.4, 18.7], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [14.5, 19.3], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [14.5, 24.8], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [14.65, 24.9], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [14.8, 21.0], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [14.8, 22.1], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [14.8, 23.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [14.8, 23.8], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [14.8, 25.0], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [15.0, 18.3], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.0, 24.4], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.1, 19.9], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.2, 24.65], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [15.4, 20.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.4, 22.9], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [15.4, 23.6], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.4, 24.9], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [15.5, 21.7], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.6, 18.8], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [15.7, 19.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [15.7, 22.4], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [15.8, 24.2], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [15.8, 25.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [16.0, 20.9], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [16.0, 23.5], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [16.0, 24.0], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [16.0, 24.9], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [16.2, 18.4], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [16.2, 21.5], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [16.2, 25.0], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [16.4, 25.4], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [16.6, 20.4], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [16.6, 23.0], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [16.6, 24.2], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [16.6, 24.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [16.8, 21.9], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [16.8, 23.7], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [16.8, 25.4], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [17.0, 24.9], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [17.4, 25.4], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [18.8, 18.5], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [19.0, 19.1], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [19.4, 18.5], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [19.8, 19.1], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [20.2, 18.6], "assetName": "rock_2"},

    {"type": {"type": "decoration"}, "pos": [23.3, 6.2], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [23.3, 6.7], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [23.5, 6.5], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [23.7, 6.6], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [23.7, 6.3], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [24.0, 8.4], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [24.2, 8.7], "assetName": "sunflower"},
    
    {"type": {"type": "decoration"}, "pos": [26.0, 5.2], "assetName": "rock_3"},
    {"type": {"type": "decoration"}, "pos": [26.0, 25.0], "assetName": "lavender"},
   
    {"type": {"type": "decoration"}, "pos": [27.8, 5.4], "assetName": "big_rock_3"},
    {"type": {"type": "decoration"}, "pos": [27.8, 27.1], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [27.0, 25.2], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [27.0, 26.0], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [27.2, 6.0], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [27.2, 26.2], "assetName": "rose"},
    {"type": {"type": "decoration"}, "pos": [27.4, 25.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [27.6, 5.2], "assetName": "rock_1"},
    {"type": {"type": "decoration"}, "pos": [27.6, 27.2], "assetName": "sunflower"},
    {"type": {"type": "decoration"}, "pos": [27.8, 26.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [28.2, 11.2], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [28.8, 4.4], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [28.4, 26.3], "assetName": "rock_2"},
    {"type": {"type": "decoration"}, "pos": [28.4, 27.0], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [28.8, 11.6], "assetName": "big_rock_2"},
    {"type": {"type": "decoration"}, "pos": [29.0, 4.6], "assetName": "lavender"},
    {"type": {"type": "decoration"}, "pos": [29.3, 11.3], "assetName": "rose"}
  ],
  "generators": [
     {"type": "forest", "origin": [0, 29], "columns": 30, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [10.5, 28.5], "columns": 15, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [0.5, 28.5], "columns": 7, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [11, 28], "columns": 13, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [12.5, 27.5], "columns": 9, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [13, 27], "columns": 7, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [13.5, 26.5], "columns": 6, "rows": 1, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
     {"type": "forest", "origin": [5, 6], "columns": 8, "rows": 5, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [0, 26], "columns": 5, "rows": 5, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [0, 22], "columns": 2, "rows": 8, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
        {"type": "forest", "origin": [24, 14], "columns": 6, "rows": 16, "spacingX": 1.0, "spacingY": 0.5, "staggerOffsetX": 0.5},
    {"type": "fence", "origin": [0, 3.2], "count": 3, "spacingX": 1.0},
    {"type": "fence", "origin": [5, 3.2], "count": 8, "spacingX": 1.0},
    {"type": "fence", "origin": [15.5, 3.2], "count": 15, "spacingX": 1.0},
    {"type": "fence", "origin": [5.0, 10.8], "count": 3, "spacingX": 1.0},
    {"type": "fence", "origin": [12.2, 10.8], "count": 2, "spacingX": 1.0},
    {"type": "fence", "origin": [16.0, 10.8], "count": 5, "spacingX": 1.0}
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
    // Roads (diberi padding ±0.8 grid agar dekorasi tidak mepet tepi jalan)
    ExclusionRect(minX: 2.2,  maxX: 3.8,  minY: 5.2,  maxY: 24.8),
    ExclusionRect(minX: 2.2,  maxX: 8.8,  minY: 23.2, maxY: 24.8),
    ExclusionRect(minX: 7.2,  maxX: 8.8,  minY: 9.2,  maxY: 16.8),
    ExclusionRect(minX: 2.2,  maxX: 25.8, minY: 9.2,  maxY: 10.8),
    ExclusionRect(minX: 7.2,  maxX: 8.8,  minY: 25.2, maxY: 26.8),
    ExclusionRect(minX: 13.2, maxX: 19.8, minY: 5.2,  maxY: 6.8),
    ExclusionRect(minX: 20.2, maxX: 21.8, minY: 5.2,  maxY: 9.8),
    ExclusionRect(minX: 20.2, maxX: 21.8, minY: 9.2,  maxY: 24.8),

    // Houses (2x2 grid masing-masing, padding ±0.5)
    ExclusionRect(minX: 0.5,  maxX: 3.5,  minY: 5.5,  maxY: 8.5),
    ExclusionRect(minX: 13.5, maxX: 17.5, minY: 6.5,  maxY: 9.5),
    ExclusionRect(minX: 23.5, maxX: 27.5, minY: 10.5, maxY: 13.5),
    ExclusionRect(minX: 23.5, maxX: 27.5, minY: 6.5,  maxY: 9.5),
    ExclusionRect(minX: 4.5,  maxX: 8.5,  minY: 24.5, maxY: 27.5),
    ExclusionRect(minX: 6.5,  maxX: 10.5, minY: 26.5, maxY: 29.5),
    ExclusionRect(minX: 4.5,  maxX: 8.5,  minY: 14.5, maxY: 17.5),
    ExclusionRect(minX: 6.5,  maxX: 10.5, minY: 16.5, maxY: 19.5),
    ExclusionRect(minX: 8.5,  maxX: 12.5, minY: 14.5, maxY: 17.5),
    ExclusionRect(minX: 19.5, maxX: 23.5, minY: 24.5, maxY: 27.5),
    ExclusionRect(minX: 21.5, maxX: 25.5, minY: 22.5, maxY: 25.5),

    // ── Pond (origin [12.6, 11.9], ukuran 8x6 grid) ──
    ExclusionRect(minX: 12.1, maxX: 21.1, minY: 11.4, maxY: 18.4),
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
///                           Jika nil, semua asset dipilih dengan probabilitas sama.
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
                
        scatterDense(
            minX: 12.5, maxX: 17.5,
            minY: 22.0, maxY: 25.9,
            count: 230,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2"],
            weights: [5, 5, 5, 1, 1],
            seed: 11111,
            parsedItems: &parsedItems
        )
                
        scatterDense(
            minX: 5.0, maxX: 20.0,
            minY: 16.0, maxY: 22.0,
            count: 450,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        
        scatterDense(
            minX: 10.0, maxX: 13.0,
            minY: 22.0, maxY: 23.5,
            count: 30,
            minDist: 0.18,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
        
        scatterDense(
            minX: 10.5, maxX: 20.0,
            minY: 12.0, maxY: 13.5,
            count: 80,
            minDist: 0.2,
            assets: ["sunflower", "rose", "lavender", "rock_1", "rock_2", "rock_3"],
            weights: [4, 4, 4, 1, 1, 1],
            seed: 22222,
            parsedItems: &parsedItems
        )
                
        scatterDense(
            minX: 25.0, maxX: 29.5,
            minY: 24.0, maxY: 28.0,
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
