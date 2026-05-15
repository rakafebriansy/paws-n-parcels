//
//  RelationshipPointsAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct RelationshipPointsAlertView: View {
    var points: Int
   
    var body: some View {
        Text("+\(points) Relationship Points")
            .comicRelief(size: 20, isBold: true)
            .multilineTextAlignment(.center)
            .foregroundColor(.brown)
            .padding()
            .background(Color.sage)
            .cornerRadius(25)
            .padding(.top, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
