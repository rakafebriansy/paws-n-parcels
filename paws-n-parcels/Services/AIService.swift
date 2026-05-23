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
        if #available(iOS 26.0, *) {
            self.session = LanguageModelSession()
        }
    }

    func generateSingleLetter(from: String, to: String, level: Int) async
        -> PackageLetter?
    {
        guard let session = session else { 
            return PackageLetter(
                sender: from,
                recipient: to,
                messageBody: "Hello \(to), here is a special package for you! Best, \(from)."
            )
        }

        let tone: String
        switch level {
        case 0: tone = "polite and formal"
        case 1: tone = "polite and friendly"
        case 2: tone = "friendly and warm"
        case 3: tone = "affectionate and close"
        case 4: tone = "very endearing and deeply bonded"
        default: tone = "neutral"
        }

        let prompt = """
            Pick one unique, cozy gift item (like a 'warm scarf', 'special pebble', or 'bag of chips', add more, be creative). 
            Write a short, heartfelt letter from \(from) to \(to) about sending this item. 
            Tone: \(tone).
            Keep the letter brief, strictly under 310 characters, and ideally shorter.
            Ensure the 'itemSent' field matches the item mentioned in the letter.
            """

        do {
            let response = try await session.respond(
                to: prompt,
                generating: PackageLetter.self
            )

            return response.content
        } catch {
            print("Generation Error: \(error)")
            return PackageLetter(
                sender: from,
                recipient: to,
                messageBody: "Hello \(to), here is a special package for you! Best, \(from)."
            )
        }
    }
}
