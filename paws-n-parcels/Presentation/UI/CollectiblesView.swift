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
    
    var collectibles: [Collectible] = Collectible.dummyData
    var onClose: (() -> Void)?
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.98, green: 0.96, blue: 0.9)
                .ignoresSafeArea()

                VStack {
                    Text("Collectibles")
                        .comicRelief(size: 45, isBold: true)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                    
                    ScrollView(showsIndicators: false){
                        LazyVGrid(columns: columns, spacing: 20) {
                            // enumerated() supaya bisa dapat urutan index
                            ForEach(Array(collectibles.enumerated()), id: \.element.id) {
                                index, item in
                                CollectibleCard(item: item, index: index, bgColor: Color.sage)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 40)
                    }
                }
            
            HStack {
                Button(action: { close() }) {
                    Image("back_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                Spacer()
            }
        }
    }
    
    private func close() {
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
            if !item.isUnlocked && index >= 5 {
                // background warna light gray untuk item yang masih locked
                Color(red: 0.85, green: 0.85, blue: 0.85)
            } else {
                bgColor
            }
            
            if item.isUnlocked || index < 5 {
//                let assetName = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
                
                VStack{
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.brown)
                // ubah warna item collectible jadi grayscale kalau belum unlocked
                    .saturation(item.isUnlocked ? 1.0 : 0.0)
                    .opacity(item.isUnlocked ? 1.0 : 0.4)
                    if item.isUnlocked{
                        Text(item.name)
                            .comicRelief(size: 20)
                            .foregroundColor(.darkGray)
                            .padding(.top, 5)
                    }
                }
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
    }
}

// dummy data untuk Preview
extension Collectible {
    static var dummyData: [Collectible] {
        [
            makePreviewItem(name: "Kacamata", isUnlocked: true),
            makePreviewItem(name: "Boba Drink", isUnlocked: true),
            makePreviewItem(name: "Mesin Tik", isUnlocked: false),
            makePreviewItem(name: "Handphone", isUnlocked: false),
            makePreviewItem(name: "Laptop", isUnlocked: true),
            makePreviewItem(name: "Rahasia 1", isUnlocked: false),
            makePreviewItem(name: "Rahasia 2", isUnlocked: false),
            makePreviewItem(name: "Rahasia 3", isUnlocked: false)
        ]
    }
    
    private static func makePreviewItem(name: String, isUnlocked: Bool) -> Collectible {
        let item = Collectible(name: name)
        item.isUnlocked = isUnlocked
        return item
    }
}

#Preview {
    NavigationStack{
        CollectiblesView()
    }
}
