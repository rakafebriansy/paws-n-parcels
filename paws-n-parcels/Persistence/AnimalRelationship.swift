//
//  AnimalFriendRelationship.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class AnimalRelationship {
    var friendOneName: String
    var friendTwoName: String
    var friendshipLevel: Int
    var friendshipPoint: Int = 0
    
    init(friendOneName: String, friendTwoName: String, friendshipLevel: Int) {
        self.friendOneName = friendOneName
        self.friendTwoName = friendTwoName
        self.friendshipLevel = friendshipLevel
    }
}
