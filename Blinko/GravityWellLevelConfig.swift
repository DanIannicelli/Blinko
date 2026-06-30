import CoreGraphics
import UIKit

// MARK: - Mode

enum GravityWellMode {
    case transit    // reach the exit gate without collision
    case survival   // stay alive as long as possible; beat a target time
}

// MARK: - Moon config

struct MoonConfig {
    var orbitRadius: CGFloat
    var speed:       CGFloat   // radians/sec (negative = counter-clockwise)
    var size:        CGFloat
    var color:       UIColor
    var startAngle:  CGFloat
}

// MARK: - Level config

struct GravityWellLevelConfig {
    var number:      Int
    var title:       String
    var mode:        GravityWellMode

    var moons:       [MoonConfig]

    // Transit only
    var entryAngle:  CGFloat?   // radians — where the launch zone arc sits
    var exitAngle:   CGFloat?   // radians — where the exit gate sits
    var exitRadius:  CGFloat?   // distance from well center to gate midpoint

    // Survival only
    var targetTime:  Double?    // seconds to beat (shows as "par")
    var bonusMoonAt: Double?    // extra moon spawns at this many seconds

    var tip: String
}

// MARK: - All levels

struct GravityWellLevels {

    static let all: [GravityWellLevelConfig] = transitLevels + survivalLevels

