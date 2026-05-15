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
    var senderId: UUID
    var receiverId: UUID
    var letter: PackageLetter
    
    var timestampCompleted: Date
    
    init(id: UUID = UUID(), senderId: UUID, receiverId: UUID, letter: PackageLetter, isCompleted: Bool = false, timestampCompleted: Date = Date()) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.letter = letter
        self.isCompleted = isCompleted
        self.timestampCompleted = timestampCompleted
    }
}
