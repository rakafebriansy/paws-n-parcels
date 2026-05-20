    //
    //  PackageLetter.swift
    //  paws-n-parcels
    //
    //  Created by Felicia Joshlyn Purnomo on 07/05/26.
    //

    import Foundation
    import FoundationModels

    @Generable
    struct PackageLetter : Codable{
        let sender: String
        let recipient: String
        let messageBody: String
    }

    @Generable
    struct LetterBatch {
        @Guide(description: "A list of 5 unique letters", .count(5))
        let letters: [PackageLetter]
    }
