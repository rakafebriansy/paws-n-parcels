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
        // FIX: LanguageModelSession() is not async or throwing
        self.session = LanguageModelSession()
    }

    func generateBatch(item: String, from: String, to: String, level: Int) async -> [PackageLetter] {
        guard let session = session else { return [] }

        let tone: String
        switch level {
        case 0: tone = "polite and formal"
        case 1: tone = "polite and friendly"
        case 2: tone = "friendly and getting to know each other better"
        case 3: tone = "friendly and very close"
        case 4: tone = "very close to each other and very endearing"
        default: tone = "neutral"
        }

        let prompt = "Write 5 short letters from \(from) to \(to) about sending a \(item). Tone: \(tone)."

        do {
            // FIX: Use .respond(to:generating:)
            // The result is a Response object; the data is in .content
            let response = try await session.respond(to: prompt, generating: LetterBatch.self)
            
            return response.content.letters
        } catch {
            print("AI Generation Error: \(error)")
            return []
        }
    }
}
