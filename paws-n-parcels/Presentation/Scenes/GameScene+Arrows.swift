//
//  GameScene+Arrows.swift
//  paws-n-parcels
//
//  Screen-edge arrow management extracted from GameScene for modularity.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func updateScreenEdgeArrows(viewWidth: CGFloat, viewHeight: CGFloat) {
        cameraNode.enumerateChildNodes(withName: "edge_arrow") { node, _ in node.removeFromParent() }
        
        guard currentPhase != .backgroundStory else {
            onJoystickBubbleUpdate?(nil)
            onYellowBubbleUpdate?(nil)
            onRedBubbleUpdate?(nil)
            return
        }

        if UserDefaults.standard.bool(forKey: "hasSeenJoystickTutorial") {
            onJoystickBubbleUpdate?(nil)
        }

        guard let mapBuilder = mapBuilder else {
            return
        }

        let screenWidth = self.size.width
        let screenHeight = self.size.height

        let padding: CGFloat = 45.0
        let ovalRadiusX = (screenWidth / 2) - padding
        let ovalRadiusY = (screenHeight / 2) - padding

        let topZoneThreshold: CGFloat = 0
        let horizontalThreshold: CGFloat = 60
        let horizontalYOffset: CGFloat = 60
        
        let hasActivePackage = deliverySystem?.activePackage != nil
        
        let now0 = CACurrentMediaTime()
        let shouldLog = now0 - lastArrowDebugLogTime >= 2.0
        if shouldLog {
            lastArrowDebugLogTime = now0
            let dsStatus = deliverySystem != nil ? "ALIVE" : "NIL"
            let apStatus = hasActivePackage ? "YES" : "NO"
            debugLog("[Arrow DEBUG] deliverySystem=\(dsStatus), activePackage=\(apStatus)")
        }
        
        if let activePackage = deliverySystem?.activePackage {
            onYellowBubbleUpdate?(nil)
            
            let receiverName = activePackage.receiver.name
            if let targetHouse = mapBuilder.environmentEntities.first(where: {
                ($0 as? HouseEntity)?.component(ofType: OwnerComponent.self)?.characterName == receiverName
            }) as? HouseEntity, let houseNode = targetHouse.component(ofType: RenderComponent.self)?.node {
                
                let arrowNode = createArrowNode(to: houseNode.position, assetName: "arrow_red", ovalX: ovalRadiusX, ovalY: ovalRadiusY, viewW: viewWidth, viewH: viewHeight)
                
                if shouldLog {
                    debugLog("[Arrow DEBUG] RED: receiver=\(receiverName), houseFound=YES, arrowCreated=\(arrowNode != nil)")
                }
                
                if !UserDefaults.standard.bool(forKey: "hasSeenRedArrowTutorial") {
                    if let validArrow = arrowNode {
                        let data = calculateTutorialBubbleData(
                            arrowNode: validArrow,
                            text: "Follow the red arrow to deliver the parcel.",
                            viewWidth: viewWidth,
                            viewHeight: viewHeight,
                            topZoneThreshold: topZoneThreshold,
                            horizontalThreshold: horizontalThreshold,
                            horizontalYOffset: horizontalYOffset
                        )
                        onRedBubbleUpdate?(data)
                    } else {
                        onRedBubbleUpdate?(nil)
                    }
                }
            } else {
                debugLog("[Arrow] RED: Target house not found for receiver: \(receiverName)")
                onRedBubbleUpdate?(nil)
            }
        } else {
            onRedBubbleUpdate?(nil)
            
            let allRequestingHouses = mapBuilder.environmentEntities
                .compactMap { $0 as? HouseEntity }
                .filter { $0.component(ofType: RequestComponent.self) != nil }
            
            if shouldLog {
                debugLog("[Arrow DEBUG] YELLOW: requestingHouses=\(allRequestingHouses.count)")
            }
            
            if yellowTutorialTargetHouseName == nil, let firstTarget = allRequestingHouses.first?.component(ofType: OwnerComponent.self)?.characterName {
                yellowTutorialTargetHouseName = firstTarget
            }
            
            var didShowYellowTutorialBubble = false
            
            for house in allRequestingHouses {
                guard let name = house.component(ofType: OwnerComponent.self)?.characterName,
                      let houseNode = house.component(ofType: RenderComponent.self)?.node else { continue }
                
                let arrowNode = createArrowNode(
                    to: houseNode.position,
                    assetName: "arrow_yellow",
                    ovalX: ovalRadiusX,
                    ovalY: ovalRadiusY,
                    viewW: viewWidth,
                    viewH: viewHeight
                )
                
                if name == yellowTutorialTargetHouseName,
                   !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                    
                    if let validArrow = arrowNode {
                        let data = calculateTutorialBubbleData(
                            arrowNode: validArrow,
                            text: "Follow the yellow arrow to pick up the parcel.",
                            viewWidth: viewWidth,
                            viewHeight: viewHeight,
                            topZoneThreshold: topZoneThreshold,
                            horizontalThreshold: horizontalThreshold,
                            horizontalYOffset: horizontalYOffset
                        )
                        onYellowBubbleUpdate?(data)
                        didShowYellowTutorialBubble = true
                    }
                }
            }
            
            if !didShowYellowTutorialBubble && !UserDefaults.standard.bool(forKey: "hasSeenYellowArrowTutorial") {
                onYellowBubbleUpdate?(nil)
            }
        }
    }
    
    func calculateTutorialBubbleData(
        arrowNode: SKNode,
        text: String,
        viewWidth: CGFloat,
        viewHeight: CGFloat,
        topZoneThreshold: CGFloat,
        horizontalThreshold: CGFloat,
        horizontalYOffset: CGFloat
    ) -> TutorialBubbleData {
        let screenX = arrowNode.position.x + (viewWidth / 2)
        let screenY = -arrowNode.position.y + (viewHeight / 2)
        
        let isInTopZone = arrowNode.position.y > topZoneThreshold
        let isHorizontallyAligned = abs(arrowNode.position.y) < horizontalThreshold
        
        let clampedX = min(max(screenX, 70), viewWidth - 70)
        
        let clampedY: CGFloat
        let finalIsInTopZone: Bool
        if isHorizontallyAligned {
            clampedY = screenY - (horizontalYOffset * 2)
            finalIsInTopZone = false 
        } else {
            clampedY = screenY + (isInTopZone ? horizontalYOffset : -(horizontalYOffset * 2))
            finalIsInTopZone = isInTopZone
        }
        
        return TutorialBubbleData(
            text: text,
            position: CGPoint(x: clampedX, y: clampedY),
            isInTopZone: finalIsInTopZone
        )
    }
    
    func createArrowNode(to targetPosition: CGPoint, assetName: String, ovalX: CGFloat, ovalY: CGFloat, viewW: CGFloat, viewH: CGFloat) -> SKSpriteNode? {
        let dx = targetPosition.x - cameraNode.position.x
        let dy = targetPosition.y - cameraNode.position.y

        let safetyMargin: CGFloat = 50.0
        if abs(dx) < (viewW / 2) - safetyMargin
            && abs(dy) < (viewH / 2) - safetyMargin
        {
            return nil
        }

        let angle = atan2(dy, dx)

        let arrowX = ovalX * cos(angle)
        let arrowY = ovalY * sin(angle)

        let arrowNode = SKSpriteNode(imageNamed: assetName)
        arrowNode.name = "edge_arrow"
        arrowNode.size = CGSize(width: 45, height: 45)
        arrowNode.position = CGPoint(x: arrowX, y: arrowY)

        arrowNode.zRotation = angle - GameConfig.arrowAssetDirection
        arrowNode.zPosition = 90_000

        cameraNode.addChild(arrowNode)
        return arrowNode
    }
}
