//
//  AITestView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 07/05/26.
//

import FoundationModels
import SwiftUI

struct AITestView: View {
    @State private var generatedLetters: [PackageLetter] = []
    @State private var isLoading = false
    @State private var statusMessage = "Press the button to generate a letter"

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Letter is writing...")
                        .padding()
                }

                List(generatedLetters, id: \.messageBody) { letter in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To: \(letter.recipient)")
                            .font(.caption)
                            .bold()
                        Text(letter.messageBody)
                            .font(.body)
                        Text("From: \(letter.sender)")
                            .font(.caption)
                            .italic()
                    }
                    .padding(.vertical, 4)
                }

                Button(action: testGeneration) {
                    Text("Generate Letter")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isLoading)

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
            .navigationTitle("AI Test Lab")
        }
    }

    func testGeneration() {
        isLoading = true
        statusMessage = "Generating Letters..."

        // 1. Define your test cases in an array
        let scenarios = [
            (from: "Gab",   to: "Somi",  level: 0),
            (from: "Somi",  to: "Josan", level: 1),
            (from: "Raka",  to: "Josan", level: 2),
            (from: "Jenni", to: "Raka",  level: 3),
            (from: "Raka",  to: "Feli",  level: 4)
        ]

        Task { @MainActor in
            // 2. Loop through the scenarios
            for scene in scenarios {
                if let letter = await AIService.shared.generateSingleLetter(
                    from: scene.from,
                    to: scene.to,
                    level: scene.level
                ) {
                    self.generatedLetters.append(letter)
                }
            }

            // 3. This MUST be inside the Task to wait for the loop to finish!
            self.statusMessage = "Finished! Generated \(scenarios.count) unique letters."
            self.isLoading = false
        }
    }
}

#Preview {
    AITestView()
}
