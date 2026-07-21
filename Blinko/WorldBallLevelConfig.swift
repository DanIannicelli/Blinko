import CoreGraphics
import UIKit

struct WorldBallPlanetConfig {
    var position:  CGPoint
    var radius:    CGFloat
    var color:     UIColor
    var gravMult:  CGFloat
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

private func green()  -> UIColor { UIColor(red:0.20,green:0.52,blue:0.26,alpha:1) }
private func brown()  -> UIColor { UIColor(red:0.52,green:0.36,blue:0.18,alpha:1) }
private func blue()   -> UIColor { UIColor(red:0.18,green:0.33,blue:0.58,alpha:1) }
private func purple() -> UIColor { UIColor(red:0.45,green:0.22,blue:0.48,alpha:1) }
private func sand()   -> UIColor { UIColor(red:0.52,green:0.45,blue:0.18,alpha:1) }
private func teal()   -> UIColor { UIColor(red:0.18,green:0.45,blue:0.52,alpha:1) }
private func rust()   -> UIColor { UIColor(red:0.55,green:0.25,blue:0.15,alpha:1) }
private func slate()  -> UIColor { UIColor(red:0.30,green:0.32,blue:0.40,alpha:1) }

// Scale factor — planets are large worlds you explore
private let S: CGFloat = 8.0

struct WorldBallLevels {

    static let all: [WorldBallLevelConfig] = [

        // L1 — Two worlds, find the launch point
        .init(number:1, title:"First Steps",
              planets:[
                .init(position:.zero,                                radius:240*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:0,    y:800*S),             radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:1,  flagAngle:.pi/2,
              tip:"Explore the planet — find where to jump"),

        // L2 — Three worlds in a triangle
        .init(number:2, title:"Side Step",
              planets:[
                .init(position:.zero,                                radius:220*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:600*S, y:500*S),            radius:180*S, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x:-400*S,y:900*S),            radius:190*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:2,  flagAngle:.pi/2,
              tip:"The path isn't straight — explore each world"),

        // L3 — Stepping stone between two giants
        .init(number:3, title:"Stone Hopper",
              planets:[
                .init(position:.zero,                                radius:260*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:250*S, y:700*S),            radius: 80*S, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-200*S,y:1200*S),           radius:220*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:2,  flagAngle:.pi/2,
              tip:"Hit the small world in the middle"),

        // L4 — Wide spread, walk to find angles
        .init(number:4, title:"Far Reach",
              planets:[
                .init(position:.zero,                                radius:230*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:700*S, y:300*S),            radius:170*S, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x:500*S, y:900*S),            radius:120*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:-300*S,y:1300*S),           radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:3,  flagAngle:.pi/2,
              tip:"Walk the full surface to find your angle"),

        // L5 — Chain of small worlds
        .init(number:5, title:"The Chain",
              planets:[
                .init(position:.zero,                                radius:220*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:100*S, y:600*S),            radius: 75*S, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-120*S,y:950*S),            radius: 80*S, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:140*S, y:1280*S),           radius: 70*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:60*S,  y:1650*S),           radius:190*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"Small worlds between the giants — aim carefully"),

        // L6 — Fork: left leads to goal, right is dead end
        .init(number:6, title:"The Fork",
              planets:[
                .init(position:.zero,                                radius:230*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:-550*S,y:550*S),            radius:160*S, color:brown(),  gravMult:1.45),
                .init(position:CGPoint(x: 550*S,y:550*S),            radius:110*S, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:-400*S,y:1100*S),           radius:130*S, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:80*S,  y:1600*S),           radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"Two paths — only one leads forward"),

        // L7 — Giant trap planet
        .init(number:7, title:"Gravity Trap",
              planets:[
                .init(position:.zero,                                radius:230*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:0,     y:700*S),            radius:280*S, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:-620*S,y:700*S),            radius:110*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:-580*S,y:1350*S),           radius:130*S, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:0,     y:1800*S),           radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:4,  flagAngle:.pi/2,
              tip:"The big world pulls you in — go around the left"),

        // L8 — Spiral path
        .init(number:8, title:"Spiral",
              planets:[
                .init(position:.zero,                                radius:220*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:500*S, y:300*S),            radius:130*S, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:650*S, y:800*S),            radius:120*S, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:300*S, y:1200*S),           radius:125*S, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-250*S,y:1500*S),           radius:130*S, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:-520*S,y:1100*S),           radius:100*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:0,     y:2000*S),           radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:6,  flagAngle:.pi/2,
              tip:"Follow the spiral outward"),

        // L9 — Two clusters with a big void gap
        .init(number:9, title:"Clusters",
              planets:[
                .init(position:.zero,                                radius:230*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:-260*S,y:550*S),            radius: 90*S, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:-120*S,y:630*S),            radius: 80*S, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:160*S, y:1050*S),           radius: 85*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:380*S, y:1350*S),           radius:100*S, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:240*S, y:1450*S),           radius: 85*S, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:90*S,  y:1900*S),           radius:200*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:6,  flagAngle:.pi/2,
              tip:"Two clusters — bridge the void between them"),

        // L10 — Long vertical climb, alternating sides
        .init(number:10, title:"Skyreach",
              planets:[
                .init(position:.zero,                                radius:230*S, color:green(),  gravMult:1.45),
                .init(position:CGPoint(x:300*S, y:500*S),            radius: 90*S, color:brown(),  gravMult:1.42),
                .init(position:CGPoint(x:-400*S,y:900*S),            radius: 95*S, color:rust(),   gravMult:1.42),
                .init(position:CGPoint(x:480*S, y:1250*S),           radius: 85*S, color:sand(),   gravMult:1.42),
                .init(position:CGPoint(x:-180*S,y:1600*S),           radius: 90*S, color:purple(), gravMult:1.42),
                .init(position:CGPoint(x:360*S, y:1950*S),           radius: 80*S, color:slate(),  gravMult:1.42),
                .init(position:CGPoint(x:-340*S,y:2300*S),           radius: 92*S, color:blue(),   gravMult:1.42),
                .init(position:CGPoint(x:90*S,  y:2700*S),           radius:220*S, color:teal(),   gravMult:1.45),
              ],
              startPlanet:0, startAngle:-.pi/2,
              flagPlanet:7,  flagAngle:.pi/2,
              tip:"Seven jumps — the long way up"),
    ]
}
