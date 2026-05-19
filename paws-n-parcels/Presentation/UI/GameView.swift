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
    @Environment(\.scenePhase) private var scenePhase
    
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
    @State private var currentPhase: GamePhase = {
        if !UserDefaults.standard.bool(forKey: "hasSeenBackgroundStory") {
            return .backgroundStory
        } else if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            return .tutorial
        } else {
            return .playing
        }
    }()
    
    enum PauseMenuScreen {
        case main
        case collectibles
        case relationships
    }
    
    @State private var activePauseScreen: PauseMenuScreen = .main
    
    @State private var joystickBubbleData: TutorialBubbleData? = nil
    @State private var yellowBubbleData: TutorialBubbleData? = nil
    @State private var redBubbleData: TutorialBubbleData? = nil
    @State private var tooFarBubbleData: TooFarBubbleData? = nil
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
            if currentPhase != .backgroundStory {
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
                
                if let data = tooFarBubbleData {
                    TooFarBubbleView(data: data)
                        .position(data.position)
                        .transition(.opacity)
                }
            }
            
            if !isPaused && currentPhase != .backgroundStory {
                VStack {
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                activePauseScreen = .main
                                gameScene.gameStateMachine?.enter(GamePausedState.self)
                                isPaused = true
                            }
                        }) {
                            Image("menu_button")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                .transition(.opacity)
                .zIndex(5)
            }
            
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
                    RelationshipPointsAlertView(points: relationshipPointsEarned) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showRelationshipPointsAlert = false
                        }
                    }
                    Spacer()
                }
                .zIndex(3)
            }
            
            if isPaused {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(9)
            }
            
            if isPaused {
                Group {
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
                            },
                            onReset: {
                                showPickUpAlert = false
                                showDeliveryAlert = false
                                showRelationshipPointsAlert = false
                                relationshipPointsEarned = 0
                                currentDialogMessage = ""
                                joystickBubbleData = nil
                                yellowBubbleData = nil
                                redBubbleData = nil
                                tooFarBubbleData = nil
                                activePauseScreen = .main
                                
                                gameScene.resetGame()
                            
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    isPaused = false
                                    currentPhase = .backgroundStory
                                }
                            }
                        )
                    case .collectibles:
                        CollectiblesView(
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
            if currentPhase == .backgroundStory {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(19)
                
                BackgroundStoryView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        UserDefaults.standard.set(true, forKey: "hasSeenBackgroundStory")
                        currentPhase = .tutorial
                        gameScene.currentPhase = .tutorial
                        gameScene.startTutorialIfNeeded()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(20)
            }
        }
        .onAppear {
            GameDataManager.shared.setup(with: modelContext)
            setupGameDependencies()
            setupGameSceneCallbacks()
            
            // Set the correct phase based on saved state
            let initialPhase = currentPhase
            gameScene.currentPhase = initialPhase
            
            if initialPhase == .playing || initialPhase == .tutorial {
                if initialPhase == .tutorial {
                    gameScene.startTutorialIfNeeded()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                gameScene.saveGameState()
                print("[GameView] App went to background/inactive. Game state saved.")
            }
        }
    }
    
    private func setupGameDependencies() {
        print("[GameView] View appeared. Injecting dependencies into GameScene...")
        
        gameScene.deliverySystem = deliverySystem
        gameScene.requestSystem = requestSystem
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
        
        gameScene.onTooFarBubbleUpdate = { data in
            withAnimation(.easeOut(duration: 0.15)) {
                tooFarBubbleData = data
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                if self.showRelationshipPointsAlert {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showRelationshipPointsAlert = false
                    }
                }
            }
        }
    }
}
