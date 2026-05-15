//
//  AnimalFriendRelationship.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class AnimalFriendRelationship {
    @Attribute(.unique) var id: UUID = UUID()
    var friendshipPoints: Int = 0
     var friendshipLevel: Int = 0
    
    var friendOneId: UUID
    var friendTwoId: UUID
    
    init(friendOneId: UUID, friendTwoId: UUID) {
        self.friendOneId = friendOneId
        self.friendTwoId = friendTwoId
    }
    
//    var coinMultiplier: Double {
//        return 1.0 + (Double(friendshipLevel) * 0.1)
//    }
}
