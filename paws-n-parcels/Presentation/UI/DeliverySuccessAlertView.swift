//
//  DeliverySuccessAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct DeliverySuccessAlertView: View {
    let creamBackground = Color(red: 0.98, green: 0.96, blue: 0.9)
    let brownText = Color(red: 0.4, green: 0.25, blue: 0.15)
    
    var body: some View {
        ZStack {
            Image("modal").resizable().scaledToFit().padding(24)
            
            VStack(spacing: 40) {
                Text("Package has been delivered!")
                    .comicRelief(size: 30, isBold: true)     .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .bold()
                
                
            }
            .padding(40)
        }
            .shadow(radius: 10)
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        DeliverySuccessAlertView()
    }
}
