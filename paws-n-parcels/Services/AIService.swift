//
//  AIService.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import FoundationModels

class AIService {
    static let shared = AIService()
    private var session: LanguageModelSession?

    init() {
        self.session = LanguageModelSession()
    }

    ///generate single letter with from, to, and level of relationship filled
    func generateSingleLetter(from: String, to: String, level: Int) async
        -> PackageLetter?
    {
        guard let session = session else { return nil }

        ///tone depending on the relationship level
        let tone: String
        switch level {
        case 0: tone = "polite and formal"
        case 1: tone = "polite and friendly"
        case 2: tone = "friendly and warm"
        case 3: tone = "affectionate and close"
        case 4: tone = "very endearing and deeply bonded"
        default: tone = "neutral"
        }

        // set the item and make the letter
        ///prompt for letter generation
        let prompt = """
            Pick one unique, cozy gift item (like a 'warm scarf', 'special pebble', or 'bag of chips', add more, be creative). 
            Write a short, heartfelt letter from \(from) to \(to) about sending this item. 
            Tone: \(tone).
            Ensure the 'itemSent' field matches the item mentioned in the letter.
            """

        //get the response for the letter that was generated
        do {
            // Because PackageLetter is Codable, the session can 'decode' the AI response
            let response = try await session.respond(
                to: prompt,
                generating: PackageLetter.self
            )

            // This is now a real PackageLetter object, not just a string!
            return response.content
        } catch {
            //print for log
            print("Generation Error: \(error)")
            return nil
        }
    }
}
