
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
    var onBGMChange: ((Float) -> Void)? = nil
    var onSFXChange: ((Float) -> Void)? = nil
    
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
            ZStack(alignment: .top) {
                Image("modal")
                    .resizable()
                    .scaledToFit()
                
                ZStack {
                    Text("Menu")
                        .comicRelief(size: 40, isBold: true)
                        .foregroundColor(.darkGray)
                    
                    HStack {
                        Button(action: {
                            onResume?()
                        }) {
                            Image("close_button")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        }
                        .padding(.leading, 35)
                        
                        Spacer()
                    }
                }
                .padding(.top, 25)
            }
            .padding(24)
            
            VStack(spacing: 14) {
                Text("Menu")
                    .comicRelief(size: 40, isBold: true)
                    .hidden()
                
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
                    .comicRelief(size: 30, isBold: true)
                    .foregroundColor(.darkGray)
                    .padding(.top, 15)
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: bgm == 0 ? "music.note.slash" : "music.note")
                            .foregroundColor(.red)
                            .font(.system(size: 28))
                            .frame(width: 34, alignment: .center)
                        
                        Text("BGM")
                            .comicRelief(size: 25, isBold: true)
                            .foregroundColor(.darkGray)
                            .frame(width: 58, alignment: .leading)
                        
                        Slider(
                            value: $bgm,
                            in: 0...100,
                            onEditingChanged: { editing in
                                isEditing = editing
                            }
                        )
                        .frame(width: 130)
                        .tint(Color.darkGray)
                        .onChange(of: bgm) { _, newValue in
                            onBGMChange?(Float(newValue / 100.0))
                        }
                    }
                    .frame(width: 230, alignment: .leading)
                    
                    HStack(spacing: 8) {
                        Image(systemName: sfx == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 28))
                            .frame(width: 34, alignment: .center)
                        
                        Text("SFX")
                            .comicRelief(size: 25, isBold: true)
                            .foregroundColor(.darkGray)
                            .frame(width: 58, alignment: .leading)
                        
                        Slider(
                            value: $sfx,
                            in: 0...100,
                            onEditingChanged: { editing in
                                isEditing = editing
                            }
                        )
                        .frame(width: 130)
                        .tint(Color.darkGray)
                        .onChange(of: sfx) { _, newValue in
                            onSFXChange?(Float(newValue / 100.0))
                        }
                    }
                    .frame(width: 230, alignment: .leading)
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
