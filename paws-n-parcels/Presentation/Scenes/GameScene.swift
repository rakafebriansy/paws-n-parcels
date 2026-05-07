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
    
    // Gameplay Kit System
    var playerEntity: PlayerEntity!
    var movementSystem = GKComponentSystem<MovementComponent>(componentClass: MovementComponent.self)
    var previousTime: TimeInterval = 0
    
    // Camera & UI
    let cameraNode = SKCameraNode()
    var joystickBase: SKShapeNode!
    var joystickKnob: SKShapeNode!
    var isJoystickActive = false
    
    override init() {
        super.init()
    }
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        setupMap()
        setupPlayer()
        setupCameraAndJoystick()
    }
    
    // MARK: - Setup ground and road
    func setupMap() {
        
        // draw ground and road on canvas
        let ground = SKShapeNode(rectOf: CGSize(width: 2000, height: 2000), cornerRadius: 50)
        ground.fillColor = .systemGreen
        ground.strokeColor = .clear
        ground.zPosition = -10
        ground.position = CGPoint(x: 0, y: 0)
        addChild(ground)
        
        let homeA = CGPoint(x: -80, y: 70)
        let homeB = CGPoint(x: 100, y: -10)
        
        let roadPath = CGMutablePath()
        roadPath.move(to: homeA)
        roadPath.addLine(to: homeB)
        
        let road = SKShapeNode(path: roadPath)
        road.strokeColor = .systemGray
        road.lineWidth = 40
        road.lineCap = .round
        road.lineJoin = .round
        road.zPosition = -5
        addChild(road)
        
        // insert home object
        drawHome(at: homeA, color: .systemOrange)
        drawHome(at: homeB, color: .systemBlue)
    }
    
    // MARK: - Draw home object
    func drawHome(at point: CGPoint, color: UIColor) {
        
        // draw home on canvas
        let home = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
        home.position = point
        home.fillColor = color
        home.strokeColor = .white
        home.lineWidth = 3
        home.zPosition = 1
        addChild(home)
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
        addChild(playerNode)
        
        // insert visual into entity
        playerEntity = PlayerEntity(node: playerNode)
        movementSystem.addComponent(foundIn: playerEntity)
    }
    
    // MARK: - Setup camera & joystick
    func setupCameraAndJoystick() {
        
        // camera
        self.camera = cameraNode
        addChild(cameraNode)
        
        // joystick base
        joystickBase = SKShapeNode(circleOfRadius: 50)
        joystickBase.fillColor = UIColor.black.withAlphaComponent(0.2)
        joystickBase.strokeColor = .clear
        joystickBase.position = CGPoint(x: 0, y: -250) // bottom of screen
        joystickBase.zPosition = 100 // bring to front
        cameraNode.addChild(joystickBase)
        
        // joystick knob
        joystickKnob = SKShapeNode(circleOfRadius: 25)
        joystickKnob.fillColor = .white
        joystickKnob.strokeColor = .clear
        joystickKnob.zPosition = 101
        joystickBase.addChild(joystickKnob)
    }
    
    // MARK: - Touch Input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: cameraNode)
        
        if joystickBase.contains(location) {
            isJoystickActive = true
        }
    }
    
    // MARK: - Joystick Logic
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isJoystickActive, let touch = touches.first else { return }
        let location = touch.location(in: joystickBase)
        
        // set knob bounds
        let maxRadius: CGFloat = 50.0
        let distance = sqrt(location.x * location.x + location.y * location.y)
        
        var newPosition = location
        if distance > maxRadius {
            let ratio: CGFloat = maxRadius / distance
            newPosition.x *= ratio
            newPosition.y *= ratio
        }
        joystickKnob.position = newPosition
        
        let velocityX = newPosition.x / maxRadius
        let velocityY = newPosition.y / maxRadius
    
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = CGPoint(x: velocityX, y: velocityY)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // reset joystick on release
        isJoystickActive = false
        let resetAction = SKAction.move(to: .zero, duration: 0.1)
        resetAction.timingMode = .easeOut
        joystickKnob.run(resetAction)
        
        // stop gameplay kit movement
        if let movement = playerEntity.component(ofType: MovementComponent.self) {
            movement.velocity = .zero
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
        
        if let renderNode = playerEntity.component(ofType: RenderComponent.self)?.node {
            cameraNode.position = renderNode.position
        }
    }
}

#Preview {
    SpriteView(scene: {
        let scene = GameScene()
        scene.size = CGSize(width: 375, height: 812)
        scene.scaleMode = .aspectFill
        return scene
    }())
    .ignoresSafeArea()
}
