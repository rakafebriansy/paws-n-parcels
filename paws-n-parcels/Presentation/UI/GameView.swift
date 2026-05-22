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
    @State private var showNewCollectibleAlert: Bool = false
    @State private var relationshipPointsEarned: Int = 0
    @State private var currentDialogMessage: String = ""
    @State private var pendingLevelUp: Bool = false
    @State private var unlockedItem: Collectible? = nil
    @State private var showPostcard: Bool = false
    
    @State private var isPaused: Bool = false
    @State private var currentPhase: GamePhase = {
        if !UserDefaults.standard.bool(forKey: "hasSeenBackgroundStory") {
            return .backgroundStory
        } else if !UserDefaults.standard.bool(forKey: "hasFinishedTutorialPhase") {
            return .tutorial
        } else {
            return .playing
        }
    }()
    @State private var deliveredRequest: Request? = nil
    
    enum PauseMenuScreen {
        case main
        case collectibles
        case relationships
    }
    
    @State private var activePauseScreen: PauseMenuScreen = .main
    
    private var isShowingAlert: Bool {
        showPickUpAlert || showNewCollectibleAlert || showDeliveryAlert
    }
    
    @State private var joystickBubbleData: TutorialBubbleData? = nil
    @State private var yellowBubbleData: TutorialBubbleData? = nil
    @State private var redBubbleData: TutorialBubbleData? = nil
    @State private var tooFarBubbleData: TooFarBubbleData? = nil
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene, debugOptions: [.showsPhysics])
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
            
            if isShowingAlert || showPostcard {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                    .onTapGesture {
                        handleModalTap()
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
                        DeliverySuccessAlertView(receiverAssetName: deliveredRequest?.receiver.assetName ?? "package")
                            .transition(.scale.combined(with: .opacity))
                    }

                    if showNewCollectibleAlert {
                        if let itemToShow = unlockedItem {
                            NewCollectibleAlertView(isPresented: $showNewCollectibleAlert, item: itemToShow)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .zIndex(2)
                .transition(.scale.combined(with: .opacity))
                .onTapGesture {
                    handleModalTap()
                }
            }
            
            if showPostcard {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showPostcard = false
                            showRelationshipPointsAlert = false
                        }
                        if pendingLevelUp {
                            pendingLevelUp = false
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showNewCollectibleAlert = true
                            }
                        } else {
                            gameScene.resumeGameplay()
                        }
                    }
                    .zIndex(5)
                
                if let request = deliveredRequest {
                    LetterView(letter: request.letter)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .allowsHitTesting(false)
                        .zIndex(3)
                }
            }
            
            if showRelationshipPointsAlert {
                VStack {
                    RelationshipPointsAlertView(points: relationshipPointsEarned) {
                        if !showPostcard && !showDeliveryAlert {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showRelationshipPointsAlert = false
                            }
                            gameScene.resumeGameplay()
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting((showPostcard || showDeliveryAlert) ? false : true)
                .zIndex(4)
                .transition(.scale.combined(with: .opacity))
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
                            },
                            onBGMChange: { volume in
                                gameScene.setBGMVolume(volume)
                            },
                            onSFXChange: { volume in
                                gameScene.setSFXVolume(volume)
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
            if GameDataManager.shared.context == nil {
                GameDataManager.shared.setup(with: modelContext)
            }
            setupGameDependencies()
            setupGameSceneCallbacks()
            
            let initialPhase = currentPhase
            gameScene.currentPhase = initialPhase
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                gameScene.saveGameState()
                print("[GameView] App went to background/inactive. Game state saved.")
            }
        }
        .onChange(of: showNewCollectibleAlert) { _, isPresented in
            if !isPresented, unlockedItem != nil, !showDeliveryAlert {
                unlockedItem = nil
                gameScene.resumeGameplay()
            }
        }
    }
    
    private func setupGameDependencies() {
        print("[GameView] View appeared. Injecting dependencies into GameScene...")
        
        deliverySystem.modelContext = modelContext
    
        gameScene.deliverySystem = deliverySystem
        gameScene.requestSystem = requestSystem
        print("[GameView] Dependencies injected successfully.")
    }
    
    private func handleModalTap() {
        if showPickUpAlert {
            SoundManager.shared.play(.appearOnline)
            withAnimation(.easeInOut) {
                showPickUpAlert = false
            }
            gameScene.resumeGameplay()
            return
        }
        
        if showDeliveryAlert {
            SoundManager.shared.play(.appearOnline)
            withAnimation(.easeInOut(duration: 0.25)) {
                showDeliveryAlert = false
            }
            if deliveredRequest != nil {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showPostcard = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRelationshipPointsAlert = false
                }
                gameScene.resumeGameplay()
            }
            return
        }
        
        if showNewCollectibleAlert {
            withAnimation(.easeInOut) {
                showNewCollectibleAlert = false
            }
        }
    }
    

    
    private func setupGameSceneCallbacks() {
        gameScene.onPickUpSuccess = { dialogMessage in
            currentDialogMessage = dialogMessage
            gameScene.gameStateMachine?.enter(GamePausedState.self)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showPickUpAlert = true
            }
        }
        
        gameScene.onDeliverySuccess = { points, isLevelUp, newItem in
            relationshipPointsEarned = points
            gameScene.gameStateMachine?.enter(GamePausedState.self)
            
            if isLevelUp, let collectible = newItem {
                unlockedItem = collectible
                pendingLevelUp = true
            } else {
                unlockedItem = nil
                pendingLevelUp = false
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showRelationshipPointsAlert = true
                showDeliveryAlert = true
            }
        }
        
        gameScene.onLetterReady = { request in
            deliveredRequest = request
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
}
