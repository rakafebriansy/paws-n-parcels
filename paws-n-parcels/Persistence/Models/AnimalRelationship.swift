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

extension AnimalRelationship {
    func involves(_ name1: String, and name2: String) -> Bool {
        return (friendOne.name == name1 && friendTwo.name == name2) ||
               (friendOne.name == name2 && friendTwo.name == name1)
    }
    
    func partner(of characterName: String) -> String? {
        if friendOne.name == characterName { return friendTwo.name }
        if friendTwo.name == characterName { return friendOne.name }
        return nil
    }
}
