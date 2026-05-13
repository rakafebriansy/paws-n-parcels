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
}

struct ItemBlueprint {
    let type: ItemType
    let pos: CGPoint
    var rotation: CGFloat = 0
}

extension ItemBlueprint {
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
}
