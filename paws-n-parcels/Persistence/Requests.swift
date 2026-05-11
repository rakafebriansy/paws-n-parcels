//
//  Requests.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 08/05/26.
//

import SwiftData
import Foundation

@Model
class Requests {
    @Attribute(.unique) var id: UUID
    var isCompleted: Bool
    var sender: AnimalFriend
    var receiver: AnimalFriend
    
    var timestampCompleted: Date
    
    init(id: UUID = UUID(), sender: AnimalFriend, receiver: AnimalFriend, isCompleted: Bool = false, timestampCompleted: Date = Date()) {
        self.id = id
        self.sender = sender
        self.receiver = receiver
        self.isCompleted = isCompleted
        self.timestampCompleted = timestampCompleted
    }
}
