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
        buildTerrain(mapSize: blueprint.groundSize, oceanGrids: blueprint.oceanGridHeight, beachGrids: blueprint.beachGridHeight)
        
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
    
    private func buildTerrain(mapSize: CGSize, oceanGrids: CGFloat, beachGrids: CGFloat) {
        let oceanHeight = oceanGrids * gridSize
        let beachHeight = beachGrids * gridSize
        let grassHeight = mapSize.height - oceanHeight - beachHeight
        
        let oceanRect = CGRect(x: 0, y: 0, width: mapSize.width, height: oceanHeight)
        let ocean = SKShapeNode(rect: oceanRect)
        ocean.fillColor = .systemBlue
        ocean.strokeColor = .clear
        ocean.zPosition = -10
        
        ocean.physicsBody = SKPhysicsBody(rectangleOf: oceanRect.size, center: CGPoint(x: oceanRect.width / 2, y: oceanHeight / 2))
        ocean.physicsBody?.isDynamic = false
        ocean.physicsBody?.restitution = 0.0
        ocean.physicsBody?.friction = 0.0
        scene.addChild(ocean)
        environmentEntities.append(EnvironmentEntity(node: ocean))
        
        let beachRect = CGRect(x: 0, y: oceanHeight, width: mapSize.width, height: beachHeight)
        let beach = SKShapeNode(rect: beachRect)
        beach.fillColor = UIColor(red: 0.93, green: 0.86, blue: 0.70, alpha: 1.0)
        beach.strokeColor = .clear
        beach.zPosition = -10
        scene.addChild(beach)
        
        let grassRect = CGRect(x: 0, y: oceanHeight + beachHeight, width: mapSize.width, height: grassHeight)
        let grass = SKShapeNode(rect: grassRect)
        grass.fillColor = .systemGreen
        grass.strokeColor = .clear
        grass.zPosition = -10
        scene.addChild(grass)
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
        homeNode.physicsBody?.restitution = 0.0

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
        obstacle.physicsBody?.restitution = 0.0
        
        scene.addChild(obstacle)
        
        environmentEntities.append(EnvironmentEntity(node: obstacle))
    }
    
    private func grid(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * gridSize, y: point.y * gridSize)
    }
}
