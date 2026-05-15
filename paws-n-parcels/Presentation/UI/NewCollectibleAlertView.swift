//
//  NewCollectibleAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct NewCollectibleAlertView: View {
    @Binding var isPresented: Bool
    var body: some View {
        ZStack{
            Image("modal").resizable().scaledToFit().padding(24)
            VStack(spacing: 40) {
                Text("New Collectible Unlocked!")
                    .comicRelief(size: 30, isBold: true)     .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .bold()
                
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
            }
            .padding(30)
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
   
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        NewCollectibleAlertView(isPresented: .constant(true))
    }
}
