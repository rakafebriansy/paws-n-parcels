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
    
    let cameraNode = SKCameraNode()
    let joystick = JoystickController()
    var mapBuilder: MapBuilder!
    
    var previousTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0, y: 0)
        cameraNode.zPosition = 100_000
        self.camera = cameraNode
        addChild(cameraNode)
        
        mapBuilder = MapBuilder(scene: self, gridSize: 100)
        mapBuilder.build(blueprint: worldMap)
        
        setupPlayer()
        setupInvisibleWalls()
        joystick.attach(to: cameraNode, screenHeight: self.size.height)
        
        drawDebugGrid(gridSize: 100)
    }
    
    // MARK: - Grid support line
    func drawDebugGrid(gridSize: CGFloat) {
        let path = CGMutablePath()
        
        let worldRadius: CGFloat = 2500
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
        
        // draw character visual
        let playerNode = SKShapeNode(circleOfRadius: 25)
        playerNode.fillColor = .systemYellow
        playerNode.strokeColor = .white
        playerNode.lineWidth = 3
        playerNode.zPosition = 5
        playerNode.position = CGPoint(x: 400, y: 400)
        
        // add physics body
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        playerNode.physicsBody?.affectedByGravity = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 0.0

        addChild(playerNode)
        
        // insert visual into entity
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
        guard let touch = touches.first else { return }
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
    }
 
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 {
            previousTime = currentTime
        }
        let deltaTime = currentTime - previousTime
        previousTime = currentTime
        
        movementSystem.update(deltaTime: deltaTime)
        
        if let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node {
            let viewWidth = self.size.width
            let viewHeight = self.size.height
            
            let mapWidth = worldMap.groundSize.width
            let mapHeight = worldMap.groundSize.height
            
            let xPos = max(viewWidth / 2, min(playerNode.position.x, mapWidth - viewWidth / 2))
            let yPos = max(viewHeight / 2, min(playerNode.position.y, mapHeight - viewHeight / 2))
            
            cameraNode.position = CGPoint(x: xPos, y: yPos)
            
            playerNode.zPosition = 10000 - playerNode.position.y
        }
    }
    
    private func setupInvisibleWalls() {
        let mapSize = worldMap.groundSize
        
        let boundaryRect = CGRect(x: 0, y: 0, width: mapSize.width, height: mapSize.height)
        
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryRect)
        self.physicsBody?.friction = 0.0
    }
    
    // MARK: - Setup character & ECS
    func setupPlayer() {
        
        // draw character visual
        let playerNode = SKShapeNode(circleOfRadius: 25)
        playerNode.fillColor = .systemYellow
        playerNode.strokeColor = .white
        playerNode.lineWidth = 3
        playerNode.zPosition = 5
        playerNode.position = CGPoint(x: 0, y: 0)
        
        // add physics body
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: 25)
        playerNode.physicsBody?.affectedByGravity = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 0.0

        addChild(playerNode)
        
        // insert visual into entity
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
        guard let touch = touches.first else { return }
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
    }
 
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        if previousTime == 0 {
            previousTime = currentTime
        }
        let deltaTime = currentTime - previousTime
        previousTime = currentTime
        
        movementSystem.update(deltaTime: deltaTime)
        
        if let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node {
            let viewWidth = self.size.width
                    let viewHeight = self.size.height
                    let xPos = max(viewWidth / 2, min(playerNode.position.x, 2000 - viewWidth / 2))
                    let yPos = max(viewHeight / 2, min(playerNode.position.y, 2000 - viewHeight / 2))
                    
                    cameraNode.position = CGPoint(x: xPos, y: yPos)
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
