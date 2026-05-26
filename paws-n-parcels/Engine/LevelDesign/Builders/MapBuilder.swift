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
        debugLog("[MapBuilder] Initializing MapBuilder.")
    }
    
    func build(_ blueprint: MapBlueprint) {
        debugLog("[MapBuilder] Starting map generation...")
        
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
            case .decoration:
                buildDecoration(at: actualPos, assetName: item.assetName ?? "rock_1")
            }
        }
        
        debugLog("[MapBuilder] Map generation completed. Total entities created: \(environmentEntities.count).")
    }
    
    private func buildTerrain(mapSize: CGSize, oceanGrids: CGFloat, beachGrids: CGFloat) {
        debugLog("[MapBuilder] Generating terrain grid...")
        
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
        tileMap.name = "terrainMap"
        
        for y in 0..<maxGridY {
            for x in 0..<maxGridX {
                let repeatingIndex = x % 3
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
        debugLog("[MapBuilder] Generating roads network...")
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
        tileMap.name = "roadMap"
        
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
            case .rectangleWithCenter(let rectSize, let center):
                node.physicsBody = SKPhysicsBody(rectangleOf: rectSize, center: center)
            case .circle(let radius, let centerOffset):
                node.physicsBody = SKPhysicsBody(circleOfRadius: radius, center: centerOffset)
            case .texture:
                if let texture = node.texture {
                    node.physicsBody = SKPhysicsBody(texture: texture, alphaThreshold: 0.1, size: size)
                    if node.physicsBody == nil {
                        node.physicsBody = SKPhysicsBody(rectangleOf: size)
                    }
                } else {
                    node.physicsBody = SKPhysicsBody(rectangleOf: size)
                }
            case .houseSimplified(let size):
                let w = size.width
                let h = size.height
                
                let bodyBase = SKPhysicsBody(rectangleOf: CGSize(width: w * 1, height: h * 0.6), center: CGPoint(x: 0, y: -h * 0.15))
                
                let roofPath = CGMutablePath()
                roofPath.move(to: CGPoint(x: -w * 0.48, y: h * 0.05))
                roofPath.addLine(to: CGPoint(x: w * 0.48, y: h * 0.05))
                roofPath.addLine(to: CGPoint(x: w * 0.25, y: h * 0.45))
                roofPath.addLine(to: CGPoint(x: -w * 0.25, y: h * 0.4))
                roofPath.closeSubpath()
                let bodyRoof = SKPhysicsBody(polygonFrom: roofPath)
                
                let bodyChimney = SKPhysicsBody(rectangleOf: CGSize(width: w * 0.18, height: h * 0.3), center: CGPoint(x: -w * 0.28, y: h * 0.15))
                
                node.physicsBody = SKPhysicsBody(bodies: [bodyBase, bodyRoof, bodyChimney])
            }
            node.physicsBody?.isDynamic = false
            node.physicsBody?.restitution = 0.0
            node.physicsBody?.friction = 0.0
        }
        
        scene.addChild(node)
        return node
    }
    
    private func buildDecoration(at point: CGPoint, assetName: String) {
        let texture = getTexture(named: assetName)
        let node = SKSpriteNode(texture: texture)
        
        if assetName == "sunflower" {
            node.size = CGSize(width: 60, height: 100)
        }
        
        node.position = point
        node.setScale(0.4)
        
        if assetName.contains("rock"){
            let actualHeight = node.size.height * 1.5
            node.zPosition = 10000 - (point.y - (actualHeight / 2))
            let physicsWidth = node.size.width * 0.8
            let physicsHeight = actualHeight * 0.7
            
            node.physicsBody = SKPhysicsBody(
                rectangleOf: CGSize(width: physicsWidth, height: physicsHeight),
                center: CGPoint(x: 0, y: 0)
            )
        } else {
            let actualHeight = node.size.height * 2
            node.zPosition = 10000 - (point.y - (actualHeight / 2))
            let physicsWidth = node.size.width * 0.5
            let physicsHeight = actualHeight * 0.3
            
            node.physicsBody = SKPhysicsBody(
                rectangleOf: CGSize(width: physicsWidth, height: physicsHeight),
                center: CGPoint(x: 0, y: -actualHeight * 0.15)
            )
        }
        
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        node.physicsBody?.collisionBitMask = PhysicsCategory.player
        node.physicsBody?.contactTestBitMask = PhysicsCategory.none
        
        scene.addChild(node)
        environmentEntities.append(EnvironmentEntity(node: node))
    }
    
    private func buildHouse(at point: CGPoint, rotation: CGFloat?, ownerName: String? = nil, assetName: String? = nil) {
        let houseId = ownerName ?? "Unknown"
        debugLog("[MapBuilder] Spawning house for \(houseId) at \(point).")
        
        let grid = GameConfig.gridSize
        let houseSize = CGSize(width: grid * 2, height: grid * 2)
        let houseImage = assetName ?? "house_1"
        
        let houseNode = buildGeneralEntity(
            imageNamed: houseImage,
            size: houseSize,
            at: point,
            rotation: rotation,
            physicsShape: .houseSimplified(size: houseSize),
            zPositionStrategy: .ySorted(offset: 0)
        )
        
        let senderAnimalTextureName = ownerName.flatMap { getAnimalAsset(for: $0) }.map { "conversation_\($0)" } ?? "conversation_rabbit"
        let senderIndicator = SKSpriteNode(texture: getTexture(named: senderAnimalTextureName))
        senderIndicator.name = "indicator_sender"
        senderIndicator.size = GameConfig.requestIndicatorSize
        senderIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        senderIndicator.zPosition = 100
        senderIndicator.isHidden = true
        
        let senderExclamation = SKSpriteNode(texture: getTexture(named: "exclamation"))
        senderExclamation.size = GameConfig.requestIndicatorExclamationSize
        senderExclamation.position = CGPoint(x: senderIndicator.size.width * 0.35, y: senderIndicator.size.height * 0.35)
        senderExclamation.zPosition = 1
        senderIndicator.addChild(senderExclamation)
        
        houseNode.addChild(senderIndicator)
        
        let receiverAnimalTextureName = ownerName.flatMap { getAnimalAsset(for: $0) }.map { "conversation_\($0)" } ?? "conversation_rabbit"
        let receiverIndicator = SKSpriteNode(texture: getTexture(named: receiverAnimalTextureName))
        receiverIndicator.name = "indicator_receiver"
        receiverIndicator.size = GameConfig.requestIndicatorSize
        receiverIndicator.position = CGPoint(x: 0, y: (houseSize.height / 2) + 20)
        receiverIndicator.zPosition = 100
        receiverIndicator.isHidden = true
        
        let receiverExclamation = SKSpriteNode(texture: getTexture(named: "exclamation"))
        receiverExclamation.size = GameConfig.requestIndicatorExclamationSize
        receiverExclamation.position = CGPoint(x: receiverIndicator.size.width * 0.35, y: receiverIndicator.size.height * 0.35)
        receiverExclamation.zPosition = 1
        receiverIndicator.addChild(receiverExclamation)
        
        houseNode.addChild(receiverIndicator)
        
        let houseEntity = HouseEntity(name: ownerName, node: houseNode)
        environmentEntities.append(houseEntity)
    }
    
    private func buildTree(at point: CGPoint) {
        let grid = GameConfig.gridSize
        let dummyNode = SKSpriteNode(imageNamed: "tree")
        let scaleFactor = grid / dummyNode.size.width
        let actualHeight = dummyNode.size.height * scaleFactor
        let treeSize = CGSize(width: grid, height: actualHeight)
        
        let node = buildGeneralEntity(
            imageNamed: "tree",
            size: treeSize,
            at: point,
            rotation: nil,
            physicsShape: .rectangle(size: CGSize(width: grid, height: grid)),
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
                    
                    let physics = self.physicsBodyForPondTile(name: tileName, grid: grid)
                    physics?.isDynamic = false
                    physics?.restitution = 0.0
                    physics?.friction = 0.0
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
    
    private func physicsBodyForPondTile(name: String, grid: CGFloat) -> SKPhysicsBody? {
        let half = grid / 2.0
        let quarter = grid / 4.0
        
        let zero: CGFloat = 0.0
        
        func pieSliceBody(cx: CGFloat, cy: CGFloat, radius: CGFloat, startRad: CGFloat, endRad: CGFloat) -> SKPhysicsBody {
            let path = CGMutablePath()
            let center = CGPoint(x: cx, y: cy)
            path.move(to: center)
            path.addArc(center: center, radius: radius, startAngle: startRad, endAngle: endRad, clockwise: false)
            path.closeSubpath()
            return SKPhysicsBody(polygonFrom: path)
        }
        
        let bodyHorizontalT = SKPhysicsBody(rectangleOf: CGSize(width: grid, height: half + quarter), center: CGPoint(x: zero, y: zero))
        let bodyHorizontalB = SKPhysicsBody(rectangleOf: CGSize(width: grid, height: half), center: CGPoint(x: zero, y: zero))
        let bodyVerticalL   = SKPhysicsBody(rectangleOf: CGSize(width: half, height: grid), center: CGPoint(x: zero, y: zero))
        let bodyVerticalR   = SKPhysicsBody(rectangleOf: CGSize(width: half, height: grid), center: CGPoint(x: zero, y: zero))
        
        let bodyCornerTL = pieSliceBody(cx: half, cy: -half, radius: half + quarter, startRad: .pi / 2, endRad: .pi)
        let bodyCornerTR = pieSliceBody(cx: -half, cy: -half, radius: half + quarter, startRad: 0, endRad: .pi / 2)
        let bodyCornerBL = pieSliceBody(cx: half, cy: half, radius: half + quarter, startRad: .pi, endRad: 3 * .pi / 2)
        let bodyCornerBR = pieSliceBody(cx: -half, cy: half, radius: half + quarter, startRad: 3 * .pi / 2, endRad: 2 * .pi)
        
        let bendTopHalf = SKPhysicsBody(rectangleOf: CGSize(width: grid, height: half), center: CGPoint(x: zero, y: quarter))
        let bendBotRight = SKPhysicsBody(rectangleOf: CGSize(width: half, height: half), center: CGPoint(x: quarter, y: -quarter))
        
        let pathBendBL = CGMutablePath()
        pathBendBL.move(to: CGPoint(x: zero, y: zero))
        pathBendBL.addLine(to: CGPoint(x: -half, y: zero))
        pathBendBL.addLine(to: CGPoint(x: zero, y: -half))
        pathBendBL.closeSubpath()
        let bendTriangleBL = SKPhysicsBody(polygonFrom: pathBendBL)
        
        let bodyBendBL = SKPhysicsBody(bodies: [bendTopHalf, bendBotRight, bendTriangleBL])

        switch name {
        case "pond": return SKPhysicsBody(rectangleOf: CGSize(width: grid, height: grid))
        case "pond_horizontal_t": return bodyHorizontalT
        case "pond_horizontal_b": return bodyHorizontalB
        case "pond_vertical_l": return bodyVerticalL
        case "pond_vertical_r": return bodyVerticalR
        case "pond_corner_tl": return bodyCornerTL
        case "pond_corner_tr": return bodyCornerTR
        case "pond_corner_bl": return bodyCornerBL
        case "pond_corner_br": return bodyCornerBR
        case "pond_bend_bl": return bodyBendBL
        default: return SKPhysicsBody(rectangleOf: CGSize(width: grid, height: grid))
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
    
    private func getAnimalAsset(for ownerName: String) -> String? {
        return CharacterRegistry.getAsset(for: ownerName)
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
