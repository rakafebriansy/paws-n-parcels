//
//  DeliverySuccessAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct DeliverySuccessAlertView: View {
    let receiverAssetName: String
    
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
                                        
                    Image(receiverAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 130, maxHeight: 130)
                }
                    .padding(40)
                    .offset(y: -10)
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        DeliverySuccessAlertView(receiverAssetName: "package")
    }
}
