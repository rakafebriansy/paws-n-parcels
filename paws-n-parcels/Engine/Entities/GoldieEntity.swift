//
//  GoldieEntity.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit

final class GoldieEntity: GKEntity {
    override init() {
        super.init()
        
        let deliveryComp = DeliveryComponent()
        
        self.addComponent(deliveryComp)
        // self.addComponent(PositionComponent(x: 0, y: 0))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
