//
//  GameScene.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 04/05/26.
//

import SpriteKit
import GameplayKit
import SwiftData
import SwiftUI

class GameScene: SKScene {
    
    var playerEntity: PlayerEntity!
    
    var movementSystem = GKComponentSystem<MovementComponent>(componentClass: MovementComponent.self)
    var gameStateMachine: GKStateMachine?
    weak var deliverySystem: DeliverySystem? {
        didSet {
            setupStateMachineIfNeeded()
        }
    }
    weak var requestSystem: RequestSystem? {
        didSet {
            registerHousesAndStartSpawning()
            setupStateMachineIfNeeded()
        }
    }
    
    let cameraNode = SKCameraNode()
    let joystick = JoystickController()
    var mapBuilder: MapBuilder!
    
    var previousTime: TimeInterval = 0
    
    var onPickUpSuccess: ((String) -> Void)?
    var onDeliverySuccess: ((Int) -> Void)?
    
    private let bounceAction: SKAction = {
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
        let moveDown = moveUp.reversed()
        return SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
    }()

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
        
        drawDebugGrid(gridSize: 100)
        registerHousesAndStartSpawning()
        
        let states = [
            GamePlayingState(scene: self),
            GamePausedState(scene: self)
        ]
        gameStateMachine = GKStateMachine(states: states)
        gameStateMachine?.enter(GamePlayingState.self)
        print("[GameScene] Game Flow State Machine initialized in GamePlayingState.")
        
        print("[GameScene] Initialization complete. Game is ready to play!")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStateMachine?.currentState is GamePlayingState else { return }
        
