//
//  Collectible.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class Collectible {
    var id: UUID = UUID()
    var name: String
    var isUnlocked: Bool = false
//    var dateUnlocked: Date?
    
    var player: PlayerProfile?
    
    init(name: String) {
        self.name = name
    }
}
