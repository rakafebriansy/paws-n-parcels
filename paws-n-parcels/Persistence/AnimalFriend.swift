//
//  AnimalFriend.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class AnimalFriend {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var assetName: String
    
    @Relationship(deleteRule: .cascade)
    var relationships: [AnimalFriendRelationship] = []
    
    init(id: UUID = UUID(), name: String, assetName: String) {
        self.name = name
        self.assetName = assetName
    }
}