        let isInteracting = playerEntity.component(ofType: PlayerStateComponent.self)?.stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }
        
        let location = touch.location(in: cameraNode)
        let treshold = -(self.size.height / 4)
        
        joystick.processTouchBegan(location: location, treshold: treshold)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStateMachine?.currentState is GamePlayingState else { return }
        
        let isInteracting = playerEntity.component(ofType: PlayerStateComponent.self)?.stateMachine?.currentState is PlayerInteractingState
        guard !isInteracting else { return }

        guard let touch = touches.first
        else { return }
        
        let locationInBase = touch.location(in: joystick.baseNode)
        
        joystick.processTouchMoved(locationInBase: locationInBase)
        
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = joystick.currentVelocity
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.processTouchEnded()
        
        let isInteracting = playerEntity.component(ofType: PlayerStateComponent.self)?.stateMachine?.currentState is PlayerInteractingState
        if isInteracting {
            if let movement = playerEntity.component(ofType: MovementComponent.self) {
                movement.velocity = .zero
            }
            return
        }

        guard gameStateMachine?.currentState is GamePlayingState else {
            if let movement = playerEntity.component(ofType: MovementComponent.self) {
                movement.velocity = .zero
            }
            return
        }

        if let movement = playerEntity.component(ofType: MovementComponent.self) {
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
        
        if let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node {
            let viewWidth = self.size.width * cameraNode.xScale
            let viewHeight = self.size.height * cameraNode.yScale
            
            let mapWidth = worldMap.groundSize.width
            let mapHeight = worldMap.groundSize.height
            
            let xPos = max(viewWidth / 2, min(playerNode.position.x, mapWidth - viewWidth / 2))
            let yPos = max(viewHeight / 2, min(playerNode.position.y, mapHeight - viewHeight / 2))
            
            cameraNode.position = CGPoint(x: xPos, y: yPos)
            playerNode.zPosition = 10000 - playerNode.position.y
            
            updateScreenEdgeArrows(viewWidth: viewWidth, viewHeight: viewHeight)
            
            if let mapBuilder = mapBuilder {
                var closestHouse: HouseEntity? = nil
                var minDistanceSquared: CGFloat = GameConfig.interactionRadiusSquared
                 
                for entity in mapBuilder.environmentEntities {
                    if let house = entity as? HouseEntity,
                       let houseNode = house.component(ofType: RenderComponent.self)?.node {
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
        let playerNode = SKSpriteNode(texture: texture, size: GameConfig.playerVerticalSize)
        playerNode.zPosition = GameConfig.playerZPosition
        playerNode.position = GameConfig.playerInitialPosition
        
        // Circular physics body matching Goldie's footprint
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: GameConfig.playerPhysicsRadius)
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
        
        let boundaryRect = CGRect(x: 0, y: 0, width: mapSize.width, height: mapSize.height)
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryRect)
        self.physicsBody?.friction = 0.0
    }
    
    private func findHouseEntity(for node: SKNode) -> HouseEntity? {
        var currentNode: SKNode? = node
        while let check = currentNode {
            if let houseEntity = mapBuilder?.environmentEntities.first(where: {
                ($0 as? HouseEntity)?.component(ofType: RenderComponent.self)?.node == check
            }) as? HouseEntity {
                return houseEntity
            }
            currentNode = check.parent
        }
        
        return nil
    }
    
    private func interactWithHouse(_ house: HouseEntity) {
        let houseName = house.component(ofType: OwnerComponent.self)?.characterName ?? "Unknown"
        
        let isHoldingPackage = deliverySystem?.activePackage != nil
        let isSender = house.component(ofType: RequestComponent.self) != nil
        let isTarget = (deliverySystem?.activePackage?.receiver.name != nil) && (deliverySystem?.activePackage?.receiver.name == house.component(ofType: OwnerComponent.self)?.characterName)
        
        if isHoldingPackage {
            guard isTarget else { return }
        } else {
            guard isSender else { return }
        }
        
        guard let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node,
              let houseNode = house.component(ofType: RenderComponent.self)?.node
        else {
            print("[GameScene] Error: Player or house visual component not found.")
            return
        }
        
        let dx = playerNode.position.x - houseNode.position.x
        let dy = playerNode.position.y - houseNode.position.y
        let distanceSquared = (dx * dx) + (dy * dy)
        
        if distanceSquared > GameConfig.interactionRadiusSquared {
            print("[GameScene] Click ignored: Goldie is too far from \(houseName)'s house.")
            showTooFarIndicator(on: houseNode)
            return
        }
        
        guard let deliverySys = deliverySystem,
              let requestSys = requestSystem
        else {
            print("[GameScene] Error: Delivery System or Request System has not been injected!")
            return
        }
        
        if let waitingState = deliverySys.stateMachine?.currentState as? WaitingForPickupState {
            if house.component(ofType: RequestComponent.self) != nil {
                if let request = requestSys.pickupRequest(house) {
                    waitingState.pickUp(request: request, player: playerEntity)
                    print("[GameScene] Successfully picked up package from \(houseName)'s house.")
                    
                    onPickUpSuccess?(request.sender.pickupDialog)
                }
            } else {
                print("[GameScene] \(houseName)'s house has no package to pick up.")
            }
        } else if let carryingState = deliverySys.stateMachine?.currentState as? CarryingState {
            guard let heldPackage = deliverySys.activePackage else { return }
            let receiverName = heldPackage.receiver.name
            if receiverName == houseName {
                print("[GameScene] Delivering package to \(houseName)...")
                carryingState.deliver()
            } else {
                print("[GameScene] Wrong address! This package is for \(receiverName), not for \(houseName).")
            }
        }
    }
    
    private func registerHousesAndStartSpawning() {
        guard let builder = mapBuilder,
              let reqSys = requestSystem
        else {
            print("[GameScene] Failed to register houses: mapBuilder or requestSystem is nil.")
            return
        }
        guard reqSys.houses.isEmpty
        else { return }
        
        reqSys.houses = builder.environmentEntities.compactMap { $0 as? HouseEntity }
        print("[GameScene] Successfully registered \(reqSys.houses.count) houses into the system.")
        
        reqSys.fetchData()
        reqSys.initialBurstSpawn()
    }
    
    private func setupStateMachineIfNeeded() {
        guard let deliverySys = deliverySystem,
              let reqSys = requestSystem
        else { return }
        
        if deliverySys.stateMachine == nil {
            deliverySys.setupStateMachine(requestSystem: reqSys, scene: self)
            print("[GameScene] Delivery State Machine setup completed successfully.")
        }
    }
    
    func resumeGameplay() {
        if let stateComponent = playerEntity.component(ofType: PlayerStateComponent.self) {
            stateComponent.stateMachine?.enter(PlayerIdleState.self)
            print("[GameScene] Gameplay resumed, entering PlayerIdleState.")
        }
    }
    
    private func updateIndicators() {
        guard let mapBuilder = mapBuilder,
              let playerNode =  playerEntity.component(ofType: RenderComponent.self)?.node
        else { return }
        
        let targetReceiverName = deliverySystem?.activePackage?.receiver.name
        let isHoldingPackage = deliverySystem?.activePackage != nil
        
        for entity in mapBuilder.environmentEntities {
            if let house = entity as? HouseEntity,
               let houseNode = house.component(ofType: RenderComponent.self)?.node as? SKSpriteNode {
                let isSender = house.component(ofType: RequestComponent.self) != nil
                let isTarget = (targetReceiverName != nil) && (targetReceiverName == house.component(ofType: OwnerComponent.self)?.characterName)
                
                let dx = playerNode.position.x - houseNode.position.x
                let dy = playerNode.position.y - houseNode.position.y
                let distanceSquared = (dx * dx) + (dy * dy)
                let isWithinRange = distanceSquared <= GameConfig.interactionRadiusSquared
                
                var highlight = houseNode.childNode(withName: "indicator_highlight") as? SKShapeNode
                if highlight == nil {
                    let margin: CGFloat = 10
                    let rect = CGRect(
                        x: -(houseNode.size.width / 2) - (margin / 2),
                        y: -(houseNode.size.height / 2) - (margin / 2),
                        width: houseNode.size.width + margin,
                        height: houseNode.size.height + margin
                    )
                    
                    highlight = SKShapeNode(rect: rect, cornerRadius: 8)
                    highlight?.name = "indicator_highlight"
                    highlight?.strokeColor = .systemYellow
                    highlight?.lineWidth = 6
                    highlight?.fillColor = .clear
                    highlight?.zPosition = -1
                    
                    if let h = highlight { houseNode.addChild(h) }
                }
                
                if isSender && isWithinRange && !isHoldingPackage {
                    highlight?.strokeColor = .systemYellow
                    highlight?.isHidden = false
                } else if isTarget && isWithinRange {
                    highlight?.strokeColor = .systemRed
                    highlight?.isHidden = false
                } else {
                    highlight?.isHidden = true
                }
                
                let senderIcon = houseNode.childNode(withName: "indicator_sender")
                let receiverIcon = houseNode.childNode(withName: "indicator_receiver")
                
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
        houseNode.childNode(withName: "too_far_x")?.removeFromParent()
        
        let xLabel = SKLabelNode(text: "❌")
        xLabel.name = "too_far_x"
        xLabel.fontSize = 55
        xLabel.zPosition = 200
        xLabel.position = CGPoint(x: 0, y: 0)
        
        let shadow = SKLabelNode(text: "❌")
        shadow.fontSize = 55
        shadow.fontColor = .black
        shadow.alpha = 0.5
        shadow.zPosition = -1
        shadow.position = CGPoint(x: 3, y: -3)
        xLabel.addChild(shadow)
        
        xLabel.setScale(0.0)
        houseNode.addChild(xLabel)
        
        let popIn = SKAction.scale(to: 1.2, duration: 0.15)
        let bounce = SKAction.scale(to: 1.0, duration: 0.1)
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.25)
        
        let spawnGroup = SKAction.group([SKAction.sequence([popIn, bounce]), moveUp])
        
        let wait = SKAction.wait(forDuration: 2.75)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        
        xLabel.run(SKAction.sequence([spawnGroup, wait, fadeOut, remove]))
    }
    
    private func updateScreenEdgeArrows(viewWidth: CGFloat, viewHeight: CGFloat) {
        cameraNode.enumerateChildNodes(withName: "edge_arrow") {
            node, _ in
            node.removeFromParent()
        }
        
        guard let mapBuilder = mapBuilder else {
            return
        }
        
        let screenWidth = self.size.width
        let screenHeight = self.size.height
        
        let padding: CGFloat = 45.0
        let ovalRadiusX = (screenWidth / 2) - padding
        let ovalRadiusY = (screenHeight / 2) - padding
        
        if let activePackage = deliverySystem?.activePackage {
            let receiverName = activePackage.receiver.name
            if let targetHouse = mapBuilder.environmentEntities.first(where: {
                ($0 as? HouseEntity)?.component(ofType: OwnerComponent.self)?.characterName == receiverName
            }) as? HouseEntity, let houseNode = targetHouse.component(ofType: RenderComponent.self)?.node {
                createArrowNode(to: houseNode.position, assetName: "arrow_red", ovalX: ovalRadiusX, ovalY: ovalRadiusY, viewW: viewWidth, viewH: viewHeight)
            }
        } else {
            for entity in mapBuilder.environmentEntities {
                if let house = entity as? HouseEntity, house.component(ofType: RequestComponent.self) != nil, let houseNode = house.component(ofType: RenderComponent.self)?.node {
                    createArrowNode(to: houseNode.position, assetName: "arrow_yellow", ovalX: ovalRadiusX, ovalY: ovalRadiusY, viewW: viewWidth, viewH: viewHeight)
                }
            }
        }
    }
    
    private func createArrowNode(to targetPosition: CGPoint, assetName: String, ovalX: CGFloat, ovalY: CGFloat, viewW: CGFloat, viewH: CGFloat) {
        let dx = targetPosition.x - cameraNode.position.x
        let dy = targetPosition.y - cameraNode.position.y
        
        let safetyMargin: CGFloat = 50.0
        if abs(dx) < (viewW / 2) - safetyMargin && abs(dy) < (viewH / 2) - safetyMargin {
            return
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
    }
}

#Preview {
    SpriteView(scene: {
        let scene = GameScene()
        scene.size = CGSize(width: 375, height: 812)
        scene.scaleMode = .aspectFill
        return scene
    }(), debugOptions: [.showsPhysics])
    .ignoresSafeArea()
}
