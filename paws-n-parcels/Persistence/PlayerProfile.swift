//
//  PlayerProfile.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var totalDeliveries: Int = 0
    var totalPoints: Int = 0
    var positionX: Double
    var positionY: Double

    @Relationship(deleteRule: .cascade)
    var collectibles: [Collectible] = []
    
    init(
        positionX: Double = 0,
        positionY: Double = 0
    ) {
        self.positionX = positionX
        self.positionY = positionY
    }
}
