//
//  LetterView.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 20/05/26.
//

import SwiftUI
import SwiftData

struct LetterView: View {
    var letter: PackageLetter
    
    var body: some View {
        ZStack {
            // 1. The Background Asset properly scaled
            Image("letter")
                .resizable()
                .scaledToFit()
                .frame(width: 350) // Adjusts the asset size nicely to match phone layouts
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            // 2. The Text Overlay Container
            // We use an absolute frame size matching the card portion of your asset
            HStack(alignment: .top, spacing: 0) {
                
                // LEFT SIDE: The Message Body and Sender Signature
                VStack(alignment: .leading, spacing: 4) {
                    Text(letter.messageBody)
                        .font(.system(size: 11, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.15))
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                    
                    Spacer(minLength: 2)
                    
                    Text("From: \(letter.sender)")
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                }
                .frame(width: 175, height: 95, alignment: .topLeading)
                
                Spacer(minLength: 0)
                
                // RIGHT SIDE: The Destination Name (To:)
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    
                    Text("To: \(letter.recipient)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        .padding(.leading, 4)
                }
                .frame(width: 115, height: 95, alignment: .bottomLeading)
            }
            .frame(width: 260, height: 95)
            .padding(.bottom, 185)
        }
    }
}

#Preview {
    LetterView(
        letter: PackageLetter(
            sender: "Kaelen",
            recipient: "Clair",
            messageBody: "I left your prototype blueprints on the work table. Let me know if the level progression data makes sense or if we need to expand the XP reward values tomorrow!"
        )
    )
}
