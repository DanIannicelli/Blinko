import SpriteKit

class WorldBallScene: SKScene {

    // MARK: - Config
    var levelConfig: WorldBallLevelConfig = WorldBallLevels.all[0]

    // MARK: - Nodes
    private var worldNode  = SKNode()
    private var playerNode: SKShapeNode!
    private var planets:    [PlanetData] = []
    private var flagNode:   SKNode?

    private var leftBtn:  SKShapeNode!
    private var rightBtn: SKShapeNode!
    private var jumpBtn:  SKShapeNode!

    // MARK: - State
    private let walkSpeed:       CGFloat = 0.55  // slower on big worlds
    private let jumpSpeed:       CGFloat = 3800  // scaled for large worlds
    private let gravityStrength: CGFloat = 22000 // scaled for large worlds
    private let worldScale:      CGFloat = 0.42  // ~50% more zoom than before

    private var voidZones:       [VoidZone] = []
    private var coins:           [(node: SKNode, angle: CGFloat, planetIdx: Int)] = []
    private var coinCount:       Int = 0

    private var playerAngle:     CGFloat = -.pi / 2
    private var currentPlanet:   Int = 0
    private var departedPlanet:  Int = -1
    private var jumpTimer:       CGFloat = 0
    private var isJumping        = false
    private var playerVel:       CGVector = .zero
    private var leftHeld         = false
    private var rightHeld        = false
    private var facingRight:     Bool = true
    private var lastUpdate:      TimeInterval = 0
    private var levelComplete    = false
    private var settleTimer:     CGFloat = 0

