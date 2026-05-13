//
//  MapBuilder.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SpriteKit
import GameplayKit
import SwiftUI

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
        
        buildRoads(blueprint.roads)
        
        for item in blueprint.items {
            switch item.type {
            case .house:
                let centerPos = gridCenter(forBottomLeft: item.pos, widthInGrids: 2, heightInGrids: 2)
                buildHouse(at: centerPos, rotation: item.rotation)
            case .pond(_):
                buildIrregularPond(at: CGPoint(x: 12.7, y: 13.7))
            case .tree:
                let centerPos = gridCenter(forBottomLeft: item.pos, widthInGrids: 1, heightInGrids: 1)
                buildTree(at: centerPos)
            }
        }
    }
    
    private func buildTerrain(mapSize: CGSize, oceanGrids: CGFloat, beachGrids: CGFloat) {
        let maxGridX = Int(mapSize.width / gridSize)
        let maxGridY = Int(mapSize.height / gridSize)
        
        let seaTiles = ["sea_1", "sea_2", "sea_3"]
        let oceanTiles = ["ocean_1", "ocean_2", "ocean_3"]
        let beachTiles = ["beach_1", "beach_2", "beach_3"]
        
        let waterHeight = 3.0 * gridSize
        let waterPhysicsNode = SKNode()
        
        waterPhysicsNode.position = CGPoint(x: mapSize.width / 2, y: waterHeight / 2)
        waterPhysicsNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: mapSize.width, height: waterHeight))
        waterPhysicsNode.physicsBody?.isDynamic = false
        waterPhysicsNode.physicsBody?.restitution = 0.0
        waterPhysicsNode.physicsBody?.friction = 0.0
        
        scene.addChild(waterPhysicsNode)
        environmentEntities.append(EnvironmentEntity(node: waterPhysicsNode))
        
        for x in 0..<maxGridX {
            let repeatingIndex = x % 3
            
            for y in 0..<maxGridY {
                let cell = CGPoint(x: x, y: y)
                var tileName = ""
               
                switch y {
                case 0:
                    tileName = "sea"
                case 1:
                    tileName = seaTiles[repeatingIndex]
                case 2:
                    tileName = oceanTiles[repeatingIndex]
                case 3:
                    tileName = beachTiles[repeatingIndex]
                default:
                    tileName = "grass"
                }
                
                let tileNode = SKSpriteNode(imageNamed: tileName)
                tileNode.size = CGSize(width: gridSize, height: gridSize)
                tileNode.position = gridCenter(forBottomLeft: cell, widthInGrids: 1, heightInGrids: 1)

                tileNode.zPosition = -10
                scene.addChild(tileNode)
            }
        }
    }
    
    private func buildRoads(_ roads: [[CGPoint]]) {
        var roadCells = Set<CGPoint>()
        
        for path in roads {
            guard path.count > 1 else {
                continue
            }
            
            for i in 0..<(path.count - 1) {
                let p1 = path[i]
                let p2 = path[i + 1]
                
                let minX = Int(min(p1.x, p2.x))
                let maxX = Int(max(p1.x, p2.x))
                let minY = Int(min(p1.y, p2.y))
                let maxY = Int(max(p1.y, p2.y))
                
                for x in minX...maxX {
                    for y in minY...maxY {
                        roadCells.insert(CGPoint(x: x, y: y))
                        roadCells.insert(CGPoint(x: x + 1, y: y))
                        roadCells.insert(CGPoint(x: x, y: y - 1))
                        roadCells.insert(CGPoint(x: x + 1, y: y - 1))
                    }
                }
            }
        }
        
        for cell in roadCells {
            let x = Int(cell.x)
            let y = Int(cell.y)
            
            let n = roadCells.contains(CGPoint(x: x, y: y + 1))
            let e = roadCells.contains(CGPoint(x: x + 1, y: y))
            let s = roadCells.contains(CGPoint(x: x, y: y - 1))
            let w = roadCells.contains(CGPoint(x: x - 1, y: y))
            
            var sum = 0
            if n {
                sum += 1
            }
            if e {
                sum += 2
            }
            if s {
                sum += 4
            }
            if w {
                sum += 8
            }
            
            var tileName = ""
            
            switch sum {
            case 3: tileName = "gravel_corner_bl"
            case 6: tileName = "gravel_corner_tl"
            case 7: tileName = "gravel_vertical_l"
            case 9: tileName = "gravel_corner_br"
            case 11: tileName = "gravel_horizontal_b"
            case 12: tileName = "gravel_corner_tr"
            case 13: tileName = "gravel_vertical_r"
            case 14: tileName = "gravel_horizontal_t"
            case 15:
                let nw = roadCells.contains(CGPoint(x: x - 1, y: y + 1))
                let ne = roadCells.contains(CGPoint(x: x + 1, y: y + 1))
                let sw = roadCells.contains(CGPoint(x: x - 1, y: y - 1))
                let se = roadCells.contains(CGPoint(x: x + 1, y: y - 1))
                
                if !nw { tileName = "gravel_bend_tl" }
                else if !ne { tileName = "gravel_bend_tr" }
                else if !sw { tileName = "gravel_bend_bl" }
                else if !se { tileName = "gravel_bend_br" }
                else { tileName = "gravel_horizontal_t" }
            default:
                tileName = "gravel_horizontal_t"
            }
            
            let tileNode = SKSpriteNode(imageNamed: tileName)
            tileNode.size = CGSize(width: gridSize, height: gridSize)
            tileNode.position = gridCenter(forBottomLeft: cell, widthInGrids: 1, heightInGrids: 1)
            tileNode.zPosition = -5
            
            scene.addChild(tileNode)
        }
    }
    
    private func buildHouse(at point: CGPoint, rotation: CGFloat?) {
        let homeSize = CGSize(width: gridSize * 2, height: gridSize * 2)
        let homeNode = SKSpriteNode(imageNamed: "goldies_house")
        
        homeNode.size = homeSize
        homeNode.position = point
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
        let treeNode = SKSpriteNode(imageNamed: "tree")
        
        let scaleFactor = gridSize / treeNode.size.width
        let actualHeight = treeNode.size.height * scaleFactor
        let trunkYPosition = -(actualHeight / 2) + 15
        let trunkOffset = CGPoint(x: 0, y: trunkYPosition)
        
        treeNode.setScale(scaleFactor)
        treeNode.position = point
        let baseOfTheTreeY = point.y - (actualHeight / 2)
        treeNode.zPosition = 10000 - baseOfTheTreeY
        
        treeNode.physicsBody = SKPhysicsBody(circleOfRadius: 15, center: trunkOffset)
        
        treeNode.physicsBody?.isDynamic = false
        treeNode.physicsBody?.restitution = 0.0
        treeNode.physicsBody?.friction = 0.0
        
        scene.addChild(treeNode)
        
        let treeEntity = EnvironmentEntity(node: treeNode)
        environmentEntities.append(treeEntity)
    }
    
    private func buildIrregularPond(at origin: CGPoint) {
        let pondLayout: [[String?]] = [
            ["pond_corner_tl", "pond_horizontal_t" ,"pond_horizontal_t", "pond_horizontal_t", "pond_horizontal_t", "pond_horizontal_t", "pond_horizontal_t", "pond_corner_tr"],
            ["pond_vertical_l", "pond", "pond", "pond", "pond", "pond", "pond", "pond_vertical_r"],
            ["pond_vertical_l", "pond", "pond", "pond", "pond", "pond", "pond", "pond_vertical_r"],
            ["pond_corner_bl", "pond_horizontal_b" ,"pond_horizontal_b","pond_bend_bl", "pond", "pond", "pond", "pond_vertical_r"],
            [nil, nil, nil, "pond_vertical_l", "pond", "pond", "pond", "pond_vertical_r"],
            [nil, nil, nil, "pond_corner_bl", "pond_horizontal_b", "pond_horizontal_b", "pond_horizontal_b", "pond_corner_br"]
        ]
        
        let totalRows = pondLayout.count
        
        for (rowIndex, rowArray) in pondLayout.enumerated() {
            for (colIndex, tileName) in rowArray.enumerated() {
                
                guard let tileName = tileName else { continue }
                
                let currentX = origin.x + CGFloat(colIndex)

                let currentY = origin.y + CGFloat(totalRows - 1 - rowIndex)
                
                let cell = CGPoint(x: currentX, y: currentY)
                
                let tileNode = SKSpriteNode(imageNamed: tileName)
                tileNode.size = CGSize(width: gridSize, height: gridSize)
                tileNode.position = gridCenter(forBottomLeft: cell, widthInGrids: 1, heightInGrids: 1)

                tileNode.zPosition = -8
                
                tileNode.physicsBody = SKPhysicsBody(rectangleOf: tileNode.size)
                tileNode.physicsBody?.isDynamic = false
                tileNode.physicsBody?.restitution = 0.0
                tileNode.physicsBody?.friction = 0.0
                
                scene.addChild(tileNode)
                environmentEntities.append(EnvironmentEntity(node: tileNode))
            }
        }
    }
    
    private func grid(_ point: CGPoint) -> CGPoint {
        let offsetX = gridSize / 2
        let offsetY = gridSize / 2
        
        return CGPoint(
            x: (point.x * gridSize) + offsetX,
            y: (point.y * gridSize) + offsetY
        )
    }
    
    private func gridCenter(forBottomLeft point: CGPoint, widthInGrids: CGFloat, heightInGrids: CGFloat) -> CGPoint {
        let exactX = (point.x * gridSize) + ((widthInGrids * gridSize) / 2)
        let exactY = (point.y * gridSize) + ((heightInGrids * gridSize) / 2)
        return CGPoint(x: exactX, y: exactY)
    }
}
#Preview {
    SpriteView(scene: {
        // Asumsi variabel global `worldMap` dapat dibaca oleh file ini
        let previewScene = SKScene(size: worldMap.groundSize)
        
        previewScene.anchorPoint = CGPoint(x: 0, y: 0)
        previewScene.scaleMode = .aspectFit
        
        let builder = MapBuilder(scene: previewScene, gridSize: 100)
        builder.build(blueprint: worldMap)
        
        return previewScene
    }())
    .ignoresSafeArea()
}
