//
//  GameScene.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 04/05/26.
//

import GameplayKit
import SpriteKit
import SwiftData
import SwiftUI
import AVFoundation

class GameScene: SKScene {

    enum FacingDirection { case front, back, left, right }
    var playerEntity: PlayerEntity!
    var playerNode: SKSpriteNode!
    var currentFacing: FacingDirection = .front
    
    // Pre-built physics bodies (allocated once, swapped on direction change)
    var physicsBodyRight: SKPhysicsBody!
    var physicsBodyLeft: SKPhysicsBody!
    var physicsBodyFrontBack: SKPhysicsBody!
    
    var movementSystem = GKComponentSystem<MovementComponent>(componentClass: MovementComponent.self)
    var gameStateMachine: GKStateMachine?
    weak var deliverySystem: DeliverySystem? {
        didSet {
            setupStateMachineIfNeeded()
        }
    }
    weak var requestSystem: RequestSystem? {
        didSet {
            setupStateMachineIfNeeded()
            registerHousesAndStartSpawning()
        }
    }
    
    let cameraNode = SKCameraNode()
    let joystick = JoystickController()
    var mapBuilder: MapBuilder!
    var previousTime: TimeInterval = 0
    
    var onPickUpSuccess: ((String) -> Void)?
    var onDeliverySuccess: ((Int, Bool, Collectible?) -> Void)?
    var onLetterReady: ((Request) -> Void)?
    var onJoystickBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onYellowBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onRedBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onTooFarBubbleUpdate: ((TooFarBubbleData?) -> Void)?
    
    var currentPhase: GamePhase = .backgroundStory
    var tooFarBubbleTimer: TimeInterval = 0
    var currentDialogMessage: String?
    var yellowTutorialTargetHouseName: String? = nil
    let tutorialDuration: TimeInterval = 5.0
    var lastArrowDebugLogTime: TimeInterval = 0
    var hasStartedFirstMove: Bool = false
    
    let bounceAction: SKAction = {
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        let moveDown = moveUp.reversed()
        return SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
    }()
    
    var bgmPlayer: AVAudioPlayer?
    
    var sfxVolume: Float = {
        if UserDefaults.standard.object(forKey: "sfx") != nil {
            return Float(UserDefaults.standard.double(forKey: "sfx") / 100.0)
        }
        return 1.0
    }()

