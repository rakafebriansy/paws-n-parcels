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
                
                VStack(spacing: 16) {
                    Text("In a peaceful village of forests, savannas, and rivers, lives Goldie. This cheerful golden retriever faithfully delivers packages, weaving warm friendships among the animals!")
                        .comicRelief(size: 13)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: onStart) {
                        Text("Tap to start!")
                            .comicRelief(size: 16, isBold: true)
                            .foregroundColor(.darkGray)
                    }
                }
                .padding(.horizontal, 56)
                .padding(.vertical, 28)
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

