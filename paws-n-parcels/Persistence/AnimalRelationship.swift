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
    var friendOne: Animal
    var friendTwo: Animal
    var friendshipLevel: Int = 0
    var friendshipPoint: Int = 0
    
    init(friendOne: Animal, friendTwo: Animal) {
        self.friendOne = friendOne
        self.friendTwo = friendTwo
    }
}
