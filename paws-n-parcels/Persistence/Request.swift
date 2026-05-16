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
    var senderName: String
    var receiverName: String
    var isCompleted: Bool
    var letter: PackageLetter
    
    init(senderName: String, receiverName: String, letter: PackageLetter, isCompleted: Bool = false) {
        self.senderName = senderName
        self.receiverName = receiverName
        self.letter = letter
        self.isCompleted = isCompleted
    }
}
