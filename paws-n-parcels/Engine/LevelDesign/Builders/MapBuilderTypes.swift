//
//  MapBuilderTypes.swift
//  paws-n-parcels
//
//  Created by Antigravity on 19/05/26.
//

import Foundation
import CoreGraphics

enum ZPositionStrategy {
    case flat(CGFloat)
    case ySorted(offset: CGFloat)
}

enum PhysicsShape {
    case rectangle(size: CGSize)
    case rectangleWithCenter(size: CGSize, center: CGPoint)
    case circle(radius: CGFloat, offset: CGPoint)
    case houseSimplified(size: CGSize)
}