    // All transit levels: launch from BOTTOM (-.pi/2), goal at TOP (.pi/2)
    static let transitLevels: [GravityWellLevelConfig] = [
        .init(
            number: 1, title: "First Contact", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 160, speed:  0.5, size: 13,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: .pi)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 200,
            tip: "Drag up — slingshot around the well to reach the gate"
        ),
        .init(
            number: 2, title: "Cross Traffic", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 150, speed:  0.6, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi/2),
                MoonConfig(orbitRadius: 220, speed: -0.4, size: 14,
                           color: UIColor(red:0.9,green:0.3,blue:0.3,alpha:1), startAngle: 0)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 190,
            tip: "Two moons moving opposite directions — time your shot"
        ),
        .init(
            number: 3, title: "The Gauntlet", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 130, speed:  0.8, size: 11,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 200, speed:  0.5, size: 13,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 270, speed: -0.3, size: 15,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi/2)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 180,
            tip: "Three orbits — find the gap between all three"
        ),
        .init(
            number: 4, title: "Needle Thread", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 145, speed:  0.9, size: 14,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 160, speed:  0.85, size: 14,
                           color: UIColor(red:0.4,green:0.8,blue:0.4,alpha:1), startAngle: .pi+0.4)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 180,
            tip: "Two moons almost at the same orbit — slip between them"
        ),
        .init(
            number: 5, title: "Side Sweep", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 170, speed:  0.55, size: 13,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 170, speed: -0.55, size: 13,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 220,
            tip: "Two moons sweeping the sides — go straight up fast"
        ),
        .init(
            number: 6, title: "Fast Lane", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 140, speed:  1.4, size: 11,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: .pi/4),
                MoonConfig(orbitRadius: 200, speed:  1.2, size: 12,
                           color: UIColor(red:1.0,green:0.5,blue:0.1,alpha:1), startAngle: -.pi/4),
                MoonConfig(orbitRadius: 260, speed:  1.0, size: 13,
                           color: UIColor(red:0.9,green:0.3,blue:0.1,alpha:1), startAngle: 0)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 175,
            tip: "Fast moons — use the arc preview to find the window"
        ),
        .init(
            number: 7, title: "Clockwork", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 130, speed:  0.7, size: 12,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 180, speed:  0.7, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 2.1),
                MoonConfig(orbitRadius: 240, speed:  0.7, size: 12,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: 4.2)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 170,
            tip: "Same speed, different phases — find the aligned gap"
        ),
        .init(
            number: 8, title: "Asteroid Pass", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 155, speed:  0.5, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 155, speed:  0.5, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: .pi+2.1),
                MoonConfig(orbitRadius: 155, speed:  0.5, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: .pi+4.2),
                MoonConfig(orbitRadius: 230, speed: -0.4, size: 14,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: 0)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 185,
            tip: "Belt of three rocks — shoot through the gap"
        ),
        .init(
            number: 9, title: "Double Helix", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 160, speed:  0.6, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 160, speed: -0.6, size: 12,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 240, speed:  0.4, size: 13,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: .pi/2)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 200,
            tip: "Two moons share an orbit going opposite ways"
        ),
        .init(
            number: 10, title: "Singularity Run", mode: .transit,
            moons: [
                MoonConfig(orbitRadius: 120, speed:  1.1, size: 11,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 170, speed: -0.9, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi/3),
                MoonConfig(orbitRadius: 220, speed:  0.7, size: 13,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: 2),
                MoonConfig(orbitRadius: 280, speed: -0.5, size: 15,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 4)
            ],
            entryAngle: -.pi/2, exitAngle: .pi/2, exitRadius: 160,
            tip: "Four moons, four orbits — bottom to top, good luck"
        ),
    ]

    // MARK: Survival (L11–20)
    static let survivalLevels: [GravityWellLevelConfig] = [
        .init(
            number: 11, title: "Quiet System", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 180, speed: 0.4, size: 13,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 0)
            ],
            targetTime: 8, bonusMoonAt: nil,
            tip: "One slow moon — find a stable orbit and hold it"
        ),
        .init(
            number: 12, title: "Binary Watch", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 150, speed:  0.6, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 220, speed: -0.4, size: 14,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi)
            ],
            targetTime: 12, bonusMoonAt: nil,
            tip: "Orbit between the two moons"
        ),
        .init(
            number: 13, title: "Rising Tide", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 170, speed: 0.5, size: 13,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 250, speed: 0.3, size: 14,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi)
            ],
            targetTime: 15, bonusMoonAt: 8,
            tip: "A third moon appears after 8 seconds"
        ),
        .init(
            number: 14, title: "Spinning Top", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 160, speed:  0.8, size: 12,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 160, speed:  0.8, size: 12,
                           color: UIColor(red:0.4,green:0.8,blue:0.4,alpha:1), startAngle: 2.1),
                MoonConfig(orbitRadius: 160, speed:  0.8, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 4.2)
            ],
            targetTime: 14, bonusMoonAt: nil,
            tip: "Three moons equally spaced on one orbit"
        ),
        .init(
            number: 15, title: "Crossfire", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 150, speed:  0.7, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 150, speed: -0.7, size: 12,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 240, speed:  0.4, size: 14,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: .pi/2)
            ],
            targetTime: 18, bonusMoonAt: nil,
            tip: "Two moons share an orbit going opposite directions"
        ),
        .init(
            number: 16, title: "Accelerando", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 140, speed:  1.0, size: 11,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 200, speed:  0.8, size: 12,
                           color: UIColor(red:1.0,green:0.5,blue:0.1,alpha:1), startAngle: 2),
                MoonConfig(orbitRadius: 260, speed:  0.6, size: 14,
                           color: UIColor(red:0.9,green:0.3,blue:0.1,alpha:1), startAngle: 4)
            ],
            targetTime: 20, bonusMoonAt: 10,
            tip: "Fast inner orbit — stay outside it"
        ),
        .init(
            number: 17, title: "Graveyard", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 145, speed:  0.9, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 145, speed:  0.9, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: 2.1),
                MoonConfig(orbitRadius: 145, speed:  0.9, size: 10,
                           color: UIColor(red:0.6,green:0.55,blue:0.5,alpha:1), startAngle: 4.2),
                MoonConfig(orbitRadius: 220, speed: -0.5, size: 13,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi)
            ],
            targetTime: 20, bonusMoonAt: nil,
            tip: "Asteroid belt at 145 — orbit outside it"
        ),
        .init(
            number: 18, title: "Maelstrom", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 130, speed:  1.2, size: 11,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 180, speed: -1.0, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: 1),
                MoonConfig(orbitRadius: 230, speed:  0.8, size: 13,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: 2),
                MoonConfig(orbitRadius: 280, speed: -0.6, size: 14,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 3)
            ],
            targetTime: 25, bonusMoonAt: nil,
            tip: "Four moons alternating direction — find the safe window"
        ),
        .init(
            number: 19, title: "Death Spiral", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 125, speed:  1.3, size: 11,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 125, speed:  1.3, size: 11,
                           color: UIColor(red:0.4,green:0.8,blue:0.4,alpha:1), startAngle: .pi),
                MoonConfig(orbitRadius: 200, speed: -0.9, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi/4),
                MoonConfig(orbitRadius: 200, speed: -0.9, size: 12,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi*1.25),
                MoonConfig(orbitRadius: 275, speed:  0.5, size: 14,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 1)
            ],
            targetTime: 25, bonusMoonAt: nil,
            tip: "Two orbits packed with moons — survive 25 seconds"
        ),
        .init(
            number: 20, title: "The Final Orbit", mode: .survival,
            moons: [
                MoonConfig(orbitRadius: 120, speed:  1.5, size: 10,
                           color: UIColor(red:1.0,green:0.8,blue:0.1,alpha:1), startAngle: 0),
                MoonConfig(orbitRadius: 120, speed:  1.5, size: 10,
                           color: UIColor(red:0.4,green:0.8,blue:0.4,alpha:1), startAngle: 2.1),
                MoonConfig(orbitRadius: 120, speed:  1.5, size: 10,
                           color: UIColor(red:0.9,green:0.8,blue:0.9,alpha:1), startAngle: 4.2),
                MoonConfig(orbitRadius: 190, speed: -1.1, size: 12,
                           color: UIColor(red:0.3,green:0.7,blue:0.9,alpha:1), startAngle: .pi/3),
                MoonConfig(orbitRadius: 190, speed: -1.1, size: 12,
                           color: UIColor(red:0.9,green:0.3,blue:0.4,alpha:1), startAngle: .pi*1.33),
                MoonConfig(orbitRadius: 260, speed:  0.7, size: 14,
                           color: UIColor(red:0.8,green:0.5,blue:0.2,alpha:1), startAngle: 2.5)
            ],
            targetTime: 30, bonusMoonAt: nil,
            tip: "The full system. 30 seconds. Good luck."
        ),
    ]
}
