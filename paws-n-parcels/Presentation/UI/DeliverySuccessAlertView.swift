//
//  DeliverySuccessAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct DeliverySuccessAlertView: View {
    var body: some View {
        ZStack {
            Image("modal").resizable().scaledToFit().padding(24).overlay(
                
                VStack(spacing: 20) {
                    Text("Package delivered!")
                        .comicRelief(size: 40, isBold: true)     .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: 270)
                        .lineLimit(2)
                        .padding(.top,10)
                                        
                    Image("paket")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 130, maxHeight: 130)
                        .padding(.bottom,140)
                        .padding(.top,20)
                }
                    .padding(40)
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        DeliverySuccessAlertView()
    }
}
