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
    @State private var currentDialogMessage: String = ""
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
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
        
        gameScene.onDeliverySuccess = {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showDeliveryAlert = true
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
        }
    }
}
