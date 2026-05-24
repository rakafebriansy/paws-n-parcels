//
//  CollectiblesView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 18/05/26.
//

import SwiftUI
import SwiftData

struct CollectiblesView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Collectible.name) private var collectibles: [Collectible]
    
    var onClose: (() -> Void)?
    
    private let lockedPlaceholderCount = 45
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Image("collectibles_book").resizable().scaledToFill().ignoresSafeArea().overlay(

                    VStack (spacing: 15) {
                        ZStack {
                            Text("Collectibles")
                                .comicRelief(size: 45, isBold: true)
                                .foregroundColor(.darkGray)
                                .padding(.leading, 36)
                            
                            HStack {
                                Button(action: { close() }) {
                                    Image("back_button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                }
                                .padding(.leading, 20)
                                Spacer()
                            }
                        }
                        .padding(.top, geometry.size.height * 0.05)
                        
                        ScrollView(showsIndicators: false){
                            LazyVGrid(columns: columns, spacing: 20) {
                                // enumerated() supaya bisa dapat urutan index
                                ForEach(Array(collectibles.enumerated()), id: \.element.id) { index, item in
                                    CollectibleCard(item: item, index: index, bgColor: Color.cream)
                                }
                                
                                ForEach(0..<lockedPlaceholderCount, id: \.self) { _ in
                                    LockedCollectibleCard(bgColor: Color.cream)
                                }
                            }
                            .padding(.horizontal, 25)
                            .padding(.bottom, 40)
                            .padding(.leading, 40)
                        }
                    }
                )
            }
        }
    }
    
    private func close() {
        SoundManager.shared.play(.click5)
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

struct CollectibleCard: View {
    let item: Collectible
    let index: Int
    let bgColor: Color
    
    var body: some View {
        ZStack {
           bgColor
            
            if item.isUnlocked || index < 5 {
                let assetName = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
                
                VStack{
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        // ubah warna item collectible jadi hitam putih kalau belum unlocked
                        .colorMultiply(item.isUnlocked ? .white : .black.opacity(0.6))
                    if item.isUnlocked{
                        Text(item.name)
                            .comicRelief(size: 20, isBold: true)
                            .foregroundColor(.darkGray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)
                    }
                }
                .padding(8)
            } else {
                Image(systemName: "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.darkGray)
            }
        }
        .frame(height: 150)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.darkGray, lineWidth: 3))
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color.darkGray)
            .offset(x: -6, y: 6))
    }
}

struct LockedCollectibleCard: View {
    let bgColor: Color
    
    var body: some View {
        ZStack {
            bgColor
            
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.darkGray)
        }
        .frame(height: 150)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.darkGray, lineWidth: 3))
        .background(RoundedRectangle(cornerRadius: 20)
            .fill(Color.darkGray)
            .offset(x: -6, y: 6))
    }
}

#Preview {
    NavigationStack {
        CollectiblesView()
    }
    .modelContainer(for: Collectible.self, inMemory: true)
}
