//
//  PickUpSuccessAlert.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct PickUpSuccessAlertView: View {
    var message: String
    var body: some View {
        ZStack{
            Image("modal").resizable().scaledToFit().padding(24).overlay(
                
                VStack(spacing: 20) {
                    Text("Ready for Delivery!")
                        .comicRelief(size: 40, isBold: true)      .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 30)
                        .padding(.top,10)
                        .frame(maxWidth: 270)
                    
                    Image("paket")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 130, maxHeight: 130)
                    
                    Text("\"\(message)\"")
                        .comicRelief(size: 20, isBold: false)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .minimumScaleFactor(0.5)
                }
                    .padding(40)
                    .offset(y:-10)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        PickUpSuccessAlertView(message: "Oh, you're here! I’ve been waiting to get this moving. Please deliver it in a flash, okay? Merci—now hop to it!")
    }
}
