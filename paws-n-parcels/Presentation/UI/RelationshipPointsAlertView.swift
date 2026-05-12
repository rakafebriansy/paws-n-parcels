//
//  RelationshipPointsAlertView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct RelationshipPointsAlertView: View {
    var points: Int
    
    let sageGreen = Color(red: 197/255, green: 218/255, blue: 179/255)
    let brownText = Color(red: 0.4, green: 0.25, blue: 0.15)
    
    var body: some View {
        Text("+\(points) Relationship Points")
            .font(.headline)
            .foregroundColor(brownText)
            .padding()
            .background(sageGreen)
            .cornerRadius(25)
            .shadow(radius: 3)
            .padding(.top, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}
