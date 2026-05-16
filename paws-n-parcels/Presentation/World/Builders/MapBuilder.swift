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
    var environmentEntities: [GKEntity] = []
    
    private var textureCache: [String: SKTexture] = [:]
    private struct GridPoint: Hashable {
        let x: Int
        let y: Int
    }
    
    init(scene: SKScene) {
        self.scene = scene
        print("[MapBuilder] Initializing MapBuilder.")
    }
    
    func build(_ blueprint: MapBlueprint) {
        print("[MapBuilder] Starting map generation...")
        
        buildTerrain(mapSize: blueprint.groundSize, oceanGrids: blueprint.oceanGridHeight, beachGrids: blueprint.beachGridHeight)
        buildRoads(blueprint.roads)
        
        for item in blueprint.items {
            let actualPos = item.scenePosition()
            
            switch item.type {
            case .house:
                buildHouse(at: actualPos, rotation: item.rotation, ownerName: item.characterName)
            case .pond(_):
                buildIrregularPond(at: item.pos)
            case .tree:
                buildTree(at: actualPos)
            }
        }
        
        print("[MapBuilder] Map generation completed. Total entities created: \(environmentEntities.count).")
    }
    
    private func buildTerrain(mapSize: CGSize, oceanGrids: CGFloat, beachGrids: CGFloat) {
        print("[MapBuilder] Generating terrain grid...")
        
        let grid = GameConfig.gridSize
        
        let maxGridX = Int(mapSize.width / grid)
        let maxGridY = Int(mapSize.height / grid)
        
        let seaTiles = ["sea_1", "sea_2", "sea_3"]
        let oceanTiles = ["ocean_1", "ocean_2", "ocean_3"]
        let beachTiles = ["beach_1", "beach_2", "beach_3"]
        
        let waterHeight = 3.0 * grid
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
                case 0: tileName = "sea"
                case 1: tileName = seaTiles[repeatingIndex]
                case 2: tileName = oceanTiles[repeatingIndex]
                case 3: tileName = beachTiles[repeatingIndex]
                default: tileName = "grass"
                }
                
                let tileNode = SKSpriteNode(imageNamed: tileName)
                tileNode.size = CGSize(width: grid, height: grid)
                tileNode.position = gridCenter(forBottomLeft: cell, widthInGrids: 1, heightInGrids: 1)
                tileNode.zPosition = -10
                scene.addChild(tileNode)
            }
        }
    }
    
    private func buildRoads(_ roads: [[CGPoint]]) {
        print("[MapBuilder] Generating roads network...")
        var roadCells = Set<GridPoint>()
        let grid = GameConfig.gridSize
        
        for path in roads {
            for (p1, p2) in zip(path, path.dropFirst()) {
                let minX = Int(min(p1.x, p2.x))
                let maxX = Int(max(p1.x, p2.x))
                let minY = Int(min(p1.y, p2.y))
                let maxY = Int(max(p1.y, p2.y))
                
                for x in minX...(maxX + 1) {
                    for y in (minY - 1)...maxY {
                        roadCells.insert(GridPoint(x: x, y: y))
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
            
            let tileNode = SKSpriteNode(texture: getTexture(named: tileName))
            tileNode.size = CGSize(width: grid, height: grid)
            
            let posCell = CGPoint(x: CGFloat(x), y: CGFloat(y))
            tileNode.position = gridCenter(forBottomLeft: posCell, widthInGrids: 1, heightInGrids: 1)
            tileNode.zPosition = -5
            
            scene.addChild(tileNode)
        }
    }
    
    private func buildHouse(at point: CGPoint, rotation: CGFloat?, ownerName: String? = nil) {
        let houseId = ownerName ?? "Unknown"
        print("[MapBuilder] Spawning house for \(houseId) at \(point).")
        
        let grid = GameConfig.gridSize
        let houseSize = CGSize(width: grid * 2, height: grid * 2)
        
        let houseNode = SKSpriteNode(imageNamed: "goldies_house")
        houseNode.size = houseSize
        houseNode.position = point
        houseNode.zPosition = 1
        
        if let degrees = rotation {
            let angleInRadians = degrees * .pi / 180
            houseNode.zRotation = angleInRadians
        }
        
        houseNode.physicsBody = SKPhysicsBody(rectangleOf: houseSize)
        houseNode.physicsBody?.isDynamic = false
        houseNode.physicsBody?.restitution = 0.0
        
        let senderIndicator = SKLabelNode(text: "📦")
        senderIndicator.name = "indicator_sender"
        senderIndicator.fontSize = 40
        senderIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        senderIndicator.zPosition = 100
        senderIndicator.isHidden = true
        houseNode.addChild(senderIndicator)
        
        let receiverIndicator = SKLabelNode(text: "📍")
        receiverIndicator.name = "indicator_receiver"
        receiverIndicator.fontSize = 40
        receiverIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        receiverIndicator.zPosition = 100
        receiverIndicator.isHidden = true
        houseNode.addChild(receiverIndicator)

        scene.addChild(houseNode)
        
        let houseEntity = HouseEntity(name: ownerName, node: houseNode)
        environmentEntities.append(houseEntity)
    }
    
    private func buildTree(at point: CGPoint) {
        let treeNode = SKSpriteNode(imageNamed: "tree")
        let scaleFactor = GameConfig.gridSize / treeNode.size.width
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
        let grid = GameConfig.gridSize
        let totalRows = pondLayout.count
        
        let tileSize = CGSize(width: grid, height: grid)
        let gridHalf = grid / 2.0

        let startX = (origin.x * grid) + gridHalf
        let startY = ((origin.y + CGFloat(totalRows - 1)) * grid) + gridHalf
        
        for (rowIndex, rowArray) in pondLayout.enumerated() {
            let currentY = startY - (CGFloat(rowIndex) * grid)
            
            for (colIndex, tileName) in rowArray.enumerated() {
                guard let tileName = tileName else { continue }
                
                let tileNode = SKSpriteNode(texture: getTexture(named: tileName))
                tileNode.size = tileSize                
                tileNode.position = CGPoint(x: startX + (CGFloat(colIndex) * grid), y: currentY)
                tileNode.zPosition = -8
                
                let physics = SKPhysicsBody(rectangleOf: tileSize)
                physics.isDynamic = false
                physics.restitution = 0.0
                physics.friction = 0.0
                tileNode.physicsBody = physics
                
                scene.addChild(tileNode)
                environmentEntities.append(EnvironmentEntity(node: tileNode))
            }
        }
    }
    
    private func getTexture(named name: String) -> SKTexture {
        if let cached = textureCache[name] {
            return cached
        }
        let texture = SKTexture(imageNamed: name)
        textureCache[name] = texture
        return texture
    }
    
    private func gridCenter(forBottomLeft point: CGPoint, widthInGrids: CGFloat, heightInGrids: CGFloat) -> CGPoint {
        let grid = GameConfig.gridSize
        
        let exactX = (point.x * grid) + ((widthInGrids * grid) / 2)
        let exactY = (point.y * grid) + ((heightInGrids * grid) / 2)
        return CGPoint(x: exactX, y: exactY)
    }
}

#Preview {
    SpriteView(scene: {
        let previewScene = SKScene(size: worldMap.groundSize)
        
        previewScene.anchorPoint = CGPoint(x: 0, y: 0)
        previewScene.scaleMode = .aspectFit
        
        let builder = MapBuilder(scene: previewScene)
        builder.build(worldMap)
        
        return previewScene
    }())
    .ignoresSafeArea()
}
