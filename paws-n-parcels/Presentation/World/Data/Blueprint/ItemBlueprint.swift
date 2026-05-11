//
//  ItemBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 11/05/26.
//

import Foundation
import SwiftUI

enum ItemType {
    case house(color: UIColor)
    case pond
}

struct ItemBlueprint {
    let type: ItemType
    let pos: CGPoint
    var rotation: CGFloat = 0
}
