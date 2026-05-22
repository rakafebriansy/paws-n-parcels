//
//  RelationshipPointsAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct RelationshipPointsAlertView: View {
    var points: Int
    var onClose: () -> Void
   
    var body: some View {
        Text("+\(points) Relationship Point")
            .comicRelief(size: 14, isBold: true)
            .foregroundColor(.brown)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.sage)
            .cornerRadius(18)
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                SoundManager.shared.play(.menu1A)
            }
    }
}

#Preview {
    ZStack {
        Color.cream.ignoresSafeArea()
        RelationshipPointsAlertView(points: 5, onClose: {})
    }
}
