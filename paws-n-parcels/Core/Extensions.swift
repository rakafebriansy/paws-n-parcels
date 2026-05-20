//
//  Extensions.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 06/05/26.
//

import Foundation
import SwiftUI

// Color Palette
extension Color {
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.9)
    static let brown = Color(red: 0.4, green: 0.25, blue: 0.15)
    static let sage = Color(red: 197/255, green: 218/255, blue: 179/255)
    static let darkGray = Color(red: 63/255, green: 55/255, blue: 49/255)
    static let red = Color(red: 223/255, green: 74/255, blue: 80/255)
}

// Font
extension View {
    func comicRelief(size: CGFloat, isBold: Bool = false) -> some View {
        self.font(.custom(isBold ? "ComicRelief-Bold" : "ComicRelief-Regular", size: size))
    }
}
