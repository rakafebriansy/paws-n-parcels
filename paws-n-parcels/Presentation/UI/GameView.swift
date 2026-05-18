//
//  GameView.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 07/05/26.
//

import Foundation
import SpriteKit
import SwiftUI
import SwiftData
import GameplayKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    
    private let requestSystem = RequestSystem()
    @State private var deliverySystem = DeliverySystem()
        
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = CGSize(width: 375, height: 812)
        scene.scaleMode = .aspectFit
        print("[GameView] GameScene instance initialized.")
        return scene
    }()
    
    @State private var showPickUpAlert: Bool = false
    @State private var showDeliveryAlert: Bool = false
    @State private var showRelationshipPointsAlert: Bool = false
    @State private var relationshipPointsEarned: Int = 0
    @State private var currentDialogMessage: String = ""
    
    @State private var isPaused: Bool = false
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
            // HUD Overlay (Top-Right Action Buttons)
            VStack {
                HStack(spacing: 12) {
                    Spacer()
                    
                    // Pause Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if isPaused {
                                gameScene.gameStateMachine?.enter(GamePlayingState.self)
                                isPaused = false
                            } else {
                                gameScene.gameStateMachine?.enter(GamePausedState.self)
                                isPaused = true
                            }
                        }
                    }) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.45))
                                    .background(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
                
                Spacer()
            }
            .zIndex(5)
            
            if showPickUpAlert || showDeliveryAlert {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
            
            ZStack {
                if showPickUpAlert {
                    PickUpSuccessAlertView(message: currentDialogMessage)
                        .transition(
                            .scale
                            .combined(with: .opacity)
                        )
                }
                
                if showDeliveryAlert {
                    DeliverySuccessAlertView()
                        .transition(
                            .scale
                            .combined(with: .opacity)
                        )
                }
            }
            .zIndex(2)
            
            if showRelationshipPointsAlert {
                VStack {
                    RelationshipPointsAlertView(points: relationshipPointsEarned)
                    Spacer()
                }
                .zIndex(3)
            }
            

            
            // Full Screen Glassmorphic Pause Overlay
            if isPaused {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                            .shadow(radius: 8)
                            .padding(.bottom, 8)
                        
                        Text("PAWS-N-PARCELS")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.white)
                            .tracking(3)
                        
                        Text("Game Paused")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    gameScene.gameStateMachine?.enter(GamePlayingState.self)
                                    isPaused = false
                                }
                            }) {
                                Text("RESUME PLAY")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.orange)
                                    )
                                    .shadow(radius: 4)
                            }
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    gameScene.gameStateMachine?.enter(GamePlayingState.self)
                                    isPaused = false
                                    gameScene.resumeGameplay()
                                }
                            }) {
                                Text("RESTART LEVEL")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                            .background(Color.black.opacity(0.2))
                                    )
                            }
                        }
                        .frame(width: 260)
                        .padding(.top, 16)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.12).opacity(0.85))
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                            )
                    )
                    .shadow(radius: 20)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(10)
            }
        }
        .onAppear {
            GameDataManager.shared.setup(with: modelContext)
            setupGameDependencies()
            setupGameSceneCallbacks()
        }
    }
    
    private func setupGameDependencies() {
        print("[GameView] View appeared. Injecting dependencies into GameScene...")
        
        gameScene.requestSystem = requestSystem
        gameScene.deliverySystem = deliverySystem
        print("[GameView] Dependencies injected successfully.")
    }
    
    private func setupGameSceneCallbacks() {
        gameScene.onPickUpSuccess = { dialogMessage in
            currentDialogMessage = dialogMessage
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showPickUpAlert = true
            }
            
            dismissAlertsAutomatically()
        }
        
        gameScene.onDeliverySuccess = { points in
            relationshipPointsEarned = points
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showDeliveryAlert = true
                showRelationshipPointsAlert = true
            }
            
            dismissAlertsAutomatically()
        }
    }
    
    private func dismissAlertsAutomatically() {
        DispatchQueue.main.asyncAfter(deadline: .now() + GameConfig.alertDisplayDuration) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showPickUpAlert = false
                showDeliveryAlert = false
            }
            gameScene.resumeGameplay()
        }
        
        if showRelationshipPointsAlert {
            DispatchQueue.main.asyncAfter(deadline: .now() + (GameConfig.alertDisplayDuration * 2.0)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRelationshipPointsAlert = false
                }
            }
        }
    }
}
