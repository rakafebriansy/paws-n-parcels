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
            // Postcard Base Background (Simulating your asset using soft colors)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.98, green: 0.96, blue: 0.92)) // Warm paper/cream tone
                .frame(width: 340, height: 220) // Standard landscape postcard aspect ratio
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            // Subtle dotted inner border to keep that cozy stationery aesthetic
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.brown.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4]))
                .frame(width: 324, height: 204)
            
            // Postcard Layout Grid
            HStack(alignment: .top, spacing: 0) {
                
                // LEFT SIDE: The Body Message & Sender Signature
                VStack(alignment: .leading, spacing: 6) {
                    Text(letter.messageBody)
                        .font(.system(size: 12, weight: .medium, design: .serif)) // Serif gives it a warm, handwritten feel
                        .italic()
                        .foregroundColor(Color(red: 0.25, green: 0.2, blue: 0.15)) // Deep espresso brown text
                        .lineLimit(6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 4)
                    
                    // Sender Signature line
                    Text("From: \(letter.sender)")
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundColor(Color.brown)
                }
                .padding(.trailing, 12)
                .frame(width: 170, alignment: .leading)
                
                // CENTER SEPARATOR LINE
                Rectangle()
                    .fill(Color.brown.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                // RIGHT SIDE: Stamp & Recipient Details
                VStack(alignment: .trailing, spacing: 0) {
                    
                    // Simulated Stamp Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.brown.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                            .fill(Color.orange.opacity(0.05))
                            .frame(width: 40, height: 48)
                        
                        Text("✉️")
                            .font(.system(size: 20))
                    }
                    .padding(.bottom, 16)
                    
                    // Address Lines (To: Recipient Name)
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("To:")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.brown.opacity(0.6))
                            
                            Text(letter.recipient)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        // Decorative traditional postcard destination lines
                        VStack(spacing: 6) {
                            Color.brown.opacity(0.25).frame(height: 1)
                            Color.brown.opacity(0.25).frame(height: 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    
                }
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width: 340, height: 220)
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
    .background(Color.gray.opacity(0.2))
}
