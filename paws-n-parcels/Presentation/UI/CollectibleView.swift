//
//  CollectibleView.swift
//  paws-n-parcels
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI
import SwiftData

struct CollectibleView: View {
    @State private var collectibles: [Collectible] = []
    var onClose: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Image("modal")
                .resizable()
                .scaledToFit()
                .padding(24)
            
            VStack(spacing: 16) {
                Text("Collectibles")
                    .comicRelief(size: 38, isBold: true)
                    .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                
                if collectibles.isEmpty {
                    Text("No collectibles found.")
                        .comicRelief(size: 18)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(collectibles, id: \.id) { item in
                                HStack(spacing: 15) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(item.isUnlocked ? Color.sage.opacity(0.4) : Color.gray.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: item.isUnlocked ? "gift.fill" : "lock.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(item.isUnlocked ? .brown : .gray)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.isUnlocked ? item.name : "Locked Item")
                                            .comicRelief(size: 18, isBold: true)
                                            .foregroundColor(item.isUnlocked ? .darkGray : .gray)
                                        
                                        Text(item.isUnlocked ? item.desc : "Deliver packages to unlock this collectible.")
                                            .comicRelief(size: 14)
                                            .foregroundColor(item.isUnlocked ? .brown : .gray.opacity(0.8))
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.cream.opacity(0.6))
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 45)
                        .padding(.bottom, 20)
                    }
                    .frame(maxHeight: 280)
                }
            }
            .padding(.horizontal, 30)
            .offset(y: -10)
            
            VStack {
                HStack {
                    Button(action: {
                        onClose?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.cream))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 40)
                    .padding(.leading, 45)
                    Spacer()
                }
                Spacer()
            }
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            self.collectibles = GameDataManager.shared.fetchCollectibles()
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.35).ignoresSafeArea()
        CollectibleView()
    }
}
