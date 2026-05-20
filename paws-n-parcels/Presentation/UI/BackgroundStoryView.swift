//
//  BackgroundStoryView.swift
//  paws-n-parcels
//
//  Created by AI on 2026-05-20.
//

import SwiftUI

struct BackgroundStoryView: View {
    var onStart: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Image("bg_story_container")
                    .resizable()
                    .scaledToFit()
                
                VStack(spacing: 20) {
                    Text("In a peaceful village of forests, savannas, and rivers, lives Goldie. This cheerful golden retriever faithfully delivers packages, weaving warm friendships among the animals!")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    Button(action: onStart) {
                        Text("Tap to start!")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.darkGray)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        BackgroundStoryView(onStart: {})
    }
}

