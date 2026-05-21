//
//  ItemBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 11/05/26.
//

import Foundation
import SwiftUI

enum ItemType: Codable {
    case house
    case pond(size: CGSize)
    case tree
    case fence
    case decoration

    enum CodingKeys: String, CodingKey {
        case type
        case width
        case height
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeStr = try container.decode(String.self, forKey: .type)
        switch typeStr {
        case "house":
            self = .house
        case "tree":
            self = .tree
        case "fence":
            self = .fence
        case "decoration":
            self = .decoration
        case "pond":
            let width = try container.decode(CGFloat.self, forKey: .width)
            let height = try container.decode(CGFloat.self, forKey: .height)
            self = .pond(size: CGSize(width: width, height: height))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .house:
            try container.encode("house", forKey: .type)
        case .tree:
            try container.encode("tree", forKey: .type)
        case .fence:
            try container.encode("fence", forKey: .type)
        case .decoration:
            try container.encode("decoration", forKey: .type)
        case .pond(let size):
            try container.encode("pond", forKey: .type)
            try container.encode(size.width, forKey: .width)
            try container.encode(size.height, forKey: .height)
        }
    }
}

struct ItemBlueprint: Codable {
    let type: ItemType
    let pos: CGPoint
    var rotation: CGFloat = 0
    var characterName: String? = nil
    var assetName: String? = nil

    enum CodingKeys: String, CodingKey {
        case type
        case pos
        case rotation
        case characterName
        case assetName
    }

    init(type: ItemType, pos: CGPoint, rotation: CGFloat = 0, characterName: String? = nil, assetName: String? = nil) {
        self.type = type
        self.pos = pos
        self.rotation = rotation
        self.characterName = characterName
        self.assetName = assetName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ItemType.self, forKey: .type)
        self.pos = try container.decode(CGPoint.self, forKey: .pos)
        self.rotation = try container.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0.0
        self.characterName = try container.decodeIfPresent(String.self, forKey: .characterName)
        self.assetName = try container.decodeIfPresent(String.self, forKey: .assetName)
    }
}

extension ItemBlueprint {
    func scenePosition() -> CGPoint {
        let width: CGFloat
        let height: CGFloat
        let grid = GameConfig.gridSize
        
        switch type {
        case .house:
            width = 2
            height = 2
        case .pond(size: let size):
            width = size.width
            height = size.height
        case .tree:
            width = 1
            height = 1
        case .fence:
            width = 1
            height = 0.5
        case .decoration:
            width = 1
            height = 1
        }
        
        let exactX = (pos.x * grid) + ((width * grid) / 2)
        let exactY = (pos.y * grid) + ((height * grid) / 2)
        
        return CGPoint(x: exactX, y: exactY)
    }
    
    static func generateForest(
        origin: CGPoint,
        columns: Int,
        rows: Int,
        spacingX: CGFloat,
        spacingY: CGFloat,
        staggerOffsetX: CGFloat
    ) -> [ItemBlueprint] {
        var trees: [ItemBlueprint] = []
        
        for row in 0..<rows {
            let currentY = origin.y + (CGFloat(row) * spacingY)
            
            let isOddRow = (row % 2 != 0)
            let currentOffset = isOddRow ? staggerOffsetX : 0
            
            for col in 0..<columns {
                let currentX = origin.x + (CGFloat(col) * spacingX) + currentOffset
                trees.append(ItemBlueprint(type: .tree, pos: CGPoint(x: currentX, y: currentY)))
            }
        }
        
        return trees
    }
    
    static func generateFence(
        origin: CGPoint,
        count: Int,
        spacingX: CGFloat,
        rotation: CGFloat = 0
    ) -> [ItemBlueprint] {
        var fences: [ItemBlueprint] = []
        
        for col in 0..<count {
            let currentX = origin.x + (CGFloat(col) * spacingX)
            fences.append(ItemBlueprint(type: .fence, pos: CGPoint(x: currentX, y: origin.y), rotation: rotation))
        }
        
        return fences
    }
}
