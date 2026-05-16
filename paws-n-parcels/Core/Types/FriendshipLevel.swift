//
//  FriendshipLevel.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 16/05/26.
//

import Foundation

enum FriendshipLevel: String {
    case stranger = "Stranger"
    case acquaintance = "Acquaintance"
    case friend = "Friend"
    case closeFriend = "Close Friend"
    case bestFriend = "Best Friend"

    var intValue: Int {
        switch self {
        case .stranger: return 0
        case .acquaintance: return 1
        case .friend: return 2
        case .closeFriend: return 3
        case .bestFriend: return 4
        }
    }

    static func getLevel(from points: Int) -> FriendshipLevel {
        if points < GameConfig.pointsForAcquaintance {return .stranger}
        if points < GameConfig.pointsForFriend {return .acquaintance}
        if points < GameConfig.pointsForCloseFriend {return .friend}
        if points < GameConfig.pointsForBestFriend {return .closeFriend}
        return .bestFriend
    }
}
