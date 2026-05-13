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
            VStack(spacing: 20) {
                Text("New Collectible Unlocked!")
                    .comicRelief(size: 30, isBold: true)     .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .bold()
                
                Button("Tutup") {
                    withAnimation(.easeInOut) {
                        isPresented = false
                    }
                }
                .padding(.top, 10)
            }
            .padding(30)
        }
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
   
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        
        NewCollectibleAlertView(isPresented: .constant(true))
    }
}
