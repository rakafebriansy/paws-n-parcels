//
//  DeliveryComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit

class DeliveryComponent: GKComponent {
    var activeRequest: Request?
    
    var isHoldingPackage: Bool { activeRequest != nil }
}
