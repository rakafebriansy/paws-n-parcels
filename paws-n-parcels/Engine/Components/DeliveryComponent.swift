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
        
        // REFILL TRIGGER: If we hit 5 left, start generating 5 more in the background
        if letterBuffer.count <= 5 && !isRefilling {
            refillBuffer(item: item, from: from, to: to, level: level)
        }
        
        return letter
    }
    
    private func refillBuffer(item: String, from: String, to: String, level: Int) {
        isRefilling = true
        Task {
            let newLetters = await AIService.shared.generateBatch(item: item, from: from, to: to, level: level)
            self.letterBuffer.append(contentsOf: newLetters)
            self.isRefilling = false
            print("Buffer refilled. Current count: \(self.letterBuffer.count)")
        }
    }
    
}
