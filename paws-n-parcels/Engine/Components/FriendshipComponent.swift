//
//  FriendshipComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit

class FriendshipComponent: GKComponent {
    var level: Int = 0
    //from 0 to 4
    
    /// when leveling up
    func increaseBond() {
        if level < 4 { level += 1 }
    }
}