    private let planetScreenY:   CGFloat = -40
    private var coinLabel:       SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)
        addChild(worldNode)
        worldNode.setScale(worldScale)
        setupStars()
        buildLevel()
        setupControls()
        setupHUD()
        syncWorld()
    }

    // MARK: - Stars

    private func setupStars() {
        for _ in 0..<220 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.8))
            s.fillColor   = .white.withAlphaComponent(CGFloat.random(in: 0.15...0.85))
            s.strokeColor = .clear
            s.position    = CGPoint(x: CGFloat.random(in: -900...900),
                                    y: CGFloat.random(in: -1200...1200))
            s.zPosition   = -20
            worldNode.addChild(s)
        }
    }

    // MARK: - Level build

    private func buildLevel() {
        planets.removeAll()
        worldNode.removeAllChildren()
        setupStars()   // re-add stars after clear

        for cfg in levelConfig.planets {
            let node = SKNode()
            node.position = cfg.position

            let body = SKShapeNode(circleOfRadius: cfg.radius)
            body.fillColor   = cfg.color
            body.strokeColor = cfg.color.withAlphaComponent(0.5)
            body.lineWidth   = 2
            node.addChild(body)

            let atmo = SKShapeNode(circleOfRadius: cfg.radius + 10)
            atmo.fillColor   = .clear
            atmo.strokeColor = cfg.color.withAlphaComponent(0.09)
            atmo.lineWidth   = 10
            node.addChild(atmo)

            let gravR = cfg.radius * cfg.gravMult
            let gravRing = SKShapeNode(circleOfRadius: gravR)
            gravRing.fillColor   = .clear
            gravRing.strokeColor = cfg.color.withAlphaComponent(0.05)
            gravRing.lineWidth   = 2
            node.addChild(gravRing)

            addGrass(to: node, radius: cfg.radius)
            addTrees(to: node, radius: cfg.radius, count: max(2, Int(cfg.radius / 16)))

            worldNode.addChild(node)
            planets.append(PlanetData(position: cfg.position, radius: cfg.radius,
                                      color: cfg.color, gravityRadius: gravR, node: node))
        }

        coins.removeAll()
        coinCount = 0
        spawnVoidRocks()
        spawnCoinsAndBoxes()
        setupFlag()
        setupPlayer()
    }

    private func spawnVoidRocks() {
        voidZones.removeAll()
        guard levelConfig.planets.count > 1 else { return }

        for i in 0..<(levelConfig.planets.count - 1) {
            let a = planets[i]
            let b = planets[i + 1]

            // Axis from a→b
            let dx = b.position.x - a.position.x
            let dy = b.position.y - a.position.y
            let dist = max(hypot(dx, dy), 1)
            let ax = dx / dist; let ay = dy / dist       // unit vector along axis

            // Zone runs planet surface to planet surface (through gravity zones too)
            let halfLen = dist / 2                       // center of A to center of B
            let halfWid = (a.radius + b.radius) * 0.38  // corridor width

            let center = CGPoint(x: (a.position.x + b.position.x) / 2,
                                 y: (a.position.y + b.position.y) / 2)

            let zone = VoidZone(center: center, axisX: ax, axisY: ay,
                                halfLen: halfLen, halfWid: halfWid)
            voidZones.append(zone)

            // Visual indicator — faint glowing corridor
            let zoneRect = SKShapeNode(rectOf: CGSize(width: halfLen * 2, height: halfWid * 2),
                                       cornerRadius: halfWid * 0.4)
            zoneRect.fillColor   = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.045)
            zoneRect.strokeColor = UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.18)
            zoneRect.lineWidth   = 1.5
            zoneRect.position    = center
            zoneRect.zRotation   = atan2(ay, ax)
            zoneRect.zPosition   = 2
            zoneRect.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 2.0),
                SKAction.fadeAlpha(to: 0.7, duration: 2.0)
            ])))
            worldNode.addChild(zoneRect)

            // "NO GRAVITY" label in the middle
            let lbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
            lbl.text      = "· · · low gravity · · ·"
            lbl.fontSize  = 10
            lbl.fontColor = UIColor(red: 0.6, green: 0.85, blue: 1.0, alpha: 0.45)
            lbl.verticalAlignmentMode = .center
            lbl.position  = center
            lbl.zRotation = atan2(ay, ax)
            lbl.zPosition = 3
            worldNode.addChild(lbl)

            // Rocks scattered inside this zone
            let count = Int.random(in: 3...6)
            for _ in 0..<count {
                let along = CGFloat.random(in: -halfLen * 0.85 ... halfLen * 0.85)
                let perp  = CGFloat.random(in: -halfWid * 0.5  ... halfWid * 0.5)
                let rock  = makeRock(radius: CGFloat.random(in: 8...22))
                rock.position = CGPoint(x: center.x + ax * along + (-ay) * perp,
                                        y: center.y + ay * along + ( ax) * perp)
                rock.zRotation = CGFloat.random(in: 0...(2 * .pi))
                rock.zPosition = 5
                worldNode.addChild(rock)
                let drift = SKAction.sequence([
                    SKAction.moveBy(x: CGFloat.random(in: -14...14),
                                    y: CGFloat.random(in: -14...14),
                                    duration: Double.random(in: 3...6)),
                    SKAction.moveBy(x: CGFloat.random(in: -14...14),
                                    y: CGFloat.random(in: -14...14),
                                    duration: Double.random(in: 3...6))
                ])
                rock.run(SKAction.repeatForever(drift))
                rock.run(SKAction.repeatForever(
                    SKAction.rotate(byAngle: (Bool.random() ? 1 : -1) * CGFloat.random(in: 0.3...0.8),
                                    duration: Double.random(in: 4...9))
                ))
            }
        }
    }

    private func spawnCoinsAndBoxes() {
        for (idx, cfg) in levelConfig.planets.enumerated() {
            let coinAngles = stride(from: CGFloat(0), to: .pi * 2, by: .pi / 5)
            for angle in coinAngles {
                let coin = SKShapeNode(circleOfRadius: 28)
                coin.fillColor   = UIColor(red:1.0, green:0.85, blue:0.15, alpha:1)
                coin.strokeColor = UIColor(red:0.9, green:0.65, blue:0.05, alpha:1)
                coin.lineWidth   = 6
                coin.zPosition   = 8
                let inner = SKShapeNode(circleOfRadius: 16)
                inner.fillColor   = UIColor(red:1.0, green:0.95, blue:0.45, alpha:1)
                inner.strokeColor = .clear
                coin.addChild(inner)
                let dist = cfg.radius + 55
                coin.position = CGPoint(x: cfg.position.x + cos(angle) * dist,
                                        y: cfg.position.y + sin(angle) * dist)
                coin.name = "coin_\(idx)_\(Int(angle*10))"
                worldNode.addChild(coin)
                coins.append((node: coin, angle: angle, planetIdx: idx))
            }

            // Item boxes — 2-3 per planet at random angles
            let boxAngles: [CGFloat] = [.pi/3, .pi, 5 * .pi/3]
            for angle in boxAngles {
                let box = SKShapeNode(rectOf: CGSize(width: 80, height: 80), cornerRadius: 8)
                box.fillColor   = UIColor(red:0.95, green:0.70, blue:0.10, alpha:1)
                box.strokeColor = UIColor(red:0.70, green:0.45, blue:0.05, alpha:1)
                box.lineWidth   = 6
                box.zPosition   = 8
                let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
                lbl.text = "?"; lbl.fontSize = 52
                lbl.fontColor = UIColor(white:1, alpha:0.9)
                lbl.verticalAlignmentMode = .center
                box.addChild(lbl)
                let dist = cfg.radius + 60
                box.position  = CGPoint(x: cfg.position.x + cos(angle) * dist,
                                        y: cfg.position.y + sin(angle) * dist)
                box.zRotation = angle - .pi/2
                box.name = "box_\(idx)_\(Int(angle*10))"
                worldNode.addChild(box)
            }
        }
    }

    private func makeRock(radius: CGFloat) -> SKShapeNode {
        let sides = Int.random(in: 5...8)
        let path  = CGMutablePath()
        for j in 0..<sides {
            let angle = CGFloat(j) / CGFloat(sides) * .pi * 2
            let r     = radius * CGFloat.random(in: 0.65...1.0)
            let pt    = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            j == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        let grey = CGFloat.random(in: 0.28...0.48)
        node.fillColor   = UIColor(white: grey, alpha: 1)
        node.strokeColor = UIColor(white: grey + 0.12, alpha: 0.6)
        node.lineWidth   = 1
        return node
    }

    private func addGrass(to node: SKNode, radius r: CGFloat) {
        let count = Int(r * 1.0)
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
            let path  = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: 0, y: CGFloat.random(in: 4...8)))
            let blade = SKShapeNode(path: path)
            blade.strokeColor = UIColor(red:0.25,green:0.80,blue:0.30,
                                        alpha:CGFloat.random(in:0.5...0.9))
            blade.lineWidth  = 1.5
            blade.position   = CGPoint(x: cos(angle)*r, y: sin(angle)*r)
            blade.zRotation  = angle - .pi/2
            node.addChild(blade)
        }
    }

    private func addTrees(to node: SKNode, radius r: CGFloat, count: Int) {
        for i in 0..<count {
            let angle = CGFloat(i) / CGFloat(count) * .pi * 2
                        + CGFloat.random(in: -0.3...0.3)
            let tree  = SKNode()
            tree.position  = CGPoint(x: cos(angle)*r, y: sin(angle)*r)
            tree.zRotation = angle - .pi/2

            let trunk = SKShapeNode(rectOf: CGSize(width: 4, height: 12))
            trunk.fillColor   = UIColor(red:0.33,green:0.20,blue:0.09,alpha:1)
            trunk.strokeColor = .clear
            trunk.position    = CGPoint(x:0, y:6)
            tree.addChild(trunk)

            let h = CGFloat.random(in: 16...26)
            let f1 = SKShapeNode(ellipseOf: CGSize(width: 22, height: h))
            f1.fillColor   = UIColor(red:0.13,green:CGFloat.random(in:0.52...0.70),blue:0.17,alpha:1)
            f1.strokeColor = .clear; f1.position = CGPoint(x:0,y:16)
            tree.addChild(f1)

            let f2 = SKShapeNode(ellipseOf: CGSize(width: 15, height: h*0.65))
            f2.fillColor   = UIColor(red:0.17,green:CGFloat.random(in:0.62...0.82),blue:0.21,alpha:1)
            f2.strokeColor = .clear; f2.position = CGPoint(x:0,y:25)
            tree.addChild(f2)

            node.addChild(tree)
        }
    }

    // MARK: - Flag

    private func setupFlag() {
        let fp = levelConfig.flagPlanet
        let fa = levelConfig.flagAngle
        let planet = planets[fp]

        let flag = SKNode()
        flag.name = "flag"
        flag.position = CGPoint(
            x: planet.position.x + cos(fa) * (planet.radius + 2),
            y: planet.position.y + sin(fa) * (planet.radius + 2)
        )
        flag.zRotation = fa - .pi/2
        flag.zPosition = 15

        let pole = SKShapeNode(rectOf: CGSize(width: 3, height: 36))
        pole.fillColor   = UIColor(white:0.85,alpha:1)
        pole.strokeColor = .clear; pole.position = CGPoint(x:0,y:18)
        flag.addChild(pole)

        let banner = SKShapeNode(rectOf: CGSize(width: 22, height: 14), cornerRadius: 2)
        banner.fillColor   = UIColor(red:1.0,green:0.25,blue:0.25,alpha:1)
        banner.strokeColor = UIColor(red:1.0,green:0.5,blue:0.5,alpha:0.6)
        banner.lineWidth   = 1; banner.position = CGPoint(x:12,y:34)
        banner.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to:1.12,duration:0.6),
            SKAction.scale(to:0.95,duration:0.6)
        ])))
        flag.addChild(banner)

        let glow = SKShapeNode(circleOfRadius: planet.radius + 20)
        glow.fillColor   = .clear
        glow.strokeColor = UIColor(red:1,green:0.3,blue:0.3,alpha:0.18)
        glow.lineWidth   = 8; glow.position = planet.position; glow.zPosition = -1
        glow.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to:0.05,duration:1.0),
            SKAction.fadeAlpha(to:0.22,duration:1.0)
        ])))
        worldNode.addChild(glow)
        worldNode.addChild(flag)
        flagNode = flag
    }

    // MARK: - Player

    private func setupPlayer() {
        playerNode?.removeFromParent()
        playerNode = SKShapeNode(circleOfRadius: 10)
        playerNode.fillColor   = UIColor(red:0.95,green:0.85,blue:0.60,alpha:1)
        playerNode.strokeColor = UIColor(red:0.80,green:0.60,blue:0.20,alpha:1)
        playerNode.lineWidth   = 2; playerNode.zPosition = 12

        let eye = SKShapeNode(circleOfRadius: 3)
        eye.fillColor = .white; eye.strokeColor = .clear; eye.position = CGPoint(x:3,y:3)
        playerNode.addChild(eye)
        let pupil = SKShapeNode(circleOfRadius: 1.4)
        pupil.fillColor = UIColor(red:0.1,green:0.1,blue:0.2,alpha:1)
        pupil.strokeColor = .clear; pupil.position = CGPoint(x:0.5,y:0)
        eye.addChild(pupil)

        currentPlanet = levelConfig.startPlanet
        playerAngle   = levelConfig.startAngle
        playerNode.position  = surfacePos(planet: planets[currentPlanet], angle: playerAngle)
        playerNode.zRotation = playerAngle - .pi/2
        worldNode.addChild(playerNode)

        isJumping = false; departedPlanet = -1; jumpTimer = 0
        playerVel = .zero; levelComplete = false
    }

    private func surfacePos(planet: PlanetData, angle: CGFloat) -> CGPoint {
        CGPoint(x: planet.position.x + cos(angle)*(planet.radius+11),
                y: planet.position.y + sin(angle)*(planet.radius+11))
    }

    // MARK: - Controls

    private func setupControls() {
        // Place buttons in safe area corners — works in portrait and landscape
        let margin: CGFloat = 50
        let y: CGFloat      = -size.height/2 + margin
        let lx1: CGFloat    = -size.width/2  + margin
        let lx2: CGFloat    = -size.width/2  + margin * 2.4
        let rx: CGFloat     =  size.width/2  - margin

        leftBtn  = makeBtn("◀", CGPoint(x: lx1, y: y), "left")
        rightBtn = makeBtn("▶", CGPoint(x: lx2, y: y), "right")
        jumpBtn  = makeBtn("▲", CGPoint(x: rx,  y: y), "jump")
        addChild(leftBtn); addChild(rightBtn); addChild(jumpBtn)
    }

    private func makeBtn(_ label: String, _ pos: CGPoint, _ name: String) -> SKShapeNode {
        let btn = SKShapeNode(circleOfRadius: 30)
        btn.fillColor   = UIColor(white:1,alpha:0.07)
        btn.strokeColor = UIColor(white:1,alpha:0.22)
        btn.lineWidth   = 1.5; btn.position = pos; btn.zPosition = 100; btn.name = name
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = label; lbl.fontSize = 20
        lbl.fontColor = UIColor(white:0.9,alpha:0.8)
        lbl.verticalAlignmentMode = .center
        btn.addChild(lbl)
        return btn
    }

    private func setupHUD() {
        let cfg = levelConfig

        let t = SKLabelNode(fontNamed: "AvenirNext-Bold")
        t.text = "L\(cfg.number)  \(cfg.title)"
        t.fontSize = 14; t.fontColor = UIColor(white:0.75,alpha:1)
        t.horizontalAlignmentMode = .left
        t.position = CGPoint(x:-size.width/2+14, y:size.height/2-50)
        t.zPosition = 100; addChild(t)

        let tip = SKLabelNode(fontNamed: "AvenirNext-Regular")
        tip.text = cfg.tip; tip.fontSize = 11
        tip.fontColor = UIColor(white:0.35,alpha:1)
        tip.position = CGPoint(x:0, y:-size.height/2+48); tip.zPosition = 100
        addChild(tip)

        let flag = SKLabelNode(fontNamed: "AvenirNext-Regular")
        flag.text = "Find the 🚩"; flag.fontSize = 12
        flag.fontColor = UIColor(white:0.4,alpha:1)
        flag.position = CGPoint(x:0, y:size.height/2-50); flag.zPosition = 100
        addChild(flag)

        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text = "☰"; back.fontSize = 20
        back.fontColor = UIColor(white:0.4,alpha:1)
        back.horizontalAlignmentMode = .right
        back.position = CGPoint(x:size.width/2-16, y:size.height/2-52)
        back.zPosition = 100; back.name = "levels"
        addChild(back)

        coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        coinLabel.text = "🪙 0"
        coinLabel.fontSize = 15
        coinLabel.fontColor = UIColor(red:1.0,green:0.85,blue:0.15,alpha:1)
        coinLabel.horizontalAlignmentMode = .right
        coinLabel.position = CGPoint(x: size.width/2-16, y: size.height/2-78)
        coinLabel.zPosition = 100
        addChild(coinLabel)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc  = touch.location(in: self)
            let name = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first
            switch name {
            case "levels": goToSelect()
            case "left":   leftHeld  = true
            case "right":  rightHeld = true
            case "jump":   doJump()
            case "retry":  restartLevel()
            case "next":   nextLevel()
            case "back":   goToSelect()
            default: break
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc  = touch.location(in: self)
            let name = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first
            if name == "left"  { leftHeld  = false }
            if name == "right" { rightHeld = false }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        leftHeld = false; rightHeld = false
    }

    // MARK: - Jump

    private func doJump() {
        guard !isJumping && !levelComplete else { return }
        isJumping = true; departedPlanet = currentPlanet; jumpTimer = 0
        let p   = planets[currentPlanet]
        let dx  = playerNode.position.x - p.position.x
        let dy  = playerNode.position.y - p.position.y
        let len = max(hypot(dx,dy), 1)
        playerVel = CGVector(dx: dx/len * jumpSpeed, dy: dy/len * jumpSpeed)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0.016 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime
        guard !levelComplete else { return }

        if isJumping { updateJump(dt: CGFloat(dt)) }
        else         { settleTimer += CGFloat(dt); updateGrounded(dt: CGFloat(dt)); checkFlag() }
        syncWorld()
    }

    private func updateGrounded(dt: CGFloat) {
        if leftHeld  { playerAngle += walkSpeed * dt; facingRight = false }
        if rightHeld { playerAngle -= walkSpeed * dt; facingRight = true  }
        playerNode.position  = surfacePos(planet: planets[currentPlanet], angle: playerAngle)
        playerNode.zRotation = playerAngle - .pi/2
        playerNode.xScale    = facingRight ? 1 : -1
        checkCoinCollect()
    }

    private func checkCoinCollect() {
        let pos = playerNode.position
        for i in stride(from: coins.count - 1, through: 0, by: -1) {
            let c = coins[i]
            let d = hypot(pos.x - c.node.position.x, pos.y - c.node.position.y)
            if d < 55 {
                c.node.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.6, duration: 0.12),
                        SKAction.fadeOut(withDuration: 0.18)
                    ]),
                    SKAction.removeFromParent()
                ]))
                coins.remove(at: i)
                coinCount += 1
                coinLabel.text = "🪙 \(coinCount)"
            }
        }
    }

    private func updateJump(dt: CGFloat) {
        jumpTimer += dt

        let pos    = playerNode.position
        let inVoid = voidZones.contains { $0.contains(pos) }

        if inVoid {
            // Inside the low-gravity corridor — float regardless of planet zones
            playerVel.dx *= 0.998
            playerVel.dy *= 0.998
            // Orient toward nearest planet so player rotates naturally
            var nearestIdx = 0; var nearestDist = CGFloat.greatestFiniteMagnitude
            for (i, p) in planets.enumerated() {
                let d = hypot(pos.x - p.position.x, pos.y - p.position.y)
                if d < nearestDist { nearestDist = d; nearestIdx = i }
            }
            let np = planets[nearestIdx]
            playerNode.zRotation = atan2(pos.y - np.position.y,
                                          pos.x - np.position.x) - .pi/2
            // Land if touching a planet surface (grace period avoids instant re-land)
            if nearestDist <= np.radius + 12 && jumpTimer > 0.18 { land(on: nearestIdx) }
        } else {
            // Outside the corridor — normal gravity from nearest planet in range
            var bestIdx = -1; var bestDist = CGFloat.greatestFiniteMagnitude
            for (i, p) in planets.enumerated() {
                if i == departedPlanet && jumpTimer < 0.08 { continue }
                let d = hypot(pos.x - p.position.x, pos.y - p.position.y)
                if d < p.gravityRadius && d < bestDist { bestDist = d; bestIdx = i }
            }

            if bestIdx >= 0 {
                // In a gravity zone — strong pull back to planet
                let target = planets[bestIdx]
                let dx   = target.position.x - pos.x
                let dy   = target.position.y - pos.y
                let dist = max(hypot(dx, dy), 1)
                let pull = gravityStrength * min(1.0, target.radius / dist)
                playerVel.dx += (dx/dist) * pull * dt
                playerVel.dy += (dy/dist) * pull * dt
                playerNode.zRotation = atan2(pos.y - target.position.y,
                                              pos.x - target.position.x) - .pi/2
                if dist <= target.radius + 12 { land(on: bestIdx) }
            } else if jumpTimer > 0.15 {
                // Completely outside all zones and corridor — fall to nearest planet
                var nearestIdx = 0; var nearestDist = CGFloat.greatestFiniteMagnitude
                for (i, p) in planets.enumerated() {
                    let d = hypot(pos.x - p.position.x, pos.y - p.position.y)
                    if d < nearestDist { nearestDist = d; nearestIdx = i }
                }
                let target = planets[nearestIdx]
                let dx   = target.position.x - pos.x
                let dy   = target.position.y - pos.y
                let dist = max(hypot(dx, dy), 1)
                playerVel.dx += (dx/dist) * gravityStrength * 0.5 * dt
                playerVel.dy += (dy/dist) * gravityStrength * 0.5 * dt
                playerNode.zRotation = atan2(pos.y - target.position.y,
                                              pos.x - target.position.x) - .pi/2
                if nearestDist <= target.radius + 12 { land(on: nearestIdx) }
            }
        }

        playerNode.position.x += playerVel.dx * dt
        playerNode.position.y += playerVel.dy * dt
    }

    private func land(on idx: Int) {
        currentPlanet = idx
        let target    = planets[idx]
        playerAngle   = atan2(playerNode.position.y - target.position.y,
                               playerNode.position.x - target.position.x)
        playerNode.position  = surfacePos(planet: target, angle: playerAngle)
        playerNode.zRotation = playerAngle - .pi/2
        playerVel   = .zero; isJumping = false; settleTimer = 0
        playerNode.run(SKAction.sequence([
            SKAction.scale(to:1.3, duration:0.06),
            SKAction.scale(to:1.0, duration:0.10)
        ]))
        checkFlag()
    }

    // MARK: - Flag check

    private func checkFlag() {
        guard !levelComplete, let flag = flagNode else { return }
        if hypot(playerNode.position.x - flag.position.x,
                 playerNode.position.y - flag.position.y) < 32 {
            levelComplete = true
            showWin()
        }
    }

    private func showWin() {
        flagNode?.run(SKAction.sequence([
            SKAction.scale(to:2.0,duration:0.25),
            SKAction.fadeOut(withDuration:0.25)
        ]))
        for _ in 0..<20 {
            let spark = SKShapeNode(circleOfRadius: 4)
            spark.fillColor   = [UIColor.yellow,.red,.cyan,.green].randomElement()!
            spark.strokeColor = .clear
            spark.position    = playerNode.position; spark.zPosition = 20
            worldNode.addChild(spark)
            let a = CGFloat.random(in:0...(2 * .pi))
            let s = CGFloat.random(in:60...180)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x:cos(a)*s,y:sin(a)*s,duration:0.6),
                    SKAction.fadeOut(withDuration:0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        let hasNext = levelConfig.number < WorldBallLevels.all.count

        let overlay = SKShapeNode(rectOf: CGSize(width:260,height:165), cornerRadius:14)
        overlay.fillColor   = UIColor(red:0.04,green:0.04,blue:0.12,alpha:0.95)
        overlay.strokeColor = UIColor(red:1,green:0.3,blue:0.3,alpha:0.7)
        overlay.lineWidth   = 2; overlay.zPosition = 110
        addChild(overlay)

        let t = SKLabelNode(fontNamed:"AvenirNext-Bold")
        t.text = "🚩  Flag reached!"
        t.fontSize = 20; t.fontColor = UIColor(red:1,green:0.9,blue:0.3,alpha:1)
        t.verticalAlignmentMode = .center; t.position = CGPoint(x:0,y:46)
        t.zPosition = 111; overlay.addChild(t)

        let r = SKLabelNode(fontNamed:"AvenirNext-Regular")
        r.text = "Retry"; r.fontSize = 14; r.fontColor = UIColor(white:0.55,alpha:1)
        r.verticalAlignmentMode = .center
        r.position = CGPoint(x: hasNext ? -60 : 0, y:-4)
        r.zPosition = 111; r.name = "retry"; overlay.addChild(r)

        if hasNext {
            let n = SKLabelNode(fontNamed:"AvenirNext-Bold")
            n.text = "Next →"; n.fontSize = 14
            n.fontColor = UIColor(red:0.3,green:0.9,blue:0.5,alpha:1)
            n.verticalAlignmentMode = .center; n.position = CGPoint(x:55,y:-4)
            n.zPosition = 111; n.name = "next"; overlay.addChild(n)
        }

        let b = SKLabelNode(fontNamed:"AvenirNext-Regular")
        b.text = "Level Select"; b.fontSize = 12; b.fontColor = UIColor(white:0.38,alpha:1)
        b.verticalAlignmentMode = .center; b.position = CGPoint(x:0,y:-44)
        b.zPosition = 111; b.name = "back"; overlay.addChild(b)

        overlay.setScale(0.05)
        overlay.run(SKAction.sequence([
            SKAction.scale(to:1.05,duration:0.2),
            SKAction.scale(to:1.0, duration:0.08)
        ]))
    }

    // MARK: - Level actions

    private func restartLevel() {
        children.filter { $0.name == nil && ($0 as? SKShapeNode) != nil && $0.zPosition == 110 }
                .forEach { $0.removeFromParent() }
        // simpler: remove overlay by shape
        children.compactMap { $0 as? SKShapeNode }
                .filter { $0.zPosition == 110 }.forEach { $0.removeFromParent() }
        buildLevel()
        syncWorld()
    }

    private func nextLevel() {
        if let idx = WorldBallLevels.all.firstIndex(where: { $0.number == levelConfig.number }),
           idx + 1 < WorldBallLevels.all.count {
            levelConfig = WorldBallLevels.all[idx + 1]
        }
        children.compactMap { $0 as? SKShapeNode }
                .filter { $0.zPosition == 110 }.forEach { $0.removeFromParent() }
        buildLevel()
        syncWorld()
    }

    private func goToSelect() {
        let scene = WorldBallSelectScene(size: size)
        scene.anchorPoint = CGPoint(x:0.5,y:0.5); scene.scaleMode = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
    }

    // MARK: - Camera

    private func syncWorld() {
        if isJumping {
            let pos       = playerNode.position
            let inVoid    = voidZones.contains { $0.contains(pos) }
            let depart    = planets[departedPlanet]

            // Pick rotation reference:
            // - In void: slowly spin toward destination planet (farthest from departure)
            // - Otherwise: nearest planet
            let refPlanet: PlanetData
            if inVoid {
                // destination = planet that is NOT the departure and is closest ahead
                var destIdx = 0; var destDist = CGFloat.greatestFiniteMagnitude
                for (i, p) in planets.enumerated() {
                    if i == departedPlanet { continue }
                    let d = hypot(pos.x - p.position.x, pos.y - p.position.y)
                    if d < destDist { destDist = d; destIdx = i }
                }
                refPlanet = planets[destIdx]
            } else {
                var nearestIdx = departedPlanet; var nearestDist = CGFloat.greatestFiniteMagnitude
                for (i, p) in planets.enumerated() {
                    let d = hypot(pos.x - p.position.x, pos.y - p.position.y)
                    if d < nearestDist { nearestDist = d; nearestIdx = i }
                }
                refPlanet = planets[nearestIdx]
            }

            let toPlayer = atan2(pos.y - refPlanet.position.y,
                                 pos.x - refPlanet.position.x)
            let targetRot  = CGFloat.pi/2 - toPlayer

            // Rotation: glacially slow in void, normal otherwise
            let blendRot: CGFloat = inVoid ? 0.003 : 0.022
            worldNode.zRotation += shortestAngle(from: worldNode.zRotation, to: targetRot) * blendRot

            let r = worldNode.zRotation

            // Camera stays planet-anchored during jump — no tracking the airborne player
            // In void: slowly drift toward destination planet; outside: hold on departure
            let blendPos: CGFloat = inVoid ? 0.008 : 0.014
            let anchorPt: CGPoint = inVoid ? refPlanet.position : depart.position
            let destX = -(anchorPt.x * cos(r) - anchorPt.y * sin(r)) * worldScale
            let destY = -(anchorPt.x * sin(r) + anchorPt.y * cos(r)) * worldScale + planetScreenY
            worldNode.position.x += (destX - worldNode.position.x) * blendPos
            worldNode.position.y += (destY - worldNode.position.y) * blendPos

        } else {
            let targetRot = CGFloat.pi/2 - playerAngle
            let t      = min(settleTimer / 0.9, 1.0)
            let blend  = 0.04 + (0.18 - 0.04) * t
            worldNode.zRotation += shortestAngle(from: worldNode.zRotation, to: targetRot) * blend

            // Follow the player — must account for worldScale in the offset
            let r   = worldNode.zRotation
            let px  = playerNode.position.x, py = playerNode.position.y
            let destX = -(px*cos(r) - py*sin(r)) * worldScale
            let destY = -(px*sin(r) + py*cos(r)) * worldScale + planetScreenY
            worldNode.position.x += (destX - worldNode.position.x) * blend
            worldNode.position.y += (destY - worldNode.position.y) * blend
        }
    }

    private func shortestAngle(from a: CGFloat, to b: CGFloat) -> CGFloat {
        var d = b - a
        while d >  .pi { d -= 2 * .pi }
        while d < -.pi { d += 2 * .pi }
        return d
    }
}

// MARK: - PlanetData (local)
private struct PlanetData {
    var position:      CGPoint
    var radius:        CGFloat
    var color:         UIColor
    var gravityRadius: CGFloat
    var node:          SKNode
}

// MARK: - VoidZone — rectangular neutral corridor between two planets
private struct VoidZone {
    var center:  CGPoint
    var axisX:   CGFloat   // unit vector along planet-to-planet axis
    var axisY:   CGFloat
    var halfLen: CGFloat   // half-length along axis
    var halfWid: CGFloat   // half-width perpendicular

    func contains(_ point: CGPoint) -> Bool {
        let dx    = point.x - center.x
        let dy    = point.y - center.y
        let along = dx * axisX + dy * axisY          // projection onto axis
        let perp  = dx * (-axisY) + dy * axisX       // perpendicular
        return abs(along) <= halfLen && abs(perp) <= halfWid
    }
}
