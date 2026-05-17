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
        print("[SceneDelegate] Initializing application scene...")
        let schema = Schema([
            Request.self,
            Animal.self,
            AnimalRelationship.self,
            Collectible.self,
            PlayerProfile.self
        ])
        
        
        let modelConfiguration = ModelConfiguration(schema: schema)
        let container: ModelContainer
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("[SceneDelegate] ModelContainer successfully initialized.")
        } catch {
            print("[SceneDelegate] Error: Failed to create ModelContainer. Reason: \(error.localizedDescription)")
            print("[SceneDelegate] Attempting to delete old database files to recover...")
            
            let fileManager = FileManager.default
            if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let storePath = appSupport.appendingPathComponent("default.store").path
                
                for suffix in ["", "-wal", "-shm"] {
                    let targetPath = storePath + suffix
                    do {
                        try fileManager.removeItem(atPath: targetPath)
                        print("[SceneDelegate] Deleted incompatible database file: default.store\(suffix)")
                    } catch {
                        print("[SceneDelegate] File not found or could not be deleted: default.store\(suffix)")
                    }
                }
            }
            
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("[SceneDelegate] ModelContainer successfully created after database reset.")
            } catch {
                print("[SceneDelegate] Fatal Error: Could not create ModelContainer even after reset. Details: \(error.localizedDescription)")
                fatalError("[SceneDelegate] Database initialization failed completely.")
            }
        }
        
        let context = ModelContext(container)
        print("[SceneDelegate] Main ModelContext created.")
        
        GameDataManager.shared.setup(with: context)
        SeederDatabase.seedDatabaseIfNeeded(context: context)
        
        let mainGameView = GameView()
            .modelContainer(container)
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: mainGameView)
            self.window = window
            window.makeKeyAndVisible()
            print("[SceneDelegate] UIWindow configured and visible.")
        }
    }
}
