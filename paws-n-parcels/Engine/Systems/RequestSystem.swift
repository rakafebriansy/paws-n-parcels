//
//  RequestSystem.swift
//  paws-n-parcels
//
//  Created by Felicia Joshlyn Purnomo on 11/05/26.
//

internal import Combine
import GameplayKit
import SwiftData
import SwiftUI

class RequestSystem: ObservableObject {
    
    //MARK: VARIABLES
    
    ///request to show for the swiftui popup
    @Published var completedRequestToShow: Request?
    
    ///call the request component
    let requestComponentSystem = GKComponentSystem(
        componentClass: RequestComponent.self
    )

    ///current active request for delivery
    var currentActiveRequest: Request?
    
    ///get all friends for the letter making
    var allFriends: [AnimalFriend] = []

    ///model context for the...
    private var modelContext: ModelContext
    
    ///timer for the spawning for the request notif (10 seconds as default)
    private var spawnTimer: TimeInterval = 10.0
    
    ///make sure the max request is 5
    private let maxRequests = 5

    ///get all the houses from the whole game
    var allHouses: [HouseEntity] = []
    
    //MARK: use later
    ///state machine
    let stateMachine = GKStateMachine(states: [])  // Initialize with states above
    
    ///get all the realtionship
    var relationships: [AnimalFriendRelationship] = []

    //initialize model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    ///update for each time for the requests spawn
    func update(deltaTime: TimeInterval) {
        // 1. Count how many houses have a notification component
        let activeCount = allHouses.filter {
            $0.component(ofType: RequestComponent.self) != nil
        }.count

        // 2. Spawn logic: If < 5, run the 10s timer
        if activeCount < maxRequests {
            spawnTimer -= deltaTime
            if spawnTimer <= 0 {
                generateAndSpawnRequest()
                spawnTimer = 10.0  // Reset interval
            }
        }
    }
    
    
    //MARK: REQUEST GENERATION

    ///fetch all the relationships to generate the letter and get the friendship level for letter generation
    private func fetchRelationships() {
        let descriptor = FetchDescriptor<AnimalFriendRelationship>()
        self.relationships = (try? modelContext.fetch(descriptor)) ?? []
    }

    ///generate and spawn the request on the main 5 houses with generated letter as well
    private func generateAndSpawnRequest() {
        //1. filter the houses that are active from all the houses, check from if the house has name
        ///the main 5 houses that has the NPC
        let eligibleHouses = allHouses.filter { house in
            guard house.characterName != nil else { return false }
            return house.component(ofType: RequestComponent.self) == nil
        }

        ///set the sender house, get the name from the house
        guard let senderHouse = eligibleHouses.randomElement(),
            let senderName = senderHouse.characterName
        else { return }

        //2. get all the realtionships to see where the senders name is involved
        ///relationships where the sender is in one of it
        let validRelationships = relationships.filter { rel in
            rel.friendOne?.name == senderName
                || rel.friendTwo?.name == senderName
        }

        //3. pick a random relationship and look for the other persons name
        ///get the chosen relationship that is known that the sender is in it
        guard let chosenRel = validRelationships.randomElement() else { return }

        // If sender is friendOne, the recipient is friendTwo. Otherwise, it's friendOne.
        ///set the recipient name from the other side of the relationship
        let recipientName =
            (chosenRel.friendOne?.name == senderName)
            ? chosenRel.friendTwo?.name
            : chosenRel.friendOne?.name

        ///frienship level gotten from the relationship
        let friendshipLevel = chosenRel.friendshipLevel

        ///final recipient name that is confirmed
        guard let finalRecipientName = recipientName else { return }

        //4. start the generation for the letter inside
        ///the AI task
        Task {
            //fill in the needed info for generation
            if let letterData = await AIService.shared.generateSingleLetter(
                from: senderName,
                to: finalRecipientName,
                level: friendshipLevel
            ) {

                //main actor for the ai
                await MainActor.run {
                    //match the strings to the swiftdata models
                    guard
                        //sender object as the name of the friend object
                        let senderObj = allFriends.first(where: {
                            $0.name == senderName
                        }),
                        //receiver object as the name of the friend object
                        let receiverObj = allFriends.first(where: {
                            $0.name == finalRecipientName
                        })
                    else {
                        return
                    }

                    //create and attach new request
                    ///create and attach new request
                    let newRequest = Request(
                        sender: senderObj,
                        receiver: receiverObj,
                        letter: letterData
                    )
                    
                    ///call the request component with the request data
                    let component = RequestComponent(requestData: newRequest)

                    //add the request component to the sender house as new request
                    senderHouse.addComponent(component)
                    requestComponentSystem.addComponent(component)

                    //print for log checking
                    print(
                        "Generated a Level \(friendshipLevel) letter from \(senderName) to \(finalRecipientName)!"
                    )
                }
            }
        }
    }
    
    //MARK: DATABASE
    
    ///sync the active request to the database after closing the game
    func syncToDatabase() {
        //1. fetch all request currently in the database
        let deleteDescriptor = FetchDescriptor<Request>()
        let oldRequests = (try? modelContext.fetch(deleteDescriptor)) ?? []

        // 2. Delete the request one by one
        for oldRequest in oldRequests {
            modelContext.delete(oldRequest)
        }

        // 3. Insert the 5 active notifications from your houses
        for house in allHouses {
            if let component = house.component(ofType: RequestComponent.self) {
                let requestToSave = component.requestData
                requestToSave.isCompleted = false
                modelContext.insert(requestToSave)
            }
        }

        // 4. Save changes to the phone's storage
        try? modelContext.save()
        print("Sync complete.")
    }

    ///load from the database when we first open the game
    func loadFromDatabase() {
        //1. fetch request where the isCompleted is false
        let descriptor = FetchDescriptor<Request>(
            predicate: #Predicate { $0.isCompleted == false }
        )
        ///saved request on the database
        let savedRequests = (try? modelContext.fetch(descriptor)) ?? []

        //2. put the requests in the corresponding houses
        for request in savedRequests {
            let senderName = request.sender.name

            if let targetHouse = allHouses.first(where: {
                $0.characterName == senderName
            }) {
                let component = RequestComponent(requestData: request)
                targetHouse.addComponent(component)

                //3. Re-track it in the GameplayKit system
                requestComponentSystem.addComponent(component)
            }
        }
        //print for log
        print("Restored \(savedRequests.count) active requests.")
    }
}
