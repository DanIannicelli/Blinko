import Foundation

struct PhysicsCategory {
    static let none:        UInt32 = 0
    static let ball:        UInt32 = 1 << 0
    static let peg:         UInt32 = 1 << 1
    static let bucket:      UInt32 = 1 << 2
    static let wall:        UInt32 = 1 << 3
    static let gate:        UInt32 = 1 << 4
    static let trap:        UInt32 = 1 << 5
    static let powerUp:     UInt32 = 1 << 6
    static let trapSensor:  UInt32 = 1 << 7
}
