import CoreGraphics
import UIKit

struct WorldBallPlanetConfig {
    var position:  CGPoint
    var radius:    CGFloat
    var color:     UIColor
    var gravMult:  CGFloat   // gravity zone = radius * gravMult
}

struct WorldBallLevelConfig {
    var number:      Int
    var title:       String
    var planets:     [WorldBallPlanetConfig]
    var startPlanet: Int
    var startAngle:  CGFloat
    var flagPlanet:  Int
    var flagAngle:   CGFloat
    var tip:         String
}

// Colours
private func green()  -> UIColor { UIColor(red:0.20,green:0.52,blue:0.26,alpha:1) }
private func brown()  -> UIColor { UIColor(red:0.52,green:0.36,blue:0.18,alpha:1) }
private func blue()   -> UIColor { UIColor(red:0.18,green:0.33,blue:0.58,alpha:1) }
private func purple() -> UIColor { UIColor(red:0.45,green:0.22,blue:0.48,alpha:1) }
private func sand()   -> UIColor { UIColor(red:0.52,green:0.45,blue:0.18,alpha:1) }
private func teal()   -> UIColor { UIColor(red:0.18,green:0.45,blue:0.52,alpha:1) }
private func rust()   -> UIColor { UIColor(red:0.55,green:0.25,blue:0.15,alpha:1) }
private func slate()  -> UIColor { UIColor(red:0.30,green:0.32,blue:0.40,alpha:1) }

struct WorldBallLevels {

    static let all: [WorldBallLevelConfig] = [

        // L1 — Three planets straight up
        .init(number:1, title:"First Steps",
              planets:[
                .init(position:.zero,                       radius:240, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:0,    y:680),      radius:180, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x:0,    y:1200),     radius:160, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:2,  flagAngle:.pi/2,
              tip:"Jump straight up — three large worlds"),

        // L2 — Zig-zag
        .init(number:2, title:"Side Step",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:550,  y:400),      radius:160, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x:-450, y:780),      radius:150, color:blue(),   gravMult:1.45),
                .init(position:CGPoint(x:300,  y:1200),     radius:170, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:3,  flagAngle:.pi/2,
              tip:"Jump left then right to reach the flag"),

        // L3 — Stepping stones between big planets
        .init(number:3, title:"Stone Hopper",
              planets:[
                .init(position:.zero,                       radius:230, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:200,  y:560),      radius: 90, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-230, y:900),      radius: 95, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:120,  y:1260),     radius:190, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:3,  flagAngle:.pi/2,
              tip:"Smaller worlds in the middle — aim carefully"),

        // L4 — Wide spread
        .init(number:4, title:"Far Reach",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:680,  y:280),      radius:170, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x:420,  y:750),      radius:100, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:-300, y:1080),     radius:180, color:blue(),   gravMult:1.45),
                .init(position:CGPoint(x:200,  y:1550),     radius:160, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"Planets spread wide — walk around to find the angle"),

        // L5 — Chain of small worlds
        .init(number:5, title:"The Chain",
              planets:[
                .init(position:.zero,                       radius:210, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:90,   y:480),      radius: 80, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-100, y:750),      radius: 75, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:120,  y:1010),     radius: 85, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:-90,  y:1270),     radius: 70, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:50,   y:1520),     radius:170, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:5,  flagAngle:.pi/2,
              tip:"Five small worlds — miss one and fall back"),

        // L6 — Two paths, one dead end
        .init(number:6, title:"The Fork",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:-500, y:500),      radius:150, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x: 500, y:500),      radius:100, color:rust(),   gravMult:1.42),  // dead end
                .init(position:CGPoint(x:-350, y:980),      radius:120, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:60,   y:1420),     radius:180, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"Right side is a dead end — go left"),

        // L7 — Massive planet in the middle pulls you off course
        .init(number:7, title:"Gravity Trap",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:0,    y:650),      radius:260, color:brown(),  gravMult:1.42),  // massive trap
                .init(position:CGPoint(x:-560, y:650),      radius:100, color:purple(), gravMult:1.42),  // escape left
                .init(position:CGPoint(x:-520, y:1200),     radius:120, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:0,    y:1650),     radius:170, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"Big planet in the middle — go around the left"),

        // L8 — Spiral outward
        .init(number:8, title:"Spiral",
              planets:[
                .init(position:.zero,                       radius:210, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:480,  y:280),      radius:120, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:600,  y:720),      radius:110, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:280,  y:1120),     radius:115, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-220, y:1380),     radius:120, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:-480, y:1020),     radius: 90, color:purple(), gravMult:1.42),  // extra loop
                .init(position:CGPoint(x:0,    y:1800),     radius:180, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:6,  flagAngle:.pi/2,
              tip:"Follow the spiral — don't get sucked into the loop"),

        // L9 — Clusters with gap
        .init(number:9, title:"Clusters",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:-240, y:500),      radius: 85, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:-110, y:570),      radius: 75, color:sand(),   gravMult:1.42),
                // gap here
                .init(position:CGPoint(x:140,  y:920),      radius: 80, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:360,  y:1200),     radius: 95, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:220,  y:1300),     radius: 80, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:80,   y:1680),     radius:180, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:6,  flagAngle:.pi/2,
              tip:"Two clusters with dead space between — bridge the gap"),

        // L10 — Long vertical climb
        .init(number:10, title:"Skyreach",
              planets:[
                .init(position:.zero,                       radius:220, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:280,  y:420),      radius: 85, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:-380, y:720),      radius: 90, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:460,  y:1000),     radius: 80, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-160, y:1280),     radius: 85, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:340,  y:1540),     radius: 75, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:-320, y:1800),     radius: 88, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:80,   y:2100),     radius:210, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:7,  flagAngle:.pi/2,
              tip:"Seven jumps alternating sides — the long way up"),
    ]
}
