//
//  SceneDelegate.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 04/05/26.
//

import UIKit
import SwiftUI
import SwiftData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: 
                Request.self, 
                AnimalFriend.self, 
                AnimalFriendRelationship.self,
                Collectible.self,
                PlayerProfile.self
            )
        } catch {
            print("Failed to create ModelContainer: \(error)")
            return
        }
        
        let context = ModelContext(container)
        SeederDatabase.seedDatabaseIfNeeded(context: context)
        
        let requestSystem = RequestSystem(modelContext: context)
        
        let mainGameView = GameView(requestSystem: requestSystem)
            .modelContainer(container)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: mainGameView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
