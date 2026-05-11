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
        
        for item in blueprint.items {
            switch item.type {
            case .house(let color):
                buildHouse(at: grid(item.pos), color: color, rotation: item.rotation)
            case .pond:
                buildPond(at: grid(item.pos), rotation: item.rotation)
            }
        }
        
        for tree in blueprint.trees {
            buildTree(at: grid(tree))
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
    
    private func buildHouse(at point: CGPoint, color: UIColor, rotation: CGFloat?) {
        let homeSize = CGSize(width: 80, height: 80)
        let homeNode = SKShapeNode(rectOf: homeSize, cornerRadius: 15)
        
        homeNode.position = point
        homeNode.fillColor = color
        homeNode.strokeColor = .white
        homeNode.lineWidth = 4
        homeNode.zPosition = 1
        
        if let degrees = rotation {
            let angleInRadians = degrees * .pi / 180
            homeNode.zRotation = angleInRadians
        }
        
        homeNode.physicsBody = SKPhysicsBody(rectangleOf: homeSize)
        homeNode.physicsBody?.isDynamic = false
        homeNode.physicsBody?.restitution = 0.0

        scene.addChild(homeNode)
        
        environmentEntities.append(EnvironmentEntity(node: homeNode))
    }
    
    private func buildTree(at point: CGPoint) {
        let treeGroup = SKNode()
        treeGroup.position = point
        
        let trunkSize = CGSize(width: 15, height: 30)
        let trunk = SKShapeNode(rectOf: trunkSize, cornerRadius: 4)
        trunk.fillColor = UIColor(red: 0.45, green: 0.30, blue: 0.25, alpha: 1.0)
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: 0)
        treeGroup.addChild(trunk)
        
        let leafColor = UIColor(red: 0.30, green: 0.50, blue: 0.35, alpha: 1.0)
        
        let mainLeaf = SKShapeNode(circleOfRadius: 35)
        mainLeaf.fillColor = leafColor
        mainLeaf.strokeColor = .white
        mainLeaf.lineWidth = 3
        mainLeaf.position = CGPoint(x: 0, y: 35)
        mainLeaf.zPosition = 1
        treeGroup.addChild(mainLeaf)
    
        treeGroup.physicsBody = SKPhysicsBody(circleOfRadius: 15)
        treeGroup.physicsBody?.isDynamic = false
        treeGroup.physicsBody?.restitution = 0.0
        treeGroup.physicsBody?.friction = 0.0
        
        scene.addChild(treeGroup)
        
        let treeEntity = EnvironmentEntity(node: treeGroup)
        environmentEntities.append(treeEntity)
    }
    
    private func buildPond(at point: CGPoint, rotation: CGFloat?) {
        let s = gridSize * 2
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: -s, y: -s))
        path.addLine(to: CGPoint(x: s, y: -s))
        path.addLine(to: CGPoint(x: s, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: s))
        path.addLine(to: CGPoint(x: -s, y: s))
        path.closeSubpath()
        
        let pondNode = SKShapeNode(path: path)
        pondNode.position = point
        pondNode.fillColor = .systemCyan
        pondNode.strokeColor = .white.withAlphaComponent(0.5)
        pondNode.lineWidth = 5
        pondNode.zPosition = -1
        
        if let degrees = rotation {
            pondNode.zRotation = degrees * .pi / 180
        }
        
        pondNode.physicsBody = SKPhysicsBody(polygonFrom: path)
        pondNode.physicsBody?.isDynamic = false
        pondNode.physicsBody?.restitution = 0.0
        
        scene.addChild(pondNode)
        environmentEntities.append(EnvironmentEntity(node: pondNode))
    }
    
    private func grid(_ point: CGPoint) -> CGPoint {
        let offsetX = gridSize / 2
        let offsetY = gridSize / 2
        
        return CGPoint(
            x: (point.x * gridSize) + offsetX,
            y: (point.y * gridSize) + offsetY
        )
    }
}
