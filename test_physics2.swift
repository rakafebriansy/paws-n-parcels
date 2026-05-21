import Foundation
import SpriteKit
import AppKit

let app = NSApplication.shared
let url = URL(fileURLWithPath: "/Users/rakafebriansy/Developer/repositories/projects/paws-n-parcels/paws-n-parcels/Assets.xcassets/rock_1.imageset/rock_1.png")
if let nsImage = NSImage(contentsOf: url) {
    let texture = SKTexture(image: nsImage)
    let body = SKPhysicsBody(texture: texture, size: texture.size())
    print("Body: \(String(describing: body))")
} else {
    print("Could not load image")
}
