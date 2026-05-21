//
//  LetterView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 20/05/26.
//

import SwiftData
import SwiftUI

struct LetterView: View {
    var letter: PackageLetter

    var body: some View {
        ZStack {
            // 1. The Background Asset properly scaled
            Image("letter")
                .resizable()
                .scaledToFit()
                .frame(width: 350)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 10,
                    x: 0,
                    y: 5
                )

            // 2. Main Content Container (Side-by-Side Layout)
            HStack(alignment: .top, spacing: 0) {
                
                // LEFT COLUMN: Message Body Only
                // This completely isolates the body so it can never cross to the right side
                VStack(alignment: .leading, spacing: 0) {
                    Text(letter.messageBody)
                        .font(.system(size: 9.5, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.15))
                        .lineLimit(10)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                }
                .frame(width: 155, height: 110, alignment: .topLeading)
                
                // MIDDLE DIVIDER GAP: Just keeps a safe space buffer between text and address area
                Spacer(minLength: 0)
                
                // RIGHT COLUMN: Stamp Spacer and Address Lines (Stacked Vertically)
                VStack(alignment: .leading, spacing: 0) {
                    
                    // Top part of the right side is left empty to give room for the stamp graphic
                    Color.clear
                        .frame(height: 45)
                    
                    Spacer(minLength: 0)
                    
                    // Bottom part: The Names aligned directly on your lines
                    VStack(alignment: .leading, spacing: 6) { // Tune spacing to match your line asset gap
                        Text("From: \(letter.sender)")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            .padding(.leading, 12)
                        
                        Text("To: \(letter.recipient)")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            .padding(.leading, 12)
                    }
                    .frame(width: 120, alignment: .leading)
                    .padding(.bottom, -5) // Fine-tune this nudge to rest exactly on the lines
                }
                .frame(width: 120, height: 110)
            }
            .frame(width: 280, height: 110)  // Total writing canvas area on the card asset
            .padding(.bottom, 175)  // Positions the container cleanly over the top section of the asset
        }
        .offset(y: 40)
    }
}

#Preview {
    LetterView(
        letter: PackageLetter(
            sender: "Kaelen",
            recipient: "Clair",
            messageBody:
                "I left your prototype blueprints on the work table. Let me know if the level progression data makes sense or if we need to expand the XP reward values tomorrow!"
        )
    )
}
