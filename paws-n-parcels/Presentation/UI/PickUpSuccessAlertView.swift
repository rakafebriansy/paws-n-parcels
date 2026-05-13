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
            Image("modal").resizable().scaledToFit().padding(24)
            
            VStack(spacing: 40) {
                Text("Ready for Delivery!")
                    .comicRelief(size: 45, isBold: true)      .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .bold()
                
                Text("\"\(message)\"")
                    .comicRelief(size: 20, isBold: false)
                    .foregroundColor(.brown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
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
        PickUpSuccessAlertView(message: "Wow, thanks a ton! Please deliver it in a flash!")
    }
}
