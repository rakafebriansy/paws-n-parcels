//
//  GameConfig.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation

struct GameConfig {
    static let deliveryRewardPoints: Int = 100
    static let pointsForAcquaintance: Int = 100
    static let pointsForFriend: Int = 300
    static let pointsForCloseFriend: Int = 600
    static let pointsForBestFriend: Int = 1000
}

enum FriendshipLevel: String {
    case stranger = "Stranger"
    case acquaintance = "Acquaintance"
    case friend = "Friend"
    case closeFriend = "Close Friend"
    case bestFriend = "Best Friend"

    static func getLevel(from points: Int) -> FriendshipLevel {
        if points < GameConfig.pointsForAcquaintance {return .stranger}
        if points < GameConfig.pointsForFriend {return .acquaintance}
        if points < GameConfig.pointsForCloseFriend {return .friend}
        if points < GameConfig.pointsForBestFriend {return .closeFriend}
        return .bestFriend
    }
}
