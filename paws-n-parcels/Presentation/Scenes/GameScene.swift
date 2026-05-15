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
    weak var deliverySystem: DeliverySystem?
    weak var requestSystem: RequestSystem? {
        didSet {
            if let builder = mapBuilder {
                requestSystem?.allHouses = builder.environmentEntities.compactMap {
                    entity in
                    return entity as? HouseEntity
                }
                print("\(requestSystem?.allHouses.count ?? 0) houses registered successfully")
                
                requestSystem?.fetchRelationships()
                requestSystem?.initialBurstSpawn()
            }
        }
    }
    
    let cameraNode = SKCameraNode()
    let joystick = JoystickController()
    var mapBuilder: MapBuilder!
    
    var previousTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        
        cameraNode.zPosition = 100_000
        cameraNode.setScale(3)
        self.camera = cameraNode
        addChild(cameraNode)
        
        mapBuilder = MapBuilder(scene: self)
        mapBuilder.build(blueprint: worldMap)

        setupPlayer()
        setupInvisibleWalls()
        joystick.attach(to: cameraNode, screenHeight: self.size.height)
        
        drawDebugGrid(gridSize: 100)
    }
    
    // MARK: - Grid support line
    func drawDebugGrid(gridSize: CGFloat) {
        let path = CGMutablePath()
        
        let worldRadius: CGFloat = GameConfig.worldSize.width
        let start = -worldRadius
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
    
    // MARK: - Setup character & ECS
    func setupPlayer() {
        
        let playerNode = SKShapeNode(circleOfRadius: 25)
        playerNode.fillColor = .systemYellow
        playerNode.strokeColor = .white
        playerNode.lineWidth = 3
        playerNode.zPosition = 5
        playerNode.position = CGPoint(x: 400, y: 400)
        
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        playerNode.physicsBody?.affectedByGravity = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 0.0

        addChild(playerNode)
        
        playerEntity = PlayerEntity(node: playerNode)
        movementSystem.addComponent(foundIn: playerEntity)
    }
    
    // MARK: - Handling Joystick
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cameraNode)
        let treshold = -(self.size.height / 4)
        
        joystick.processTouchBegan(location: location, treshold: treshold)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let locationInBase = touch.location(in: joystick.baseNode)
        
        joystick.processTouchMoved(locationInBase: locationInBase)
        
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = joystick.currentVelocity
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.processTouchEnded()
        
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = joystick.currentVelocity
        }
        
        guard let touch = touches.first else {
            return
        }
        
        let locationInMap = touch.location(in: self)
        let tappedNodes = nodes(at: locationInMap)
        
        for node in tappedNodes {
            if let house = findHouseEntity(for: node) {
                interactWithHouse(house)
                break
            }
        }
    }
 
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 {
            previousTime = currentTime
        }
        let deltaTime = currentTime - previousTime
        previousTime = currentTime
        
        movementSystem.update(deltaTime: deltaTime)
        
        requestSystem?.update(deltaTime: deltaTime)
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
            
            if let mapBuilder = mapBuilder {
                var closestHouse: HouseEntity? = nil
                var minDistance: CGFloat = 150.0
                 
                for entity in mapBuilder.environmentEntities {
                    if let house = entity as? HouseEntity,
                       let houseNode = house.component(ofType: RenderComponent.self)?.node {
                        let dx = playerNode.position.x - houseNode.position.x
                        let dy = playerNode.position.y - houseNode.position.y
                        let distance = sqrt(dx*dx + dy*dy)
                        
                        if distance < minDistance {
                            minDistance = distance
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
        let houseName = house.characterName ?? "Unknown"
        
        guard let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node,
              let houseNode = house.component(ofType: RenderComponent.self)?.node else {
            return
        }
        
        let dx = playerNode.position.x - houseNode.position.x
        let dy = playerNode.position.y - houseNode.position.y
        let distance = sqrt(dx*dx + dy*dy)
        
        if distance > 150.0 {
            return
        }
        
        guard let deliverySys = deliverySystem,
              let requestSys = requestSystem else {
            print("Goldie is too far away from \(houseName)'s house")
            return
        }
        
        if deliverySys.activePackage == nil {
            if house.component(ofType: RequestComponent.self) != nil {
                if let requestData = requestSys.removePackageFromHouse(house) {
                    deliverySys.pickUpPackage(request: requestData, for: playerEntity)
                    print("Package picked up from \(houseName)'s house")
                }
            } else {
                print("Theres no package on \(houseName)'s house")
            }
        } else if let heldPackage = deliverySys.activePackage {
            let receiverName = requestSys.allFriends.first(where: { $0.id == heldPackage.receiverId })?.name
            if receiverName == houseName {
                let result = deliverySys.deliverPackage(for: playerEntity, allRelationships: requestSys.relationships)
                print("Package has been delivered to \(houseName)'s house. Got \(result.pointsAdded) points")
                
                requestSys.triggerNewPackageSpawn()
            } else {
                print("Wrong destination, this package doesn't belong to \(houseName)")
            }
        }
    }
    
    private func updateIndicators() {
        guard let mapBuilder = mapBuilder,
              let deliverySys = deliverySystem else {
            return
        }
        
        let targetReceiverId = deliverySys.activePackage?.receiverId
        
        for entity in mapBuilder.environmentEntities {
            if let house = entity as? HouseEntity,
               let houseNode = house.component(ofType: RenderComponent.self)?.node {
                let senderIcon = houseNode.childNode(withName: "indicator_sender")
                let receiverIcon = houseNode.childNode(withName: "indicator_receiver")
                
                let isSender = house.component(ofType: RequestComponent.self) != nil
                senderIcon?.isHidden = !isSender
                
                let isTarget = (house.characterName != nil && house.characterName == requestSystem?.allFriends.first(where: { $0.id == targetReceiverId })?.name)
                receiverIcon?.isHidden = !isTarget
                
                // BUG-09: Counter-rotate indicators
                senderIcon?.zRotation = -houseNode.zRotation
                receiverIcon?.zRotation = -houseNode.zRotation
                
                if isSender {
                    if senderIcon?.action(forKey: "bounce") == nil {
                        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
                        let moveDown = moveUp.reversed()
                        let bounce = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
                        senderIcon?.run(bounce, withKey: "bounce")
                    }
                } else {
                    senderIcon?.removeAction(forKey: "bounce")
                    // Reset to original position if needed, or it's fine since it's hidden
                }
                
                if isTarget {
                    if receiverIcon?.action(forKey: "bounce") == nil {
                        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.5)
                        let moveDown = moveUp.reversed()
                        let bounce = SKAction.repeatForever(SKAction.sequence([moveUp, moveDown]))
                        receiverIcon?.run(bounce, withKey: "bounce")
                    }
                } else {
                    receiverIcon?.removeAction(forKey: "bounce")
                }
            }
        }
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
