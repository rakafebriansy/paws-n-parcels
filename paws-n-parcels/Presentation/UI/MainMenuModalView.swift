
//
//  MainMenuModalView.swift
//  paws-n-parcels
//
//  Created by Aloysia Jennifer on 12/05/26.
//

import SwiftUI

struct MainMenuModalView: View {
    @AppStorage("bgm") private var bgm = 100.0
    @AppStorage("sfx") private var sfx = 100.0
    @AppStorage("isVibrationOn") private var isVibrationOn = true
    @State private var isEditing = false
    @State private var showResetConfirm = false
    
    var onResume: (() -> Void)? = nil
    var onCollectibles: (() -> Void)? = nil
    var onRelationships: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            if !showResetConfirm {
                mainMenuContent
            }

            if showResetConfirm {
                ResetConfirmModalView(
                    onConfirm: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showResetConfirm = false
                        }
                        onReset?()
                    },
                    onCancel: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showResetConfirm = false
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var mainMenuContent: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                Image("modal")
                    .resizable()
                    .scaledToFit()
                
                Button(action: {
                    onResume?()
                }) {
                    Image("close_button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 40)
                .padding(.leading, 35)
            }
            .padding(24)
            
            VStack(spacing: 14) {
                Text("Menu")
                    .comicRelief(size: 40, isBold: true)
                    .foregroundColor(.darkGray)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 10) {
                    Button(action: {
                        onCollectibles?()
                    }){
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Collectibles")
                        }
                        .comicRelief(size: 18, isBold: true)
                        .foregroundColor(Color.cream)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.darkGray)
                        .cornerRadius(35)
                    }
                    
                    Button(action: {
                        onRelationships?()
                    }){
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Relationships")
                        }
                        .comicRelief(size: 18, isBold: true)
                        .foregroundColor(Color.cream)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.darkGray)
                        .cornerRadius(35)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showResetConfirm = true
                        }
                    }){
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .comicRelief(size: 18, isBold: true)
                        .foregroundColor(Color.cream)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(35)
                    }
                }
                .padding(.horizontal, 60)
                
                Text("Settings")
                    .comicRelief(size: 26, isBold: true)
                    .foregroundColor(.darkGray)
                    .padding(.top, 6)
                
                HStack {
                    Image(systemName: bgm == 0 ? "music.note.slash" : "music.note")
                        .foregroundColor(.red)
                        .font(.system(size:24))
                    
                    Text("BGM")
                        .comicRelief(size: 22, isBold: true)
                        .foregroundColor(.darkGray)
                    
                    Slider(
                        value: $bgm,
                        in: 0...100,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    ).frame(width:120)
                        .tint(Color.darkGray)
                }
                .padding(.vertical, -8)
                
                HStack {
                    Image(systemName: sfx == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.red)
                        .font(.system(size:24))
                    
                    Text("SFX")
                        .comicRelief(size: 22, isBold: true)
                        .foregroundColor(.darkGray)
                    
                    Slider(
                        value: $sfx,
                        in: 0...100,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    ).frame(width:120)
                        .tint(Color.darkGray)
                }
            }
            .offset(y: -20)
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        MainMenuModalView()
    }
}
