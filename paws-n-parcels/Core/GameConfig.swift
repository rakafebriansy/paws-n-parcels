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
    
    static let gridSize: CGFloat = 100.0
    static let worldSize: CGSize = CGSize(width: 3000, height: 3000)
    static let interactionRadius: CGFloat = 150.0
    static var interactionRadiusSquared: CGFloat {
        return interactionRadius * interactionRadius
    }
    
    static let maxRequests = 5
    
    static let playerSpeedMultiplier: CGFloat = 2.5
}

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
