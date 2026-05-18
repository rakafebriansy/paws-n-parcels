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
    
    enum PauseMenuScreen {
        case main
        case collectibles
        case relationships
    }
    
    @State private var activePauseScreen: PauseMenuScreen = .main
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            VStack {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            if isPaused {
                                gameScene.gameStateMachine?.enter(GamePlayingState.self)
                                isPaused = false
                            } else {
                                activePauseScreen = .main
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
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.leading, 16)
                
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
            
            if isPaused {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    
                    switch activePauseScreen {
                    case .main:
                        MainMenuModalView(
                            onResume: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    gameScene.gameStateMachine?.enter(GamePlayingState.self)
                                    isPaused = false
                                }
                            },
                            onCollectibles: {
                                withAnimation(.easeInOut) {
                                    activePauseScreen = .collectibles
                                }
                            },
                            onRelationships: {
                                withAnimation(.easeInOut) {
                                    activePauseScreen = .relationships
                                }
                            }
                        )
                    case .collectibles:
                        CollectibleView(
                            onClose: {
                                withAnimation(.easeInOut) {
                                    activePauseScreen = .main
                                }
                            }
                        )
                    case .relationships:
                        ZStack {
                            RelationshipView()
                                                       // Close button for RelationshipView to return to Pause Main Menu
                            VStack {
                                HStack {
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            activePauseScreen = .main
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.cream))
                                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                                    }
                                    .padding(.top, 40)
                                    .padding(.leading, 45)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
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
