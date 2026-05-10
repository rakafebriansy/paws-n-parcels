//
//  MapBlueprint.swift
//  paws-n-parcels
//
//  Created by Raka Febrian Syahputra on 10/05/26.
//

import Foundation
import SwiftUI

struct MapBlueprint {
    let groundSize: CGSize
    let roads: [[CGPoint]]
    let homes: [(pos: CGPoint, color: UIColor)]
    let obstacles: [CGPoint]
}

let worldMap = MapBlueprint(
    groundSize: CGSize(width: 2000, height: 2000),
    roads: [
        [
            CGPoint(x: 0, y: -10),
            CGPoint(x: 0, y: 10),
        ],
        [
            CGPoint(x: 0, y: 2),
            CGPoint(x: 5, y: 2),
        ],
    ],
    homes: [
        (pos: CGPoint(x: -2, y: 5), color: .systemOrange),
        (pos: CGPoint(x: 5, y: 2), color: .systemBlue),
        (pos: CGPoint(x: 3, y: -4), color: .systemRed),
    ],
    obstacles: [
        CGPoint(x: 2, y: 6),
        CGPoint(x: -3, y: -2),
    ]
)
