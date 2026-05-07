//
//  AITestView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 07/05/26.
//

import SwiftUI
import FoundationModels

struct AITestView: View {
    @State private var generatedLetters: [PackageLetter] = []
    @State private var isLoading = false
    @State private var statusMessage = "Press the button to generate 5 letters"

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Somi is writing...")
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
                    Text("Generate Batch (5 Letters)")
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
        statusMessage = "Connecting..."
        
        Task {
            do {
                let batch = await AIService.shared.generateBatch(
                    item: "Shiny Ribbon",
                    from: "Somi",
                    to: "Player",
                    level: 2
                )
                
                DispatchQueue.main.async {
                    if batch.isEmpty {
                        self.statusMessage = "Batch is empty. Check Xcode Console!"
                    } else {
                        self.generatedLetters = batch
                        self.statusMessage = "Success!"
                    }
                    self.isLoading = false
                }
            } catch let error as LanguageModelSession.GenerationError {
                // This is the "Magic" part that tells you WHY it failed
                DispatchQueue.main.async {
                    self.statusMessage = "Error: \(error)"
                    self.isLoading = false
                    print("--- AI ERROR DEBUG ---")
                    print("Code: \(error)")
                }
            } catch {
                print("Unknown Error: \(error)")
            }
        }
    }
}

#Preview {
    AITestView()
}
