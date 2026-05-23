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

    var playerEntity: PlayerEntity!

    var movementSystem = GKComponentSystem<MovementComponent>(
        componentClass: MovementComponent.self
    )
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
    
    private var tooFarBubbleTimer: TimeInterval = 0
    
    var currentDialogMessage: String?
    var yellowTutorialTargetHouseName: String? = nil
    
    let tutorialDuration: TimeInterval = 5.0
    
    var lastArrowDebugLogTime: TimeInterval = 0
    
    private var hasStartedFirstMove: Bool = false
    
    private let bounceAction: SKAction = {
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        let moveDown = moveUp.reversed()
        return SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
    }()
    
    private var bgmPlayer: AVAudioPlayer?

    override func didMove(to view: SKView) {
        print("[GameScene] Starting Scene initialization...")
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
        print(
            "[GameScene] Game Flow State Machine initialized in GamePlayingState."
        )

        print("[GameScene] Initialization complete. Game is ready to play!")
        
        print("[Tutorial] hasSeenJoystickTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial"))")
        print("[Tutorial] hasSeenYellowArrowTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial"))")
        print("[Tutorial] hasSeenRedArrowTutorial: \(UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial"))")
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            print("[Tutorial] Joystick tutorial deferred until background story is dismissed.")
        }
        
        restoreGameState()
        startAutoSaveTimer()
        playBGM()
    }
    
    func startTutorialIfNeeded() {
        currentPhase = .tutorial
        print("[GameScene] Phase changed to tutorial.")
        hasStartedFirstMove = false
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            print("[Tutorial] Showing joystick tutorial bubble.")
            updateJoystickTutorialBubblePosition()
        } else {
            print("[GameScene] Joystick tutorial already seen.")
            
            let activeCount = requestSystem?.houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count ?? 0
            let hasHeldPackage = deliverySystem?.activePackage != nil
            
            if activeCount == 0 && !hasHeldPackage {
                print("[GameScene] Spawning tutorial request immediately since none exist.")
                Task {
                    await requestSystem?.spawnTutorialRequestAsync()
                }
            } else {
                print("[GameScene] Tutorial request already exists. Waiting for player action.")
            }
        }
    }

    private func onFirstJoystickUse() {
        guard !hasStartedFirstMove else { return }
        hasStartedFirstMove = true
        
        print("[GameScene] First joystick use detected.")
        requestSystem?.fetchData()
        
        if currentPhase == .tutorial && !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            UserDefaults.standard.set(true, forKey: "hasSeenJoystickTutorial")
            onJoystickBubbleUpdate?(nil)
            
            let activeCount = requestSystem?.houses.filter { $0.component(ofType: RequestComponent.self) != nil }.count ?? 0
            let hasHeldPackage = deliverySystem?.activePackage != nil
            
            if activeCount == 0 && !hasHeldPackage {
                Task {
                    await requestSystem?.spawnTutorialRequestAsync()
                }
            }
            print("[GameScene] Joystick tutorial dismissed by movement. Spawned tutorial request.")
        }
    }

    private func updateJoystickTutorialBubblePosition() {
        guard !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") else { return }
        let viewWidth  = self.view?.bounds.width  ?? size.width
        let viewHeight = self.view?.bounds.height ?? size.height
        let screenX = joystick.baseNode.position.x + (viewWidth / 2)
        let screenY = -joystick.baseNode.position.y + (viewHeight / 2)
        
        let clampedX = min(max(screenX, 70), viewWidth - 70)
        let clampedY = screenY - 190
        
        let data = TutorialBubbleData(
            text: "Move Goldie using this joystick.",
            position: CGPoint(x: clampedX, y: clampedY),
            isInTopZone: false
        )
        onJoystickBubbleUpdate?(data)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase != .backgroundStory else { return }
        guard gameStateMachine?.currentState is GamePlayingState else { return }

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }

        let location = touch.location(in: cameraNode)
        joystick.processTouchBegan(location: location)
        
        if currentPhase == .tutorial {
            updateJoystickTutorialBubblePosition()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase != .backgroundStory else { return }
        guard gameStateMachine?.currentState is GamePlayingState else { return }

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }

        let locationInBase = touch.location(in: joystick.baseNode)

        joystick.processTouchMoved(locationInBase: locationInBase)

        if let movement = playerEntity.component(ofType: MovementComponent.self)
        {
            movement.velocity = joystick.currentVelocity
        }
        
        if currentPhase == .tutorial && joystick.currentVelocity != .zero {
            onFirstJoystickUse()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.processTouchEnded()

        let isInteracting =
            playerEntity.component(ofType: PlayerStateComponent.self)?
            .stateMachine?.currentState is PlayerInteractingState
        if isInteracting {
            if let movement = playerEntity.component(
                ofType: MovementComponent.self
            ) {
                movement.velocity = .zero
            }
            return
        }

        guard gameStateMachine?.currentState is GamePlayingState else {
            if let movement = playerEntity.component(
                ofType: MovementComponent.self
            ) {
                movement.velocity = .zero
            }
            return
        }

        if let movement = playerEntity.component(ofType: MovementComponent.self)
        {
            movement.velocity = joystick.currentVelocity
        }

        guard let touch = touches.first
        else { return }

        let locationInMap = touch.location(in: self)
        let tappedNodes = nodes(at: locationInMap)

        for node in tappedNodes {
            let name = node.name
            if name == "indicator_sender" || name == "indicator_receiver" {
                SoundManager.shared.play(.appearOnline)
                if let house = findHouseEntity(for: node) {
                    interactWithHouse(house)
                }
                break
            }
        }
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

    func setupPlayer() {
        let texture = SKTexture(imageNamed: "goldie_down_1")
        let playerNode = SKSpriteNode(
            texture: texture,
            size: GameConfig.playerFrontSize
        )
        playerNode.zPosition = GameConfig.playerZPosition
        playerNode.position = GameConfig.playerInitialPosition

        playerNode.physicsBody = SKPhysicsBody(
            circleOfRadius: GameConfig.playerPhysicsRadius
        )
        playerNode.physicsBody?.affectedByGravity = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 0.0

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

    private func findHouseEntity(for node: SKNode) -> HouseEntity? {
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

    private func interactWithHouse(_ house: HouseEntity) {
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
            print(
                "[GameScene] Error: Player or house visual component not found."
            )
            return
        }

        let dx = playerNode.position.x - houseNode.position.x
        let dy = playerNode.position.y - houseNode.position.y
        let distanceSquared = (dx * dx) + (dy * dy)

        if distanceSquared > GameConfig.interactionRadiusSquared {
            print(
                "[GameScene] Click ignored: Goldie is too far from \(houseName)'s house."
            )
            showTooFarIndicator(on: houseNode)
            return
        }

        guard let deliverySys = deliverySystem,
            let requestSys = requestSystem
        else {
            print(
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
                    print(
                        "[GameScene] Successfully picked up package from \(houseName)'s house."
                    )

                    if currentPhase == .tutorial && !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                        UserDefaults.standard.set(true, forKey: "hasSeenYellowArrowTutorial")
                        onYellowBubbleUpdate?(nil)
                    }

                    onPickUpSuccess?(request.sender.pickupDialog)
                }
            } else {
                print(
                    "[GameScene] \(houseName)'s house has no package to pick up."
                )
            }
        } else if let carryingState = deliverySys.stateMachine?.currentState
            as? CarryingState
        {
            guard let heldPackage = deliverySys.activePackage else { return }
            let receiverName = heldPackage.receiver.name
            if receiverName == houseName {
                print("[GameScene] Delivering package to \(houseName)...")
                carryingState.deliver()
                
                if currentPhase == .tutorial {
                    if !UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial") {
                        UserDefaults.standard.set(true, forKey: "hasSeenRedArrowTutorial")
                        onRedBubbleUpdate?(nil)
                    }
                    UserDefaults.standard.set(true, forKey: "hasFinishedTutorialPhase")
                    
                    currentPhase = .playing
                    print("[GameScene] Tutorial complete! Phase changed to playing. Spawning initial burst.")
                    requestSystem?.initialBurstSpawn()
                }
            } else {
                print(
                    "[GameScene] Wrong address! This package is for \(receiverName), not for \(houseName)."
                )
            }
        }
    }

    private func registerHousesAndStartSpawning() {
        guard let builder = mapBuilder,
            let reqSys = requestSystem
        else {
            print(
                "[GameScene] Failed to register houses: mapBuilder or requestSystem is nil."
            )
            return
        }
        guard reqSys.houses.isEmpty
        else { return }

        reqSys.houses = builder.environmentEntities.compactMap {
            $0 as? HouseEntity
        }
        print(
            "[GameScene] Successfully registered \(reqSys.houses.count) houses into the system."
        )

        reqSys.fetchData()
        
        restoreActiveRequests()

        if currentPhase == .playing {
            reqSys.initialBurstSpawn()
        } else if currentPhase == .tutorial {
            startTutorialIfNeeded()
        } else {
            print("[GameScene] Skipping initialBurstSpawn — waiting for background story to finish.")
        }
    }

    private func setupStateMachineIfNeeded() {
        guard let deliverySys = deliverySystem,
            let reqSys = requestSystem
        else { return }

        if deliverySys.stateMachine == nil {
            deliverySys.setupStateMachine(requestSystem: reqSys, scene: self)
            print(
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
            print("[GameScene] Gameplay resumed, entering PlayerIdleState.")
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
        
        print("[GameScene] Game reset to initial state. SwiftData cleared and re-seeded.")
    }
    
    private func playBGM() {
        bgmPlayer?.stop()
        bgmPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[BGM] Error setting up audio session: \(error)")
        }
        
        guard let url = Bundle.main.url(forResource: "1. Playground", withExtension: "m4a") else {
            print("[BGM] Error: Could not find BGM file in bundle")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            var targetVolume: Float = 1.0
            if UserDefaults.standard.object(forKey: "bgm") != nil {
                targetVolume = Float(UserDefaults.standard.double(forKey: "bgm") / 100.0)
            }
            player.volume = 0.0
            player.prepareToPlay()
            player.play()
            player.setVolume(targetVolume, fadeDuration: 2.0)
            self.bgmPlayer = player
            print("[BGM] Playing BGM with fade-in, target volume: \(targetVolume).")
        } catch {
            print("[BGM] Error initializing AVAudioPlayer: \(error)")
        }
    }
    
    func setBGMVolume(_ volume: Float) {
        bgmPlayer?.volume = volume
        print("[BGM] Volume set to \(volume).")
    }
    
    private(set) var sfxVolume: Float = {
        if UserDefaults.standard.object(forKey: "sfx") != nil {
            return Float(UserDefaults.standard.double(forKey: "sfx") / 100.0)
        }
        return 1.0
    }()
    
    func setSFXVolume(_ volume: Float) {
        sfxVolume = volume
        SoundManager.shared.setVolume(volume)
        print("[SFX] Volume set to \(volume).")
    }
    
    func saveGameState() {
        guard let playerNode = playerEntity?.component(ofType: RenderComponent.self)?.node else {
            print("[GameScene] Cannot save: player node not available.")
            return
        }
        
        let playerX = Double(playerNode.position.x)
        let playerY = Double(playerNode.position.y)
        
        var activeRequestSenderNames: [String] = []
        if let mapBuilder = mapBuilder {
            for entity in mapBuilder.environmentEntities {
                if let house = entity as? HouseEntity,
                   let requestComp = house.component(ofType: RequestComponent.self),
                   let ownerName = house.component(ofType: OwnerComponent.self)?.characterName {
                    let request = requestComp.request
                    if !request.isCompleted {
                        activeRequestSenderNames.append(ownerName)
                    }
                }
            }
        }
        
        GameDataManager.shared.saveGameState(
            playerX: playerX,
            playerY: playerY,
            activeRequestSenderNames: activeRequestSenderNames
        )
    }
    
    func restoreGameState() {
        if let profile = GameDataManager.shared.fetchPlayerProfile() {
            let savedX = CGFloat(profile.positionX)
            let savedY = CGFloat(profile.positionY)
            
            if savedX != 0 || savedY != 0 {
                if let playerNode = playerEntity?.component(ofType: RenderComponent.self)?.node {
                    playerNode.position = CGPoint(x: savedX, y: savedY)
                    print("[GameScene] Player position restored to (\(savedX), \(savedY))")
                }
            }
        }
    }
    
    private func restoreActiveRequests() {
        let pendingRequests = GameDataManager.shared.fetchPendingRequests()
        let savedSenderNames = GameDataManager.shared.loadActiveRequestSenderNames()
        
        var restoredCount = 0
        if let mapBuilder = mapBuilder, !pendingRequests.isEmpty {
            for request in pendingRequests {
                let senderName = request.sender.name
                
                guard savedSenderNames.contains(senderName) else {
                    GameDataManager.shared.context?.delete(request)
                    continue
                }
                
                if let house = mapBuilder.environmentEntities.first(where: {
                    ($0 as? HouseEntity)?.component(ofType: OwnerComponent.self)?.characterName == senderName
                }) as? HouseEntity {
                    guard house.component(ofType: RequestComponent.self) == nil else { continue }
                    
                    let component = RequestComponent(request: request)
                    house.addComponent(component)
                    requestSystem?.system.addComponent(component)
                    restoredCount += 1
                }
            }
            GameDataManager.shared.save()
        }
        
        if let pickedUpRequest = GameDataManager.shared.fetchPickedUpRequests().first {
            deliverySystem?.pickUpPackage(request: pickedUpRequest, for: playerEntity)
            deliverySystem?.stateMachine?.enter(CarryingState.self)
            print("[GameScene] Restored carried request from \(pickedUpRequest.sender.name) to \(pickedUpRequest.receiver.name).")
        }
        
        print("[GameScene] Restored \(restoredCount) active requests from saved state.")
    }
    
    func startAutoSaveTimer() {
        let autoSaveAction = SKAction.sequence([
            SKAction.wait(forDuration: 30.0),
            SKAction.run { [weak self] in
                self?.saveGameState()
            }
        ])
        self.run(SKAction.repeatForever(autoSaveAction), withKey: "autoSave")
        print("[GameScene] Auto-save timer started (every 30 seconds).")
    }
    
    private func updateIndicators() {
        guard let mapBuilder = mapBuilder,
            let playerNode = playerEntity.component(
                ofType: RenderComponent.self
            )?.node
        else { return }

        let targetReceiverName = deliverySystem?.activePackage?.receiver.name
        let isHoldingPackage = deliverySystem?.activePackage != nil

        for entity in mapBuilder.environmentEntities {
            if let house = entity as? HouseEntity,
                let houseNode = house.component(ofType: RenderComponent.self)?
                    .node as? SKSpriteNode
            {
                let isSender =
                    house.component(ofType: RequestComponent.self) != nil
                let isTarget =
                    (targetReceiverName != nil)
                    && (targetReceiverName
                        == house.component(ofType: OwnerComponent.self)?
                        .characterName)

                let dx = playerNode.position.x - houseNode.position.x
                let dy = playerNode.position.y - houseNode.position.y
                let distanceSquared = (dx * dx) + (dy * dy)
                let isWithinRange =
                    distanceSquared <= GameConfig.interactionRadiusSquared

                let senderIcon = houseNode.childNode(withName: "indicator_sender") as? SKSpriteNode
                let receiverIcon = houseNode.childNode(withName: "indicator_receiver") as? SKSpriteNode

                senderIcon?.isHidden = !isSender || isHoldingPackage
                receiverIcon?.isHidden = !isTarget

                senderIcon?.zRotation = -houseNode.zRotation
                receiverIcon?.zRotation = -houseNode.zRotation

                if isSender {
                    if senderIcon?.action(forKey: "bounce") == nil {
                        senderIcon?.run(bounceAction, withKey: "bounce")
                    }
                } else {
                    senderIcon?.removeAction(forKey: "bounce")
                }

                if isTarget {
                    if receiverIcon?.action(forKey: "bounce") == nil {
                        receiverIcon?.run(bounceAction, withKey: "bounce")
                    }
                } else {
                    receiverIcon?.removeAction(forKey: "bounce")
                }

                if isSender && isWithinRange && !isHoldingPackage {
                    if senderIcon?.action(forKey: "highlight") == nil {
                        let pulse = SKAction.sequence([
                            SKAction.scale(to: 1.15, duration: 0.25),
                            SKAction.scale(to: 1.0,  duration: 0.25)
                        ])
                        senderIcon?.run(SKAction.repeatForever(pulse), withKey: "highlight")
                        senderIcon?.color = .yellow
                        senderIcon?.colorBlendFactor = 0.12
                    }
                } else {
                    senderIcon?.removeAction(forKey: "highlight")
                    senderIcon?.setScale(1.0)
                    senderIcon?.colorBlendFactor = 0.0
                }

                if isTarget && isWithinRange {
                    if receiverIcon?.action(forKey: "highlight") == nil {
                        let pulse = SKAction.sequence([
                            SKAction.scale(to: 1.15, duration: 0.25),
                            SKAction.scale(to: 1.0,  duration: 0.25)
                        ])
                        receiverIcon?.run(SKAction.repeatForever(pulse), withKey: "highlight")
                        receiverIcon?.color = .red
                        receiverIcon?.colorBlendFactor = 0.12
                    }
                } else {
                    receiverIcon?.removeAction(forKey: "highlight")
                    receiverIcon?.setScale(1.0)
                    receiverIcon?.colorBlendFactor = 0.0
                }

                if let oldHighlight = houseNode.childNode(withName: "indicator_highlight") {
                    oldHighlight.removeFromParent()
                }
            }
        }
    }

    private func showTooFarIndicator(on houseNode: SKNode) {
        tooFarBubbleTimer = 2.0
        updateTooFarBubblePosition()
    }
    
    private func updateTooFarBubblePosition() {
        guard let view = self.view,
              let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node else { return }
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        
        let absoluteScenePos = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 140)
        let relativePos = cameraNode.convert(absoluteScenePos, from: self)
        let screenX = relativePos.x + (viewWidth / 2)
        let screenY = -relativePos.y + (viewHeight / 2)
        
        let data = TooFarBubbleData(
            text: "Too far away.",
            position: CGPoint(x: screenX, y: screenY)
        )
        onTooFarBubbleUpdate?(data)
    }
    
    private func updateScreenEdgeArrows(viewWidth: CGFloat, viewHeight: CGFloat) {
        cameraNode.enumerateChildNodes(withName: "edge_arrow") { node, _ in node.removeFromParent() }
        
        guard currentPhase != .backgroundStory else {
            onJoystickBubbleUpdate?(nil)
            onYellowBubbleUpdate?(nil)
            onRedBubbleUpdate?(nil)
            return
        }

        if UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            onJoystickBubbleUpdate?(nil)
        }

        guard let mapBuilder = mapBuilder else {
            return
        }

        let screenWidth = self.size.width
        let screenHeight = self.size.height

        let padding: CGFloat = 45.0
        let ovalRadiusX = (screenWidth / 2) - padding
        let ovalRadiusY = (screenHeight / 2) - padding

        let topZoneThreshold: CGFloat = 0
        let horizontalThreshold: CGFloat = 60
        let horizontalYOffset: CGFloat = 60
        
        let hasActivePackage = deliverySystem?.activePackage != nil
        
        let now0 = CACurrentMediaTime()
        let shouldLog = now0 - lastArrowDebugLogTime >= 2.0
        if shouldLog {
            lastArrowDebugLogTime = now0
            let dsStatus = deliverySystem != nil ? "ALIVE" : "NIL"
            let apStatus = hasActivePackage ? "YES" : "NO"
            print("[Arrow DEBUG] deliverySystem=\(dsStatus), activePackage=\(apStatus)")
        }
        
        if let activePackage = deliverySystem?.activePackage {
            onYellowBubbleUpdate?(nil)
            
            let receiverName = activePackage.receiver.name
            if let targetHouse = mapBuilder.environmentEntities.first(where: {
                ($0 as? HouseEntity)?.component(ofType: OwnerComponent.self)?.characterName == receiverName
            }) as? HouseEntity, let houseNode = targetHouse.component(ofType: RenderComponent.self)?.node {
                
                let arrowNode = createArrowNode(to: houseNode.position, assetName: "arrow_red", ovalX: ovalRadiusX, ovalY: ovalRadiusY, viewW: viewWidth, viewH: viewHeight)
                
                if shouldLog {
                    print("[Arrow DEBUG] RED: receiver=\(receiverName), houseFound=YES, arrowCreated=\(arrowNode != nil)")
                }
                
                if !UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial") {
                    if let validArrow = arrowNode {
                        let data = calculateTutorialBubbleData(
                            arrowNode: validArrow,
                            text: "Follow the red arrow to deliver the parcel.",
                            viewWidth: viewWidth,
                            viewHeight: viewHeight,
                            topZoneThreshold: topZoneThreshold,
                            horizontalThreshold: horizontalThreshold,
                            horizontalYOffset: horizontalYOffset
                        )
                        onRedBubbleUpdate?(data)
                    } else {
                        onRedBubbleUpdate?(nil)
                    }
                }
            } else {
                print("[Arrow] RED: Target house not found for receiver: \(receiverName)")
                onRedBubbleUpdate?(nil)
            }
        } else {
            onRedBubbleUpdate?(nil)
            
            let allRequestingHouses = mapBuilder.environmentEntities
                .compactMap { $0 as? HouseEntity }
                .filter { $0.component(ofType: RequestComponent.self) != nil }
            
            if shouldLog {
                print("[Arrow DEBUG] YELLOW: requestingHouses=\(allRequestingHouses.count)")
            }
            
            if yellowTutorialTargetHouseName == nil, let firstTarget = allRequestingHouses.first?.component(ofType: OwnerComponent.self)?.characterName {
                yellowTutorialTargetHouseName = firstTarget
            }
            
            var didShowYellowTutorialBubble = false
            
            for house in allRequestingHouses {
                guard let name = house.component(ofType: OwnerComponent.self)?.characterName,
                      let houseNode = house.component(ofType: RenderComponent.self)?.node else { continue }
                
                let arrowNode = createArrowNode(
                    to: houseNode.position,
                    assetName: "arrow_yellow",
                    ovalX: ovalRadiusX,
                    ovalY: ovalRadiusY,
                    viewW: viewWidth,
                    viewH: viewHeight
                )
                
                if name == yellowTutorialTargetHouseName,
                   !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                    
                    if let validArrow = arrowNode {
                        let data = calculateTutorialBubbleData(
                            arrowNode: validArrow,
                            text: "Follow the yellow arrow to pick up the parcel.",
                            viewWidth: viewWidth,
                            viewHeight: viewHeight,
                            topZoneThreshold: topZoneThreshold,
                            horizontalThreshold: horizontalThreshold,
                            horizontalYOffset: horizontalYOffset
                        )
                        onYellowBubbleUpdate?(data)
                        didShowYellowTutorialBubble = true
                    }
                }
            }
            
            if !didShowYellowTutorialBubble && !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                onYellowBubbleUpdate?(nil)
            }
        }
    }
    
    private func calculateTutorialBubbleData(
        arrowNode: SKNode,
        text: String,
        viewWidth: CGFloat,
        viewHeight: CGFloat,
        topZoneThreshold: CGFloat,
        horizontalThreshold: CGFloat,
        horizontalYOffset: CGFloat
    ) -> TutorialBubbleData {
        let screenX = arrowNode.position.x + (viewWidth / 2)
        let screenY = -arrowNode.position.y + (viewHeight / 2)
        
        let isInTopZone = arrowNode.position.y > topZoneThreshold
        let isHorizontallyAligned = abs(arrowNode.position.y) < horizontalThreshold
        
        let clampedX = min(max(screenX, 70), viewWidth - 70)
        
        let clampedY: CGFloat
        let finalIsInTopZone: Bool
        if isHorizontallyAligned {
            clampedY = screenY - (horizontalYOffset * 2)
            finalIsInTopZone = false 
        } else {
            clampedY = screenY + (isInTopZone ? horizontalYOffset : -(horizontalYOffset * 2))
            finalIsInTopZone = isInTopZone
        }
        
        return TutorialBubbleData(
            text: text,
            position: CGPoint(x: clampedX, y: clampedY),
            isInTopZone: finalIsInTopZone
        )
    }
    
    private func createArrowNode(to targetPosition: CGPoint, assetName: String, ovalX: CGFloat, ovalY: CGFloat, viewW: CGFloat, viewH: CGFloat) -> SKSpriteNode? {
        let dx = targetPosition.x - cameraNode.position.x
        let dy = targetPosition.y - cameraNode.position.y

        let safetyMargin: CGFloat = 50.0
        if abs(dx) < (viewW / 2) - safetyMargin
            && abs(dy) < (viewH / 2) - safetyMargin
        {
            return nil
        }

        let angle = atan2(dy, dx)

        let arrowX = ovalX * cos(angle)
        let arrowY = ovalY * sin(angle)

        let arrowNode = SKSpriteNode(imageNamed: assetName)
        arrowNode.name = "edge_arrow"
        arrowNode.size = CGSize(width: 45, height: 45)
        arrowNode.position = CGPoint(x: arrowX, y: arrowY)

        arrowNode.zRotation = angle - GameConfig.arrowAssetDirection
        arrowNode.zPosition = 90_000

        cameraNode.addChild(arrowNode)
        return arrowNode
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
        debugOptions: [.showsPhysics]
    )
    .ignoresSafeArea()
}
