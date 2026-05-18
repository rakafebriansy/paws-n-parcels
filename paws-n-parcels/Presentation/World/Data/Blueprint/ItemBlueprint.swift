//
//  ItemBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 11/05/26.
//

import Foundation
import SwiftUI

enum ItemType {
    case house
    case pond(size: CGSize)
    case tree
    case fence
}

struct ItemBlueprint {
    let type: ItemType
    let pos: CGPoint
    var rotation: CGFloat = 0
    var characterName: String? = nil
    var assetName: String? = nil
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