    override func didMove(to view: SKView) {
        debugLog("[GameScene] Starting Scene initialization...")
        self.anchorPoint = CGPoint(x: 0, y: 0)

        cameraNode.zPosition = 100_000
        cameraNode.setScale(GameConfig.cameraScale)
        self.camera = cameraNode
        addChild(cameraNode)

        mapBuilder = MapBuilder(scene: self)
        mapBuilder.build(worldMap)

        setupPlayer()
        setupInvisibleWalls()
        joystick.attach(to: cameraNode, screenHeight: self.size.height)

        registerHousesAndStartSpawning()

        let states = [
            GamePlayingState(scene: self),
            GamePausedState(scene: self),
        ]
        gameStateMachine = GKStateMachine(states: states)
        gameStateMachine?.enter(GamePlayingState.self)
        debugLog("[GameScene] Game Flow State Machine initialized in GamePlayingState.")

        debugLog("[GameScene] Initialization complete. Game is ready to play!")
        
        debugLog("[Tutorial] hasSeenJoystickTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial"))")
        debugLog("[Tutorial] hasSeenYellowArrowTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial"))")
        debugLog("[Tutorial] hasSeenRedArrowTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial"))")
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            debugLog("[Tutorial] Joystick tutorial deferred until background story is dismissed.")
        }
        
        restoreGameState()
        startAutoSaveTimer()
        playBGM()
    }

    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 {
            previousTime = currentTime
        }

        let deltaTime = currentTime - previousTime
        previousTime = currentTime
        deliverySystem?.update(deltaTime: deltaTime)
        playerEntity.update(deltaTime: deltaTime)
        movementSystem.update(deltaTime: deltaTime)
        gameStateMachine?.update(deltaTime: deltaTime)
        
        updatePhysicsIfDirectionChanged()
        updateIndicators()
        
        if tooFarBubbleTimer > 0 {
            tooFarBubbleTimer -= deltaTime
            if tooFarBubbleTimer <= 0 {
                tooFarBubbleTimer = 0
                onTooFarBubbleUpdate?(nil)
            } else {
                updateTooFarBubblePosition()
            }
        }
    }

    override func didSimulatePhysics() {
        super.didSimulatePhysics()
        
        if let playerNode = playerEntity.component(
            ofType: RenderComponent.self
        )?.node {
            let viewWidth = self.size.width * cameraNode.xScale
            let viewHeight = self.size.height * cameraNode.yScale

            let mapWidth = worldMap.groundSize.width
            let mapHeight = worldMap.groundSize.height

            let xPos = max(
                viewWidth / 2,
                min(playerNode.position.x, mapWidth - viewWidth / 2)
            )
            let yPos = max(
                viewHeight / 2,
                min(playerNode.position.y, mapHeight - viewHeight / 2)
            )

            cameraNode.position = CGPoint(x: xPos, y: yPos)
            playerNode.zPosition = 10000 - playerNode.position.y

            updateScreenEdgeArrows(viewWidth: viewWidth, viewHeight: viewHeight)

            if let mapBuilder = mapBuilder {
                var closestHouse: HouseEntity? = nil
                var minDistanceSquared: CGFloat = GameConfig
                    .interactionRadiusSquared

                for entity in mapBuilder.environmentEntities {
                    if let house = entity as? HouseEntity,
                        let houseNode = house.component(
                            ofType: RenderComponent.self
                        )?.node
                    {
                        let dx = playerNode.position.x - houseNode.position.x
                        let dy = playerNode.position.y - houseNode.position.y
                        let distanceSquared = (dx * dx) + (dy * dy)

                        if distanceSquared < minDistanceSquared {
                            minDistanceSquared = distanceSquared
                            closestHouse = house
                        }
                    }
                }

                if deliverySystem?.nearbyHouse != closestHouse {
                    self.deliverySystem?.nearbyHouse = closestHouse
                }
            }
        }
    }
    
    func setFacing(_ direction: FacingDirection) {
        guard direction != currentFacing else { return }
        currentFacing = direction

        switch direction {
        case .right:
            applyPhysics(isFacingRight: true)
        case .left:
            applyPhysics(isFacingRight: false)
        case .front, .back:
            applyPhysics(isFacingRight: nil)
        }
    }
    
    /// Membuat compound physics body untuk arah tertentu (dipanggil sekali saat init).
    /// - Parameter isFacingRight: true = kanan, false = kiri, nil = depan/belakang
    private func buildPhysicsBody(isFacingRight: Bool?) -> SKPhysicsBody {
        let headRadius: CGFloat = 15.0
        let bodyRadiusSmall: CGFloat = 15.0
        var physicsBodies: [SKPhysicsBody] = []

        switch isFacingRight {
        case true:
            physicsBodies = [
                SKPhysicsBody(circleOfRadius: headRadius, center: CGPoint(x: 20, y: 20)),
                SKPhysicsBody(circleOfRadius: bodyRadiusSmall, center: CGPoint(x: -10, y: -6)),
                SKPhysicsBody(circleOfRadius: bodyRadiusSmall, center: CGPoint(x: 15, y: -6))
            ]
        case false:
            physicsBodies = [
                SKPhysicsBody(circleOfRadius: headRadius, center: CGPoint(x: -20, y: 20)),
                SKPhysicsBody(circleOfRadius: bodyRadiusSmall, center: CGPoint(x: 10, y: -6)),
                SKPhysicsBody(circleOfRadius: bodyRadiusSmall, center: CGPoint(x: -15, y: -6))
            ]
        case nil:
            physicsBodies = [
                SKPhysicsBody(circleOfRadius: headRadius, center: CGPoint(x: 0, y: 20)),
                SKPhysicsBody(circleOfRadius: 20.0, center: CGPoint(x: 0, y: 0))
            ]
        }

        let body = SKPhysicsBody(bodies: physicsBodies)
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0.0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.obstacle
        return body
    }
    
    /// Swap physics body dari pre-built pool (tanpa alokasi baru).
    /// - Parameter isFacingRight: true = kanan, false = kiri, nil = depan/belakang
    func applyPhysics(isFacingRight: Bool?) {
        let targetBody: SKPhysicsBody
        switch isFacingRight {
        case true:  targetBody = physicsBodyRight
        case false: targetBody = physicsBodyLeft
        case nil:   targetBody = physicsBodyFrontBack
        }
        
        // Hanya swap jika physics body berbeda
        guard playerNode.physicsBody !== targetBody else { return }
        
        let currentVelocity = playerNode.physicsBody?.velocity ?? .zero
        playerNode.physicsBody = targetBody
        playerNode.physicsBody?.velocity = currentVelocity
    }

    /// Panggil ini setiap kali arah karakter berubah.
    /// Hanya update physics jika arah benar-benar berubah (efisien).
    func updatePhysicsIfDirectionChanged() {
        guard let movement = playerEntity.component(ofType: MovementComponent.self) else { return }
        let velocity = movement.velocity
        guard velocity != .zero else { return }

        let isMovingHorizontally = abs(velocity.x) > abs(velocity.y)

        if isMovingHorizontally {
            setFacing(velocity.x > 0 ? .right : .left)
        } else {
            setFacing(velocity.y > 0 ? .back : .front)
        }
    }
    
    func setupPlayer() {
        let texture = SKTexture(imageNamed: "goldie_front_1")
        playerNode = SKSpriteNode(texture: texture, size: GameConfig.playerFrontSize)
        playerNode.zPosition = GameConfig.playerZPosition
        playerNode.position = GameConfig.playerInitialPosition
        
        // Pre-build 3 physics bodies sekali saat init (tidak ada alokasi ulang)
        physicsBodyRight = buildPhysicsBody(isFacingRight: true)
        physicsBodyLeft = buildPhysicsBody(isFacingRight: false)
        physicsBodyFrontBack = buildPhysicsBody(isFacingRight: nil)
        
        applyPhysics(isFacingRight: nil)

        addChild(playerNode)

        playerEntity = PlayerEntity(node: playerNode)
        playerEntity.addComponent(PlayerStateComponent(scene: self))
        movementSystem.addComponent(foundIn: playerEntity)
    }

    private func setupInvisibleWalls() {
        let mapSize = worldMap.groundSize

        let boundaryRect = CGRect(
            x: 0,
            y: 0,
            width: mapSize.width,
            height: mapSize.height
        )

        self.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryRect)
        self.physicsBody?.friction = 0.0
    }

    func findHouseEntity(for node: SKNode) -> HouseEntity? {
        var currentNode: SKNode? = node
        while let check = currentNode {
            if let houseEntity = mapBuilder?.environmentEntities.first(where: {
                ($0 as? HouseEntity)?.component(ofType: RenderComponent.self)?
                    .node == check
            }) as? HouseEntity {
                return houseEntity
            }
            currentNode = check.parent
        }

        return nil
    }

    func interactWithHouse(_ house: HouseEntity) {
        let houseName =
            house.component(ofType: OwnerComponent.self)?.characterName
            ?? "Unknown"

        let isHoldingPackage = deliverySystem?.activePackage != nil
        let isSender = house.component(ofType: RequestComponent.self) != nil
        let isTarget =
            (deliverySystem?.activePackage?.receiver.name != nil)
            && (deliverySystem?.activePackage?.receiver.name
                == house.component(ofType: OwnerComponent.self)?.characterName)

        if isHoldingPackage {
            guard isTarget else { return }
        } else {
            guard isSender else { return }
        }

        guard
            let playerNode = playerEntity.component(
                ofType: RenderComponent.self
            )?.node,
            let houseNode = house.component(ofType: RenderComponent.self)?.node
        else {
            debugLog(
                "[GameScene] Error: Player or house visual component not found."
            )
            return
        }

        let dx = playerNode.position.x - houseNode.position.x
        let dy = playerNode.position.y - houseNode.position.y
        let distanceSquared = (dx * dx) + (dy * dy)

        if distanceSquared > GameConfig.interactionRadiusSquared {
            debugLog(
                "[GameScene] Click ignored: Goldie is too far from \(houseName)'s house."
            )
            showTooFarIndicator(on: houseNode)
            return
        }

        guard let deliverySys = deliverySystem,
            let requestSys = requestSystem
        else {
            debugLog(
                "[GameScene] Error: Delivery System or Request System has not been injected!"
            )
            return
        }

        if let waitingState = deliverySys.stateMachine?.currentState
            as? WaitingForPickupState
        {
            if house.component(ofType: RequestComponent.self) != nil {
                if let request = requestSys.pickupRequest(house) {
                    waitingState.pickUp(request: request, player: playerEntity)
                    debugLog(
                        "[GameScene] Successfully picked up package from \(houseName)'s house."
                    )

                    if currentPhase == .tutorial && !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                        UserDefaults.standard.set(true, forKey: "hasSeenYellowArrowTutorial")
                        onYellowBubbleUpdate?(nil)
                    }

                    onPickUpSuccess?(request.sender.pickupDialog)
                }
            } else {
                debugLog(
                    "[GameScene] \(houseName)'s house has no package to pick up."
                )
            }
        } else if let carryingState = deliverySys.stateMachine?.currentState
            as? CarryingState
        {
            guard let heldPackage = deliverySys.activePackage else { return }
            let receiverName = heldPackage.receiver.name
            if receiverName == houseName {
                debugLog("[GameScene] Delivering package to \(houseName)...")
                carryingState.deliver()
                
                if currentPhase == .tutorial {
                    if !UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial") {
                        UserDefaults.standard.set(true, forKey: "hasSeenRedArrowTutorial")
                        onRedBubbleUpdate?(nil)
                    }
                    UserDefaults.standard.set(true, forKey: "hasFinishedTutorialPhase")
                    
                    currentPhase = .playing
                    debugLog("[GameScene] Tutorial complete! Phase changed to playing. Spawning initial burst.")
                    requestSystem?.initialBurstSpawn()
                }
            } else {
                debugLog(
                    "[GameScene] Wrong address! This package is for \(receiverName), not for \(houseName)."
                )
            }
        }
    }

    func registerHousesAndStartSpawning() {
        guard let builder = mapBuilder,
            let reqSys = requestSystem
        else {
            debugLog(
                "[GameScene] Failed to register houses: mapBuilder or requestSystem is nil."
            )
            return
        }
        guard reqSys.houses.isEmpty
        else { return }

        reqSys.houses = builder.environmentEntities.compactMap {
            $0 as? HouseEntity
        }
        debugLog(
            "[GameScene] Successfully registered \(reqSys.houses.count) houses into the system."
        )

        reqSys.fetchData()
        
        restoreActiveRequests()

        if currentPhase == .playing {
            reqSys.initialBurstSpawn()
        } else if currentPhase == .tutorial {
            startTutorialIfNeeded()
        } else {
            debugLog("[GameScene] Skipping initialBurstSpawn — waiting for background story to finish.")
        }
    }

    private func setupStateMachineIfNeeded() {
        guard let deliverySys = deliverySystem,
            let reqSys = requestSystem
        else { return }

        if deliverySys.stateMachine == nil {
            deliverySys.setupStateMachine(requestSystem: reqSys, scene: self)
            debugLog(
                "[GameScene] Delivery State Machine setup completed successfully."
            )
        }
    }

    func resumeGameplay() {
        gameStateMachine?.enter(GamePlayingState.self)
        if let stateComponent = playerEntity.component(
            ofType: PlayerStateComponent.self
        ) {
            stateComponent.stateMachine?.enter(PlayerIdleState.self)
            debugLog("[GameScene] Gameplay resumed, entering PlayerIdleState.")
        }
    }
    
    func resetGame() {
        requestSystem?.cancelAllSpawns()
        
        UserDefaults.standard.set(false, forKey: "hasSeenJoystickTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenYellowArrowTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenRedArrowTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenBackgroundStory")
        UserDefaults.standard.set(false, forKey: "hasFinishedTutorialPhase")
        
        hasStartedFirstMove = false
        currentDialogMessage = nil
        yellowTutorialTargetHouseName = nil
        
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = .zero
        }
        joystick.processTouchEnded()
        
        if let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node {
            playerNode.position = GameConfig.playerInitialPosition
        }
        
        deliverySystem?.activePackage = nil
        if let deliveryComp = playerEntity.component(ofType: DeliveryComponent.self) {
            deliveryComp.activeRequest = nil
        }
        deliverySystem?.stateMachine?.enter(NoActiveRequestState.self)
        
        if let mapBuilder = mapBuilder {
            for entity in mapBuilder.environmentEntities {
                if let house = entity as? HouseEntity,
                   let reqComp = house.component(ofType: RequestComponent.self) {
                    requestSystem?.system.removeComponent(reqComp)
                    house.removeComponent(ofType: RequestComponent.self)
                }
            }
        }
        
        tooFarBubbleTimer = 0
        onTooFarBubbleUpdate?(nil)
        onJoystickBubbleUpdate?(nil)
        onYellowBubbleUpdate?(nil)
        onRedBubbleUpdate?(nil)
        
        currentPhase = .backgroundStory
        
        gameStateMachine?.enter(GamePlayingState.self)
        
        if let context = GameDataManager.shared.context {
            SeederDatabase.clearDatabase(context: context)
            SeederDatabase.seedDatabaseIfNeeded(context: context)
        }
        
        requestSystem?.fetchData()
        
        playBGM()
        
        debugLog("[GameScene] Game reset to initial state. SwiftData cleared and re-seeded.")
    }
    
    func drawDebugGrid(gridSize: CGFloat) {
        let path = CGMutablePath()

        let worldRadius: CGFloat = GameConfig.worldSize.width
        let start = 0.0
        let end = worldRadius

        for x in stride(from: start, through: end, by: gridSize) {
            path.move(to: CGPoint(x: x, y: start))
            path.addLine(to: CGPoint(x: x, y: end))
        }

        for y in stride(from: start, through: end, by: gridSize) {
            path.move(to: CGPoint(x: start, y: y))
            path.addLine(to: CGPoint(x: end, y: y))
        }

        let gridNode = SKShapeNode(path: path)

        gridNode.strokeColor = UIColor.white.withAlphaComponent(0.3)
        gridNode.lineWidth = 2
        gridNode.zPosition = 90
        addChild(gridNode)

        let centerPath = CGMutablePath()
        centerPath.move(to: CGPoint(x: -50, y: 0))
        centerPath.addLine(to: CGPoint(x: 50, y: 0))
        centerPath.move(to: CGPoint(x: 0, y: -50))
        centerPath.addLine(to: CGPoint(x: 0, y: 50))

        let centerNode = SKShapeNode(path: centerPath)
        centerNode.strokeColor = .red
        centerNode.lineWidth = 5
        centerNode.zPosition = 91
        addChild(centerNode)
    }
}

#Preview {
    SpriteView(
        scene: {
            let scene = GameScene()
            scene.size = CGSize(width: 375, height: 812)
            scene.scaleMode = .aspectFill
            return scene
        }(),
        // debugOptions: [.showsPhysics]
    )
    .ignoresSafeArea()
}
