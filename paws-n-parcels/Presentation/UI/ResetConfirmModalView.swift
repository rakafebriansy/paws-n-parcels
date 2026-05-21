//
//  ResetConfirmModalView.swift
//  paws-n-parcels
//

import SwiftUI

struct ResetConfirmModalView: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                Image("modal")
                    .resizable()
                    .scaledToFit()

                Button(action: {
                    onCancel()
                }) {
                    Image("back_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 40)
                .padding(.leading, 35)
            }
            .padding(24)

            VStack(spacing: 20) {
                Text("Reset Game?")
                    .comicRelief(size: 36, isBold: true)
                    .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)

                Text("Are you sure you want to\nreset all progress?\nThis cannot be undone.")
                    .comicRelief(size: 18)
                    .foregroundColor(.darkGray.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Yes, Reset")
                        }
                        .comicRelief(size: 18, isBold: true)
                        .foregroundColor(Color.cream)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(35)
                    }

                    Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .comicRelief(size: 18, isBold: true)
                            .foregroundColor(Color.cream)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.darkGray)
                            .cornerRadius(35)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 8)
            }
            .offset(y: -10)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        ResetConfirmModalView(onConfirm: {}, onCancel: {})
    }
}
