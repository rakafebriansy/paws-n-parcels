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
    var sender: Animal
    var receiver: Animal
    var isCompleted: Bool
    var letter: PackageLetter
    
    init(sender: Animal, receiver: Animal, letter: PackageLetter, isCompleted: Bool = false) {
        self.sender = sender
        self.receiver = receiver
        self.letter = letter
        self.isCompleted = isCompleted
    }
}
