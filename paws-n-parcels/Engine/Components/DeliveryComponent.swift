//
//  DeliveryComponent.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import GameplayKit

class DeliveryComponent: GKComponent {
    var letterBuffer: [PackageLetter] = []
    var isRefilling = false
    
    // Core Logic: Get a letter and check if we need more
    func popLetter(item: String, from: String, to: String, level: Int) -> PackageLetter? {
        guard !letterBuffer.isEmpty else { return nil }
        
        let letter = letterBuffer.removeFirst()

        return letter
    }
    
    private func refillBuffer(item: String, from: String, to: String, level: Int) {
        isRefilling = true
        Task { [weak self] in
            let newLetter = await AIService.shared.generateSingleLetter(from: from, to: to, level: level)
            if let letter = newLetter {
                self?.letterBuffer.append(letter)
            }
            self?.isRefilling = false
            print("Buffer refilled. Current count: \(self?.letterBuffer.count ?? 0)")
        }
    }
    
}
