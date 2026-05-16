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
    let requestSystem: RequestSystem
    @State private var deliverySystem = DeliverySystem()
        
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = CGSize(width: 375, height: 812)
        scene.scaleMode = .aspectFit
        print("[GameView] GameScene instance initialized.")
        return scene
    }()
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
        }
        .onAppear {
            print("[GameView] View appeared. Injecting dependencies into GameScene...")
                        
            deliverySystem.setup(context: requestSystem.modelContext)
            
            gameScene.requestSystem = requestSystem
            gameScene.deliverySystem = deliverySystem
            
            print("[GameView] Dependencies injected successfully.")        }
    }
}

#Preview {
    do {
        let schema = Schema([
            Request.self,
            Animal.self,
            AnimalRelationship.self,
            Collectible.self,
            PlayerProfile.self
        ])
        
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let dummyRequestSystem = RequestSystem(modelContext: context)
        
        print("[GameView] Preview environment loaded successfully.")
        
        return GameView(requestSystem: dummyRequestSystem)
            .modelContainer(container)
    } catch {
        print("[GameView] Preview Error: Failed to load ModelContainer. Details: \(error.localizedDescription)")
        return Text("Failed to load Preview: \(error.localizedDescription)")
    }
}
