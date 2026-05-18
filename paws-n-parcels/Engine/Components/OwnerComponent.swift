//
//  OwnerComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra.
//

import GameplayKit

class OwnerComponent: GKComponent {
    let characterName: String
    
    init(characterName: String) {
        self.characterName = characterName
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
