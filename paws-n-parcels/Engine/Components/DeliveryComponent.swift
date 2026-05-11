//
//  DeliveryComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit

class DeliveryComponent: GKComponent {
    // Menyimpan request yang sedang dibawa, kalau nil berarti sedang tidak membawa paket
    var activeRequest: Requests? = nil
    var isHoldingPackage: Bool {
        return activeRequest != nil
    }
    
}
