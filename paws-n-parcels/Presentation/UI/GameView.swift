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
    @StateObject private var deliverySystem = DeliverySystem()
    
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        scene.size = CGSize(width: 375, height: 812)
        scene.scaleMode = .aspectFit
        return scene
    }()
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
        }
        .onAppear {
            deliverySystem.setup(context: requestSystem.modelContext)
            
            gameScene.requestSystem = requestSystem
            gameScene.deliverySystem = deliverySystem
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Request.self, AnimalFriend.self, AnimalFriendRelationship.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let dummyRequestSystem = RequestSystem(modelContext: context)
        
        return GameView(requestSystem: dummyRequestSystem)
    } catch {
        return Text("Failed to load Preview: \(error.localizedDescription)")
    }
}
