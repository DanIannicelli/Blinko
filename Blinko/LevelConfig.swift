import Foundation

// MARK: - Level Config (Codable for JSON)

struct LevelConfig: Codable {
    let number:            Int
    let title:             String
    let ballCount:         Int
    let availableBallTypes:[String]        // ["normal","key","bomb"…]
    let keyColors:         [String]        // which gate colors key balls can unlock
    let bucketPoints:      [Int]
    let pegPattern:        String
    let pegRows:           Int?
    let pegCols:           Int?
    let gates:             [GateCfg]
    let traps:             [TrapCfg]
    let powerUps:          [PowerUpCfg]
    let targetScore:       Int
    let multiplier:        Int?            // score multiplier for the whole level
}

struct GateCfg: Codable {
    let xFrac:          CGFloat  // fraction of screenWidth  (-0.5 … 0.5)
    let yFrac:          CGFloat  // fraction of screenHeight (-0.5 … 0.5)
    let widthFrac:      CGFloat  // fraction of screenWidth
    let colorKey:       String?  // nil = timed; non-nil = key-locked
    let toggleInterval: Double   // seconds; 0 = no toggle
    let startOpen:      Bool
}

struct TrapCfg: Codable {
    let xFrac:      CGFloat
    let yFrac:      CGFloat
    let widthFrac:  CGFloat
}

struct PowerUpCfg: Codable {
    let xFrac:  CGFloat
    let yFrac:  CGFloat
    let type:   String  // "lightning" | "extraBall" | "bomb"
}

// MARK: - JSON root wrapper

struct LevelsFile: Codable {
    let levels: [LevelConfig]
}
