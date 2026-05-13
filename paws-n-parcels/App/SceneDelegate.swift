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
        let container = try! ModelContainer(for: Request.self, AnimalFriend.self, AnimalFriendRelationship.self)
        let context = ModelContext(container)
        
        // In SceneDelegate.swift
        let system = RequestSystem(modelContext: context)

        // DO NOT create a new array here. Fill the one inside the system!
        let names = ["Clair", "Kaelen", "Somi", "Sun-woo", "Min-jun"]
        system.allHouses = names.map { name in
            HouseEntity(name: name, position: .zero)
        }

        let testView = RequestDebugView(system: system)

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: testView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    //MARK: FOR AI
//    func scene(
//        _ scene: UIScene,
//        willConnectTo session: UISceneSession,
//        options connectionOptions: UIScene.ConnectionOptions
//    ) {
//
//        // 1. Create your SwiftUI Test View
//        let testView = AITestView()
//
//        // 2. Wrap it in a UIHostingController (this lets SwiftUI live inside UIKit)
//        if let windowScene = scene as? UIWindowScene {
//            let window = UIWindow(windowScene: windowScene)
//            window.rootViewController = UIHostingController(rootView: testView)
//            self.window = window
//            window.makeKeyAndVisible()
//        }
//    }

    //    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    //        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    //        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    //        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    //        guard let _ = (scene as? UIWindowScene) else { return }
    //    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}
