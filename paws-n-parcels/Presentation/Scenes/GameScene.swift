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
    
    var onJoystickBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onYellowBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onRedBubbleUpdate: ((TutorialBubbleData?) -> Void)?
    var onTooFarBubbleUpdate: ((TooFarBubbleData?) -> Void)?
    
    var currentPhase: GamePhase = .backgroundStory
    
    private var tooFarBubbleTimer: TimeInterval = 0
    
    var hasShownYellowArrowTutorialTimer: Bool = false
    var hasShownRedArrowTutorialTimer: Bool = false
    
    var currentDialogMessage: String?
    
    var yellowTutorialStartTime: TimeInterval? = nil
    var yellowTutorialTargetHouseName: String? = nil
    var redTutorialStartTime: TimeInterval? = nil
    let tutorialDuration: TimeInterval = 8.0
    
    var lastArrowDebugLogTime: TimeInterval = 0
    
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

        // drawDebugGrid(gridSize: 100)
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
        
        // Start spawning requests now that the background story has been dismissed
        requestSystem?.fetchData()
        requestSystem?.initialBurstSpawn()
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            print("[Tutorial] Showing joystick tutorial bubble")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                UserDefaults.standard.set(true, forKey: "hasSeenJoystickTutorial")
                self.onJoystickBubbleUpdate?(nil)
                self.currentPhase = .playing
                print("[GameScene] Phase changed to playing.")
            }
        } else {
            currentPhase = .playing
            print("[GameScene] No tutorial needed, phase changed to playing.")
        }
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
            if let house = findHouseEntity(for: node) {
                interactWithHouse(house)
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

        // Circular physics body matching Goldie's footprint
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
        
        // Only spawn requests immediately if the game is already past the background story.
        // If still in backgroundStory phase, spawning is deferred to startTutorialIfNeeded().
        if currentPhase != .backgroundStory {
            reqSys.initialBurstSpawn()
        } else {
            print("[GameScene] Skipping initialBurstSpawn — background story not yet dismissed.")
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
        UserDefaults.standard.set(false, forKey: "hasSeenJoystickTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenYellowArrowTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenRedArrowTutorial")
        UserDefaults.standard.set(false, forKey: "hasSeenBackgroundStory")
        
        hasShownYellowArrowTutorialTimer = false
        hasShownRedArrowTutorialTimer = false
        currentDialogMessage = nil
        yellowTutorialStartTime = nil
        yellowTutorialTargetHouseName = nil
        redTutorialStartTime = nil
        
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
        
        UserDefaults.standard.removeObject(forKey: "activeRequestSenderNames")
        GameDataManager.shared.savePlayerPosition(
            x: Double(GameConfig.playerInitialPosition.x),
            y: Double(GameConfig.playerInitialPosition.y)
        )
        GameDataManager.shared.deleteAllPendingRequests()
        
        // fetchData and initialBurstSpawn are intentionally NOT called here.
        // Request generation is deferred until startTutorialIfNeeded() is called
        // when the player taps "Tap to start" on the background story screen.
        
        playBGM()
        
        print("[GameScene] Game reset to initial state.")
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
            player.volume = 0.0
            player.prepareToPlay()
            player.play()
            player.setVolume(1.0, fadeDuration: 2.0)
            self.bgmPlayer = player
            print("[BGM] Playing BGM with fade-in.")
        } catch {
            print("[BGM] Error initializing AVAudioPlayer: \(error)")
        }
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

                var highlight =
                    houseNode.childNode(withName: "indicator_highlight")
                    as? SKSpriteNode
                if highlight == nil {
                    let houseTexture = houseNode.texture ?? SKTexture(imageNamed: "house_1")
                    let highlightSize = houseNode.size
                    
                    let h = SKSpriteNode(texture: houseTexture, size: highlightSize)
                    h.name = "indicator_highlight"
                    h.color = .clear
                    h.colorBlendFactor = 1.0
                    h.zPosition = -1
                    
                    h.physicsBody = SKPhysicsBody(texture: houseTexture, size: highlightSize)
                    h.physicsBody?.isDynamic = false
                    h.physicsBody?.categoryBitMask = 0
                    h.physicsBody?.collisionBitMask = 0
                    h.physicsBody?.contactTestBitMask = 0
                    
                    let strokeThickness: CGFloat = 2.5
                    let offsets = [
                        CGPoint(x: strokeThickness, y: 0),
                        CGPoint(x: -strokeThickness, y: 0),
                        CGPoint(x: 0, y: strokeThickness),
                        CGPoint(x: 0, y: -strokeThickness),
                        CGPoint(x: strokeThickness, y: strokeThickness),
                        CGPoint(x: -strokeThickness, y: -strokeThickness),
                        CGPoint(x: strokeThickness, y: -strokeThickness),
                        CGPoint(x: -strokeThickness, y: strokeThickness)
                    ]
                    
                    for (index, offset) in offsets.enumerated() {
                        let outlineSprite = SKSpriteNode(texture: houseTexture, size: highlightSize)
                        outlineSprite.name = "outline_\(index)"
                        outlineSprite.position = offset
                        outlineSprite.colorBlendFactor = 1.0
                        outlineSprite.color = .clear
                        outlineSprite.zPosition = -1
                        h.addChild(outlineSprite)
                    }
                    
                    houseNode.addChild(h)
                    highlight = h
                }

                if isSender && isWithinRange && !isHoldingPackage {
                    highlight?.isHidden = false
                    if let subSprites = highlight?.children as? [SKSpriteNode] {
                        for sprite in subSprites {
                            sprite.color = .yellow
                            sprite.alpha = 1.0
                        }
                    }
                } else if isTarget && isWithinRange {
                    highlight?.isHidden = false
                    if let subSprites = highlight?.children as? [SKSpriteNode] {
                        for sprite in subSprites {
                            sprite.color = .red
                            sprite.alpha = 1.0
                        }
                    }
                } else {
                    highlight?.isHidden = true
                    if let subSprites = highlight?.children as? [SKSpriteNode] {
                        for sprite in subSprites {
                            sprite.color = .clear
                            sprite.alpha = 0.0
                        }
                    }
                }

                let senderIcon = houseNode.childNode(
                    withName: "indicator_sender"
                )
                let receiverIcon = houseNode.childNode(
                    withName: "indicator_receiver"
                )

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
        
        // Don't generate arrows or tutorial bubbles while background story is showing
        guard currentPhase != .backgroundStory else {
            onJoystickBubbleUpdate?(nil)
            onYellowBubbleUpdate?(nil)
            onRedBubbleUpdate?(nil)
            return
        }
        
        if !UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            let screenX = joystick.baseNode.position.x + (viewWidth / 2)
            let screenY = -joystick.baseNode.position.y + (viewHeight / 2)
            
            let clampedX = min(max(screenX, 70), viewWidth - 70)
            let clampedY = screenY - 110
            
            let data = TutorialBubbleData(
                text: "Move Goldie using this joystick.",
                position: CGPoint(x: clampedX, y: clampedY),
                isInTopZone: false
            )
            onJoystickBubbleUpdate?(data)
        } else {
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
                    let now2 = CACurrentMediaTime()
                    
                    if !hasShownRedArrowTutorialTimer {
                        hasShownRedArrowTutorialTimer = true
                        redTutorialStartTime = now2
                    }
                    
                    if let startTime = redTutorialStartTime {
                        if now2 - startTime < tutorialDuration {
                            if let validArrow = arrowNode {
                                let screenX = validArrow.position.x + (viewWidth / 2)
                                let screenY = -validArrow.position.y + (viewHeight / 2)
                                
                                let isInTopZone = validArrow.position.y > 0
                                
                                let clampedX = min(max(screenX, 70), viewWidth - 70)
                                let clampedY = screenY + (isInTopZone ? 55 : -55)
                                
                                let data = TutorialBubbleData(
                                    text: "Follow the red arrow to deliver the parcel.",
                                    position: CGPoint(x: clampedX, y: clampedY),
                                    isInTopZone: isInTopZone
                                )
                                onRedBubbleUpdate?(data)
                            } else {
                                onRedBubbleUpdate?(nil)
                            }
                        } else {
                            UserDefaults.standard.set(true, forKey: "hasSeenRedArrowTutorial")
                            onRedBubbleUpdate?(nil)
                        }
                    }
                }
            } else {
                print("[Arrow] RED: Target house not found for receiver: \(receiverName)")
                onRedBubbleUpdate?(nil)
            }
        } else {
            onRedBubbleUpdate?(nil)
            
            let now = CACurrentMediaTime()
            
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
                    
                    if !hasShownYellowArrowTutorialTimer {
                        hasShownYellowArrowTutorialTimer = true
                        yellowTutorialStartTime = now
                    }
                    
                    if let startTime = yellowTutorialStartTime {
                        if now - startTime < tutorialDuration {
                            if let validArrow = arrowNode {
                                let screenX = validArrow.position.x + (viewWidth / 2)
                                let screenY = -validArrow.position.y + (viewHeight / 2)
                                
                                let isInTopZone = validArrow.position.y > 0
                                
                                let clampedX = min(max(screenX, 70), viewWidth - 70)
                                let clampedY = screenY + (isInTopZone ? 55 : -55)
                                
                                let data = TutorialBubbleData(
                                    text: "Follow the yellow arrow to pick up the parcel.",
                                    position: CGPoint(x: clampedX, y: clampedY),
                                    isInTopZone: isInTopZone
                                )
                                onYellowBubbleUpdate?(data)
                                didShowYellowTutorialBubble = true
                            }
                        } else {
                            UserDefaults.standard.set(true, forKey: "hasSeenYellowArrowTutorial")
                            onYellowBubbleUpdate?(nil)
                            didShowYellowTutorialBubble = true
                        }
                    }
                }
            }
            
            if !didShowYellowTutorialBubble && !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                onYellowBubbleUpdate?(nil)
            }
        }
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
