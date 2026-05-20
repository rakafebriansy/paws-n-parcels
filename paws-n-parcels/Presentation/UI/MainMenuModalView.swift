
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
                
                HStack {
                    Image(systemName: bgm == 0 ? "music.note.slash" : "music.note")
                        .foregroundColor(.red)
                        .font(.system(size:28))
                    
                    Text("BGM")
                        .comicRelief(size: 25, isBold: true)
                        .foregroundColor(.darkGray)
                    
                    Slider(
                        value: $bgm,
                        in: 0...100,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    ).frame(width:130)
                        .tint(Color.darkGray)
                }
                .padding(-10)
                
                HStack {
                    Image(systemName: sfx == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.red)
                        .font(.system(size:28))
                    
                    Text("SFX")
                        .comicRelief(size: 25, isBold: true)
                        .foregroundColor(.darkGray)
                    
                    Slider(
                        value: $sfx,
                        in: 0...100,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    ).frame(width:130)
                        .tint(Color.darkGray)
                }
            }
            .offset(y: -25)

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
