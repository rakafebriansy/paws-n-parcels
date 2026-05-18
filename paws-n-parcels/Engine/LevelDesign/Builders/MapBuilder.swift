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

enum ZPositionStrategy {
    case flat(CGFloat)
    case ySorted(offset: CGFloat)
}

enum PhysicsShape {
    case rectangle(size: CGSize)
    case circle(radius: CGFloat, offset: CGPoint)
}

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
        buildRoads(blueprint.roads, mapSize: blueprint.groundSize)
        
        for item in blueprint.items {
            let actualPos = item.scenePosition()
            
            switch item.type {
            case .house:
                buildHouse(at: actualPos, rotation: item.rotation, ownerName: item.characterName, assetName: item.assetName)
            case .pond(_):
                buildIrregularPond(at: item.pos)
            case .tree:
                buildTree(at: actualPos)
            case .fence:
                buildFence(at: actualPos, rotation: item.rotation)
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
        
        let tileNames = ["sea", "sea_1", "sea_2", "sea_3", "ocean_1", "ocean_2", "ocean_3", "beach_1", "beach_2", "beach_3", "grass"]
        let tileSet = createTileSet(for: tileNames)
        let tileMap = SKTileMapNode(tileSet: tileSet, columns: maxGridX, rows: maxGridY, tileSize: CGSize(width: grid, height: grid))
        tileMap.anchorPoint = .zero
        tileMap.position = .zero
        tileMap.zPosition = -10
        
        for x in 0..<maxGridX {
            let repeatingIndex = x % 3
            for y in 0..<maxGridY {
                var tileName = ""
               
                switch y {
                case 0: tileName = "sea"
                case 1: tileName = seaTiles[repeatingIndex]
                case 2: tileName = oceanTiles[repeatingIndex]
                case 3: tileName = beachTiles[repeatingIndex]
                default: tileName = "grass"
                }
                
                if let group = tileSet.tileGroups.first(where: { $0.name == tileName }) {
                    tileMap.setTileGroup(group, forColumn: x, row: y)
                }
            }
        }
        scene.addChild(tileMap)
    }
    
    private func buildRoads(_ roads: [[CGPoint]], mapSize: CGSize) {
        print("[MapBuilder] Generating roads network...")
        var roadCells = Set<GridPoint>()
        let grid = GameConfig.gridSize
        let maxGridX = Int(mapSize.width / grid)
        let maxGridY = Int(mapSize.height / grid)
        
        let tileNames = ["gravel_corner_bl", "gravel_corner_tl", "gravel_vertical_l", "gravel_corner_br", "gravel_horizontal_b", "gravel_corner_tr", "gravel_vertical_r", "gravel_horizontal_t", "gravel_bend_tl", "gravel_bend_tr", "gravel_bend_bl", "gravel_bend_br"]
        let tileSet = createTileSet(for: tileNames)
        let tileMap = SKTileMapNode(tileSet: tileSet, columns: maxGridX, rows: maxGridY, tileSize: CGSize(width: grid, height: grid))
        tileMap.anchorPoint = .zero
        tileMap.position = .zero
        tileMap.zPosition = -5
        
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
            
            let n = roadCells.contains(GridPoint(x: x, y: y + 1))
            let e = roadCells.contains(GridPoint(x: x + 1, y: y))
            let s = roadCells.contains(GridPoint(x: x, y: y - 1))
            let w = roadCells.contains(GridPoint(x: x - 1, y: y))
            
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
                let nw = roadCells.contains(GridPoint(x: x - 1, y: y + 1))
                let ne = roadCells.contains(GridPoint(x: x + 1, y: y + 1))
                let sw = roadCells.contains(GridPoint(x: x - 1, y: y - 1))
                let se = roadCells.contains(GridPoint(x: x + 1, y: y - 1))
                
                if !nw { tileName = "gravel_bend_tl" }
                else if !ne { tileName = "gravel_bend_tr" }
                else if !sw { tileName = "gravel_bend_bl" }
                else if !se { tileName = "gravel_bend_br" }
                else { tileName = "gravel_horizontal_t" }
            default:
                tileName = "gravel_horizontal_t"
            }
            
            if let group = tileSet.tileGroups.first(where: { $0.name == tileName }) {
                tileMap.setTileGroup(group, forColumn: x, row: y)
            }
        }
        scene.addChild(tileMap)
    }
    
    private func createTileSet(for names: [String]) -> SKTileSet {
        var groups: [SKTileGroup] = []
        let grid = GameConfig.gridSize
        for name in names {
            let texture = getTexture(named: name)
            let def = SKTileDefinition(texture: texture, size: CGSize(width: grid, height: grid))
            let group = SKTileGroup(tileDefinition: def)
            group.name = name
            groups.append(group)
        }
        return SKTileSet(tileGroups: groups)
    }
    
    private func buildGeneralEntity(
        imageNamed: String,
        size: CGSize,
        at point: CGPoint,
        rotation: CGFloat?,
        physicsShape: PhysicsShape?,
        zPositionStrategy: ZPositionStrategy
    ) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: imageNamed)
        node.size = size
        node.position = point
        
        if let degrees = rotation {
            let angleInRadians = degrees * .pi / 180
            node.zRotation = angleInRadians
        }
        
        switch zPositionStrategy {
        case .flat(let val):
            node.zPosition = val
        case .ySorted(let offset):
            let baseOfTheItemY = point.y - (size.height / 2) + offset
            node.zPosition = 10000 - baseOfTheItemY
        }
        
        if let shape = physicsShape {
            switch shape {
            case .rectangle(let rectSize):
                node.physicsBody = SKPhysicsBody(rectangleOf: rectSize)
            case .circle(let radius, let centerOffset):
                node.physicsBody = SKPhysicsBody(circleOfRadius: radius, center: centerOffset)
            }
            node.physicsBody?.isDynamic = false
            node.physicsBody?.restitution = 0.0
            node.physicsBody?.friction = 0.0
        }
        
        scene.addChild(node)
        return node
    }
    
    private func buildHouse(at point: CGPoint, rotation: CGFloat?, ownerName: String? = nil, assetName: String? = nil) {
        let houseId = ownerName ?? "Unknown"
        print("[MapBuilder] Spawning house for \(houseId) at \(point).")
        
        let grid = GameConfig.gridSize
        let houseSize = CGSize(width: grid * 2, height: grid * 2)
        let houseImage = assetName ?? "house_1"
        
        let houseNode = buildGeneralEntity(
            imageNamed: houseImage,
            size: houseSize,
            at: point,
            rotation: rotation,
            physicsShape: .rectangle(size: houseSize),
            zPositionStrategy: .flat(1)
        )
        
        let senderIndicator = SKSpriteNode(texture: getTexture(named: "conversation_bubble"))
        senderIndicator.name = "indicator_sender"
        senderIndicator.size = GameConfig.requestIndicatorSize
        senderIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        senderIndicator.zPosition = 100
        senderIndicator.isHidden = true
        
        if let owner = ownerName, let assetName = getAnimalAsset(for: owner) {
            let animalFace = SKSpriteNode(texture: getTexture(named: assetName))
            animalFace.size = GameConfig.requestIndicatorAnimalFaceSize
            animalFace.position = CGPoint(x: 0, y: 3)
            animalFace.zPosition = 1
            
            senderIndicator.addChild(animalFace)
        }
            
        houseNode.addChild(senderIndicator)
        
        let receiverIndicator = SKLabelNode(text: "📍")
        receiverIndicator.name = "indicator_receiver"
        receiverIndicator.fontSize = 40
        receiverIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        receiverIndicator.zPosition = 100
        receiverIndicator.isHidden = true
        houseNode.addChild(receiverIndicator)
        
        let houseEntity = HouseEntity(name: ownerName, node: houseNode)
        environmentEntities.append(houseEntity)
        
        if let name = ownerName, let animalAsset = getAnimalAsset(for: name) {
            // Spawn NPC 80 units below the house in front of the door
            let npcPos = CGPoint(x: point.x, y: point.y - 80)
            let npc = NPCEntity(name: name, assetName: animalAsset, position: npcPos, house: houseEntity, scene: scene as! GameScene)
            npc.addComponent(NPCStateComponent(scene: scene as! GameScene))
            environmentEntities.append(npc)
            
            if let gameScene = scene as? GameScene {
                gameScene.movementSystem.addComponent(foundIn: npc)
            }
        }
    }
    
    private func buildTree(at point: CGPoint) {
        let grid = GameConfig.gridSize
        let dummyNode = SKSpriteNode(imageNamed: "tree")
        let scaleFactor = grid / dummyNode.size.width
        let actualHeight = dummyNode.size.height * scaleFactor
        let treeSize = CGSize(width: grid, height: actualHeight)
        
        let trunkYPosition = -(actualHeight / 2) + 15
        let trunkOffset = CGPoint(x: 0, y: trunkYPosition)
        
        let node = buildGeneralEntity(
            imageNamed: "tree",
            size: treeSize,
            at: point,
            rotation: nil,
            physicsShape: .circle(radius: 15, offset: trunkOffset),
            zPositionStrategy: .ySorted(offset: 0)
        )
        
        let treeEntity = EnvironmentEntity(node: node)
        environmentEntities.append(treeEntity)
    }
    
    private func buildFence(at point: CGPoint, rotation: CGFloat? = nil) {
        let grid = GameConfig.gridSize
        let fenceSize = CGSize(width: grid, height: grid * 0.5)
        
        let node = buildGeneralEntity(
            imageNamed: "fence",
            size: fenceSize,
            at: point,
            rotation: rotation,
            physicsShape: .rectangle(size: fenceSize),
            zPositionStrategy: .ySorted(offset: 0)
        )
        
        let fenceEntity = EnvironmentEntity(node: node)
        environmentEntities.append(fenceEntity)
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
        let totalCols = pondLayout[0].count
        
        let tileNames = ["pond", "pond_corner_tl", "pond_horizontal_t", "pond_corner_tr", "pond_vertical_l", "pond_vertical_r", "pond_corner_bl", "pond_horizontal_b", "pond_corner_br", "pond_bend_bl"]
        let tileSet = createTileSet(for: tileNames)
        
        let tileMap = SKTileMapNode(tileSet: tileSet, columns: totalCols, rows: totalRows, tileSize: CGSize(width: grid, height: grid))
        tileMap.anchorPoint = .zero
        tileMap.position = CGPoint(x: origin.x * grid, y: origin.y * grid)
        tileMap.zPosition = -8
        
        let physicsNode = SKNode()
        physicsNode.position = tileMap.position
        
        for (rowIndex, rowArray) in pondLayout.enumerated() {
            let rowInTileMap = totalRows - 1 - rowIndex
            for (colIndex, tileName) in rowArray.enumerated() {
                guard let tileName = tileName else { continue }
                if let group = tileSet.tileGroups.first(where: { $0.name == tileName }) {
                    tileMap.setTileGroup(group, forColumn: colIndex, row: rowInTileMap)
                    
                    let dummyNode = SKNode()
                    dummyNode.position = CGPoint(x: (CGFloat(colIndex) * grid) + (grid / 2.0), y: (CGFloat(rowInTileMap) * grid) + (grid / 2.0))
                    
                    let physics = SKPhysicsBody(rectangleOf: CGSize(width: grid, height: grid))
                    physics.isDynamic = false
                    physics.restitution = 0.0
                    physics.friction = 0.0
                    dummyNode.physicsBody = physics
                    
                    physicsNode.addChild(dummyNode)
                }
            }
        }
        
        scene.addChild(tileMap)
        scene.addChild(physicsNode)
        
        let pondEntity = EnvironmentEntity(node: physicsNode)
        environmentEntities.append(pondEntity)
    }
    
    private func getTexture(named name: String) -> SKTexture {
        if let cached = textureCache[name] {
            return cached
        }
        let texture = SKTexture(imageNamed: name)
        textureCache[name] = texture
        return texture
    }
    
    private func getAnimalAsset(for ownerName: String) -> String? {
        return CharacterRegistry.getAsset(for: ownerName)
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
