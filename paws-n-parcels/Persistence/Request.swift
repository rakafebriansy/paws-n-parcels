//
//  Request.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import SwiftData
import Foundation

@Model
class Request {
    @Attribute(.unique) var id: UUID
    var isCompleted: Bool
    var sender: AnimalFriend
    var receiver: AnimalFriend
    var letter: PackageLetter
    
    var timestampCompleted: Date
    
    init(id: UUID = UUID(), sender: AnimalFriend, receiver: AnimalFriend, letter: PackageLetter, isCompleted: Bool = false, timestampCompleted: Date = Date()) {
        self.id = id
        self.sender = sender
        self.receiver = receiver
        self.letter = letter
        self.isCompleted = isCompleted
        self.timestampCompleted = timestampCompleted
    }
}
