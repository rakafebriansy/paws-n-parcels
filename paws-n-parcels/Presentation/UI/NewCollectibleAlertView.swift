//
//  NewCollectibleAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct NewCollectibleAlertView: View {
    @Binding var isPresented: Bool
    
    let creamBackground = Color(red: 0.98, green: 0.96, blue: 0.9)
    let brownText = Color(red: 0.4, green: 0.25, blue: 0.15)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Collectible Unlocked!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(brownText)
            
            Button("Tutup") {
                withAnimation(.easeInOut) {
                    isPresented = false
                }
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(creamBackground)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue.opacity(0.5), lineWidth: 3))
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }
}
