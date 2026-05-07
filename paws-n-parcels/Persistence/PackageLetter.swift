//
//  PackageLetter.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 07/05/26.
//

import Foundation
import FoundationModels

@Generable
struct PackageLetter {
    let sender: String
    let recipient: String
    let itemSent: String
    let messageBody: String
}

@Generable
struct LetterBatch {
    // FIX: Add the 'description:' label to the string
    @Guide(description: "A list of 5 unique letters", .count(5))
    let letters: [PackageLetter]
}
