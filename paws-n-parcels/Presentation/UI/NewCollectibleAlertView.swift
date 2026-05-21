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
            Image("modal").resizable().scaledToFit().padding(24).overlay(
                VStack{
                    Text("New Collectible Unlocked!")
                        .comicRelief(size: 32, isBold: true)     .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal,30)
                        .frame(maxWidth: 300)
                    
                    let assetName = item.name.lowercased().replacingOccurrences(of: " ", with: "_")
                    
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .lineLimit(2)
                        
                    Text(item.name)
                        .comicRelief(size: 27)     .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal,30)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: 300)
                
                    Button(action: {
                        withAnimation(.easeInOut) {
                            isPresented = false
                        }
                    }){
                        HStack{
                            Text("Yay!")
                        }
                        .comicRelief(size: 25, isBold: true)
                        .tracking(1.5)
                        .foregroundColor(Color.cream)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.darkGray)
                        .cornerRadius(35)
                    }
                }
            )
        }
        .padding(5)
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
