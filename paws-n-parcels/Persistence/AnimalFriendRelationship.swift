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
    var id: UUID = UUID()
    var friendshipPoints: Int = 0
    var friendshipLevel: Int = 0
    
    var friendOne: AnimalFriend?
    var friendTwo: AnimalFriend?
    
    init(friendOne: AnimalFriend, friendTwo: AnimalFriend) {
        self.friendOne = friendOne
        self.friendTwo = friendTwo
    }
    
    var coinMultiplier: Double {
        return 1.0 + (Double(friendshipLevel) * 0.1)
    }
}
