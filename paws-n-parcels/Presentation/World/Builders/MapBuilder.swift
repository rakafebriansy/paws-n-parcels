//
//  MapBuilder.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

class MapBuilder {
    let scene: SKScene
    let gridSize: CGFloat
    
    var environmentEntities: [EnvironmentEntity] = []
    
    init(scene: SKScene, gridSize: CGFloat) {
        self.scene = scene
        self.gridSize = gridSize
    }
    
    func build(blueprint: MapBlueprint) {
        buildGround(size: blueprint.groundSize)
        
        for roadPath in blueprint.roads {
            buildRoad(points: roadPath)
        }
        
        for home in blueprint.homes {
            buildHome(at: grid(home.pos), color: home.color)
        }
        
        for obstacle in blueprint.obstacles {
            buildObstacle(at: grid(obstacle), size: CGSize(width: 50, height: 50))
        }
    }
    
    private func buildGround(size: CGSize) {
        let ground = SKShapeNode(rectOf: size, cornerRadius: 50)
        ground.fillColor = .systemGreen
        ground.strokeColor = .clear
        ground.zPosition = -10
        scene.addChild(ground)
    }
    
    private func buildRoad(points: [CGPoint]) {
        guard points.count > 1 else { return }
        
        let roadPath = CGMutablePath()
        roadPath.move(to: grid(points[0]))
        
        for i in 1..<points.count {
            roadPath.addLine(to: grid(points[i]))
        }
        
        let roadNode = SKShapeNode(path: roadPath)
        roadNode.strokeColor = .systemGray
        roadNode.lineWidth = 80
        roadNode.lineCap = .round
        roadNode.lineJoin = .round
        roadNode.zPosition = -5
        scene.addChild(roadNode)
    }
    
    private func buildHome(at point: CGPoint, color: UIColor) {
        let homeSize = CGSize(width: 80, height: 80)
        let homeNode = SKShapeNode(rectOf: homeSize, cornerRadius: 15)
        
        homeNode.position = point
        homeNode.fillColor = color
        homeNode.strokeColor = .white
        homeNode.lineWidth = 4
        homeNode.zPosition = 1
        
        homeNode.physicsBody = SKPhysicsBody(rectangleOf: homeSize)
        homeNode.physicsBody?.isDynamic = false
        scene.addChild(homeNode)
        
        environmentEntities.append(EnvironmentEntity(node: homeNode))
    }
    
    private func buildObstacle(at point: CGPoint, size: CGSize) {
        let obstacle = SKShapeNode(rectOf: size, cornerRadius: 5)
        
        obstacle.position = point
        obstacle.fillColor = .darkGray
        obstacle.strokeColor = .black
        obstacle.zPosition = 1
        
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: size)
        obstacle.physicsBody?.isDynamic = false
        scene.addChild(obstacle)
        
        environmentEntities.append(EnvironmentEntity(node: obstacle))
    }
    
    private func grid(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * gridSize, y: point.y * gridSize)
    }
}
