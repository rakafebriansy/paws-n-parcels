//
//  SceneDelegate.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 04/05/26.
//

import SwiftData
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {

        // 1. Setup SwiftData Container (In-Memory for clean testing)
        let schema = Schema([
            Request.self,
            AnimalFriend.self,
            AnimalFriendRelationship.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        let context = container.mainContext

        // 2. BOOTSTRAP: Create the 5 Characters & Relationships
        // This ensures the 'Bridge' logic in RequestSystem doesn't fail.
        let names = ["Clair", "Kaelen", "Somi", "Sun-woo", "Min-jun"]
        var friends: [AnimalFriend] = []

        for name in names {
            let friend = AnimalFriend(name: name, species: "Domestic")
            context.insert(friend)
            friends.append(friend)
        }

        // Create 2 sample relationships (Clair-Kaelen and Somi-Sunwoo)
        let rel1 = AnimalFriendRelationship(
            friendOne: friends[0],
            friendTwo: friends[1]
        )
        rel1.friendOne = friends[0]  // Clair
        rel1.friendTwo = friends[1]  // Kaelen
        rel1.friendshipLevel = 1

        let rel2 = AnimalFriendRelationship(
            friendOne: friends[2],
            friendTwo: friends[3]
        )
        rel2.friendOne = friends[2]  // Somi
        rel2.friendTwo = friends[3]  // Sun-woo
        rel2.friendshipLevel = 2

        context.insert(rel1)
        context.insert(rel2)

        // 3. Initialize RequestSystem & Inject House Entities
        let system = RequestSystem(modelContext: context)

        // Create the House objects the system and UI will share
        system.allHouses = names.map { name in
            HouseEntity(name: name, position: .zero)
        }

        // Load the friends/relationships we just created into the system
        system.fetchInitialData()

        // 4. Wrap in UIHostingController
        let testView = RequestDebugView(system: system)
            .modelContainer(container)  // Pass container to environment

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
