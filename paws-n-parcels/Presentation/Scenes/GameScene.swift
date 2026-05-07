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
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setupMap()
    }
    
    func setupMap() {
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
        
        drawHome(at: homeA, color: .systemOrange)
        drawHome(at: homeB, color: .systemBlue)
    }
    
    func drawHome(at point: CGPoint, color: UIColor) {
        let home = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 10)
        home.position = point
        home.fillColor = color
        home.strokeColor = .white
        home.lineWidth = 3
        home.zPosition = 1
        addChild(home)
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
