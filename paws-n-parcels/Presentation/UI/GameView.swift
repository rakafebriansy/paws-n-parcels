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
    
    @Query private var allRelationships: [AnimalFriendRelationship]
    
    var body: some View {
        ZStack {
            SpriteView(scene: gameScene)
                .ignoresSafeArea()
            
            if let nearbyHouse = deliverySystem.nearbyHouse,
               let activeReq = deliverySystem.activePackage ?? nearbyHouse.component(ofType: RequestComponent.self)?.requestData {
                
                let rel = allRelationships.first(where: {
                    ($0.friendOneId == activeReq.senderId && $0.friendTwoId == activeReq.receiverId) ||
                    ($0.friendOneId == activeReq.receiverId && $0.friendTwoId == activeReq.senderId)
                })
                
                if let activeRel = rel {
                    VStack {
                        Spacer()
                        DeliveryView(
                            playerEntity: gameScene.playerEntity,
                            deliverySystem: deliverySystem,
                            req: activeReq,
                            activeRelationship: activeRel
                        )
                        .frame(height: 300)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .transition(.move(edge: .bottom))
                    }
                    .ignoresSafeArea()
                }
            }
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
