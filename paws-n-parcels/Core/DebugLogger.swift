//
//  DebugLogger.swift
//  paws-n-parcels
//
//  Created by Antigravity on 23/05/26.
//

import Foundation

func debugLog(_ message: @autoclosure () -> Any) {
    #if DEBUG
    if GameConfig.showDebug {
        print(message())
    }
    #endif
}
