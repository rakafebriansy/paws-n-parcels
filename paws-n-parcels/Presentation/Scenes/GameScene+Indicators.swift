//
//  GameScene+Indicators.swift
//  paws-n-parcels
//
//  House indicator management extracted from GameScene for modularity.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    static let senderPulseAction: SKAction = {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.25),
            SKAction.scale(to: 1.0,  duration: 0.25)
        ])
        return SKAction.repeatForever(pulse)
    }()
    
    static let receiverPulseAction: SKAction = {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.25),
            SKAction.scale(to: 1.0,  duration: 0.25)
        ])
        return SKAction.repeatForever(pulse)
    }()

    
    func updateIndicators() {
        guard let mapBuilder = mapBuilder,
            let playerNode = playerEntity.component(
                ofType: RenderComponent.self
            )?.node
        else { return }

        let targetReceiverName = deliverySystem?.activePackage?.receiver.name
        let isHoldingPackage = deliverySystem?.activePackage != nil

        for entity in mapBuilder.environmentEntities {
            if let house = entity as? HouseEntity,
                let houseNode = house.component(ofType: RenderComponent.self)?
                    .node as? SKSpriteNode
            {
                let isSender =
                    house.component(ofType: RequestComponent.self) != nil
                let isTarget =
                    (targetReceiverName != nil)
                    && (targetReceiverName
                        == house.component(ofType: OwnerComponent.self)?
                        .characterName)

                let dx = playerNode.position.x - houseNode.position.x
                let dy = playerNode.position.y - houseNode.position.y
                let distanceSquared = (dx * dx) + (dy * dy)
                let isWithinRange =
                    distanceSquared <= GameConfig.interactionRadiusSquared

                let senderIcon = houseNode.childNode(withName: "indicator_sender") as? SKSpriteNode
                let receiverIcon = houseNode.childNode(withName: "indicator_receiver") as? SKSpriteNode

                senderIcon?.isHidden = !isSender || isHoldingPackage
                receiverIcon?.isHidden = !isTarget

                senderIcon?.zRotation = -houseNode.zRotation
                receiverIcon?.zRotation = -houseNode.zRotation

                if isSender {
                    if senderIcon?.action(forKey: "bounce") == nil {
                        senderIcon?.run(bounceAction, withKey: "bounce")
                    }
                } else {
                    senderIcon?.removeAction(forKey: "bounce")
                }

                if isTarget {
                    if receiverIcon?.action(forKey: "bounce") == nil {
                        receiverIcon?.run(bounceAction, withKey: "bounce")
                    }
                } else {
                    receiverIcon?.removeAction(forKey: "bounce")
                }

                if isSender && isWithinRange && !isHoldingPackage {
                    if senderIcon?.action(forKey: "highlight") == nil {
                        senderIcon?.run(Self.senderPulseAction, withKey: "highlight")
                        senderIcon?.color = .yellow
                        senderIcon?.colorBlendFactor = 0.12
                    }
                } else {
                    senderIcon?.removeAction(forKey: "highlight")
                    senderIcon?.setScale(1.0)
                    senderIcon?.colorBlendFactor = 0.0
                }

                if isTarget && isWithinRange {
                    if receiverIcon?.action(forKey: "highlight") == nil {
                        receiverIcon?.run(Self.receiverPulseAction, withKey: "highlight")
                        receiverIcon?.color = .red
                        receiverIcon?.colorBlendFactor = 0.12
                    }
                } else {
                    receiverIcon?.removeAction(forKey: "highlight")
                    receiverIcon?.setScale(1.0)
                    receiverIcon?.colorBlendFactor = 0.0
                }

                if let oldHighlight = houseNode.childNode(withName: "indicator_highlight") {
                    oldHighlight.removeFromParent()
                }
            }
        }
    }
    
    func showTooFarIndicator(on houseNode: SKNode) {
        tooFarBubbleTimer = 2.0
        updateTooFarBubblePosition()
    }
    
    func updateTooFarBubblePosition() {
        guard let view = self.view,
              let playerNode = playerEntity.component(ofType: RenderComponent.self)?.node else { return }
        let viewWidth = view.bounds.width
        let viewHeight = view.bounds.height
        
        let absoluteScenePos = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 140)
        let relativePos = cameraNode.convert(absoluteScenePos, from: self)
        let screenX = relativePos.x + (viewWidth / 2)
        let screenY = -relativePos.y + (viewHeight / 2)
        
        let data = TooFarBubbleData(
            text: "Too far away.",
            position: CGPoint(x: screenX, y: screenY)
        )
        onTooFarBubbleUpdate?(data)
    }
}
