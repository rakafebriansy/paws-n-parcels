//
//  AnimalFriend.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SwiftData

@Model
final class Animal {
    @Attribute(.unique) var name: String
    var assetName: String
    
    init(name: String, assetName: String) {
        self.name = name
        self.assetName = assetName
    }
}
