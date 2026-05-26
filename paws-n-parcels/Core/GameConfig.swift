//
//  GameConfig.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import CoreGraphics

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let obstacle: UInt32 = 0b10 
}

struct GameConfig {
    static var showDebug: Bool = false
    
    static let loadingMessages: [String] = [
        "Packing parcels with love 📦🐾",
        "Tying ribbons on boxes 🎀🐕",
        "Filling up the delivery bag 🎒🦴",
        "Stamping letters 💌🐾"
    ]
    
    static let fontRegular: String = "ComicRelief-Regular"
    static let fontBold: String = "ComicRelief-Bold"
    
    static let deliveryRewardPoints: Int = 1
    
    static let pointsForAcquaintance: Int = 1
    static let pointsForFriend: Int = 2
    static let pointsForCloseFriend: Int = 3
    static let pointsForBestFriend: Int = 4
    
    static let maxRequests = 5
    static let playerSpeedMultiplier: CGFloat = 1
    
    /// - Rightward (3): 0
    /// - Upward (12): .pi / 2
    /// - Leftward (9): .pi
    /// - Downward (6): -.pi / 2
    static let arrowAssetDirection: CGFloat = .pi / 2
    
    static let cameraScale: CGFloat = 1
    static let gridSize: CGFloat = 100.0
    static let interactionRadius: CGFloat = 150.0
    static var interactionRadiusSquared: CGFloat {
        return interactionRadius * interactionRadius
    }
    static let requestIndicatorSize = CGSize(width: 120, height: 120)
    static let requestIndicatorAnimalFaceSize = CGSize(width: 60, height: 60)
    static let requestIndicatorExclamationSize = CGSize(width: 35, height: 35)
    static let worldSize: CGSize = CGSize(width: 3000, height: 3000)
    
    static let alertDisplayDuration: TimeInterval = 1.5
    static let newRequestSpawnDelay: Int = 5
    
    static let playerInitialPosition = CGPoint(x: 400, y: 400)
    static let playerPhysicsRadius: CGFloat = 14
    static let playerZPosition: CGFloat = 5
    
    static let playerFrontSize = CGSize(width: 46, height: 67)
    static let playerUpSize = CGSize(width: 46, height: 95)
    static let playerHorizontalSize = CGSize(width: 80, height: 64)
    
    static let playerWalkFrameDuration: TimeInterval = 0.16
    
    static let playerCarryingTransitionDuration: TimeInterval = 0.1
    static let playerCarryingTransitionScale: CGFloat = 0.8
    static let playerCarryingTransitionAlpha: CGFloat = 0.4
    
    static let playerWalkVerticalSquash = (x: CGFloat(1.05), y: CGFloat(0.95))
    static let playerWalkVerticalStretch = (x: CGFloat(0.95), y: CGFloat(1.05))
    static let playerWalkHorizontalSquash = (x: CGFloat(1.08), y: CGFloat(0.92))
    static let playerWalkHorizontalStretch = (x: CGFloat(0.92), y: CGFloat(1.08))
    static let playerWalkBounceDuration: TimeInterval = 0.16
    
    static let playerIdleVerticalSquash = (x: CGFloat(1.02), y: CGFloat(0.98))
    static let playerIdleVerticalStretch = (x: CGFloat(0.98), y: CGFloat(1.02))
    static let playerIdleHorizontalSquash = (x: CGFloat(1.04), y: CGFloat(0.96))
    static let playerIdleHorizontalStretch = (x: CGFloat(0.96), y: CGFloat(1.04))
    static let playerIdleBreatheDuration: TimeInterval = 0.8
    
    static let playerInteractionPulseUp: CGFloat = 1.15
    static let playerInteractionPulseDown: CGFloat = 1.0
    static let playerInteractionPulseUpDuration: TimeInterval = 0.1
    static let playerInteractionPulseDownDuration: TimeInterval = 0.1
}
