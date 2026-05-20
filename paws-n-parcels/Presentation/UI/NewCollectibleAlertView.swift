//
//  NewCollectibleAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct NewCollectibleAlertView: View {
    @Binding var isPresented: Bool
    var item: Collectible
    
    var body: some View {
        ZStack{
            Image("modal").resizable().scaledToFit().padding(24)
            VStack(spacing: 20) {
                Text("New Collectible Unlocked!")
                    .comicRelief(size: 30, isBold: true)     .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                
                let assetName = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
                
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                Text(item.name)
                    .comicRelief(size: 25, isBold: true)     .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)
            
                Button("Tutup") {
                    withAnimation(.easeInOut) {
                        isPresented = false
                    }
                }
                .padding(.top, 10)
            }
            .padding(30)
        }
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
   
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        let item = Collectible(name: "sunflower")
        
        NewCollectibleAlertView(isPresented: .constant(true), item: item)
    }
}
