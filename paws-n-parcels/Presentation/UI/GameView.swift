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
    
    @State private var requestSystem = RequestSystem()
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
    
    @State private var joystickBubbleData: TutorialBubbleData? = nil
    @State private var yellowBubbleData: TutorialBubbleData? = nil
    @State private var redBubbleData: TutorialBubbleData? = nil
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
            // Render Tutorial Bubbles
            if let data = joystickBubbleData {
                TutorialBubbleView(data: data)
                    .position(data.position)
                    .transition(.opacity)
            }
            if let data = yellowBubbleData {
                TutorialBubbleView(data: data)
                    .position(data.position)
                    .transition(.opacity)
            }
            if let data = redBubbleData {
                TutorialBubbleView(data: data)
                    .position(data.position)
                    .transition(.opacity)
            }
            
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
                            .foregroundColor(.cream)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.45))
                                    .background(Circle().stroke(Color.cream.opacity(0.2), lineWidth: 1.5))
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
                        RelationshipView(onClose: {
                            withAnimation(.easeInOut) {
                                activePauseScreen = .main
                            }
                        })
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
        
        gameScene.onJoystickBubbleUpdate = { data in
            joystickBubbleData = data
        }
        
        gameScene.onYellowBubbleUpdate = { data in
            yellowBubbleData = data
        }
        
        gameScene.onRedBubbleUpdate = { data in
            redBubbleData = data
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
