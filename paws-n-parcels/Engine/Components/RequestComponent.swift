//
//  RequestComponent.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

import GameplayKit

class RequestComponent: GKComponent {
    let request: Request
    
    init(request: Request) {
        self.request = request
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
