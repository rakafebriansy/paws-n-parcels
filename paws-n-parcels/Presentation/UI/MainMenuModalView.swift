
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
    
    var onResume: (() -> Void)? = nil
    var onCollectibles: (() -> Void)? = nil
    var onRelationships: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Image("modal").resizable().scaledToFit().padding(24).overlay(
                
                VStack(spacing: 23) {
                    Text("Menu")
                        .comicRelief(size: 45, isBold: true)
                        .foregroundColor(.darkGray)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 15) {
                        Button(action: {
                            onCollectibles?()
                        }){
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Collectibles")
                            }
                            .comicRelief(size: 25, isBold: true)
                            .tracking(1.5)
                            .foregroundColor(Color.cream)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 30)
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
                            .comicRelief(size: 25, isBold: true)
                            .tracking(1.5)
                            .foregroundColor(Color.cream)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 20)
                            .background(Color.darkGray)
                            .cornerRadius(35)
                        }
                    }
                    
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
                        }
                        .frame(width: 230, alignment: .leading)
                    }
                    
                }
                    .offset(y: -25)
                    .padding(.vertical, 10)
                
                )
                VStack {
                    HStack {
                        Button(action: {
                            onResume?()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30))
                                .foregroundColor(.darkGray)
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color.white.opacity(0.75)))
                                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 40)
                        .padding(.leading, 35)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
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
