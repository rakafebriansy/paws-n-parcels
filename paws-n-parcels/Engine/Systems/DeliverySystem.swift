//
//  DeliverySystem.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

class DeliverySystem: GKComponentSystem<DeliveryComponent> {

    // Call this when the player successfully reaches a delivery goal
    func completeDelivery(
        for npc: GKEntity,
        itemName: String,
        playerName: String
    ) {
        guard let delivery = npc.component(ofType: DeliveryComponent.self),
            let friendship = npc.component(ofType: FriendshipComponent.self)
        else { return }

        // 1. Pop the letter from the buffer
        // refill waktu sisa 5
        if let letter = delivery.popLetter(
            item: itemName,
            from: "NPC_Name",  // You can get this from an IdentityComponent if you have one
            to: "NPC Name",
        ) {
            // 2. Send to UI Presentation layer
            print("Showing Letter: \(letter.messageBody)")
            // UIController.shared.showLetter(letter)
        }
    }
}
