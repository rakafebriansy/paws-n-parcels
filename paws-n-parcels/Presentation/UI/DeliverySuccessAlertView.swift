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
        VStack(spacing: 20) {
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                .bold()
            
            Text("Package has been delivered!")
                .font(.headline)
                .bold()
                .foregroundColor(brownText)
        }
        .padding(40)
        .background(creamBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(brownText, lineWidth: 3))
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }
}
