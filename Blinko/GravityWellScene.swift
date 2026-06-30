import SpriteKit

class GravityWellScene: SKScene {

    // MARK: - Config
    var levelConfig: GravityWellLevelConfig = GravityWellLevels.all[0]

    // MARK: - Physics
    private var G: CGFloat { 70_000 + CGFloat(levelConfig.number - 1) * 6_500 }

    // MARK: - Nodes
    private var wellNode:       SKNode!
    private var planetNode:     SKShapeNode?
    private var trailNodes:     [SKShapeNode] = []
    private var moonNodes:      [SKNode]      = []
    private var trajectoryDots: [SKShapeNode] = []
    private var exitGateNode:   SKNode?
    private var entryZoneNode:  SKNode?

    // MARK: - State
    private var planetVelocity: CGVector   = .zero
    private var planetActive    = false
    private var moonAngles:     [CGFloat]  = []
    private var dragStart:      CGPoint?
    private var dragIndicator:  SKShapeNode?

    // Survival
    private var orbitTime:      TimeInterval = 0
    private var survived        = false

    // Transit
    private var transitDone     = false

    // Bonus moon
    private var bonusMoonSpawned = false

    private var lastUpdate:     TimeInterval = 0

    // MARK: - HUD nodes
    private var scoreLbl:  SKLabelNode!
    private var statusLbl: SKLabelNode!
    private var tipLbl:    SKLabelNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)
        setupStars()
        setupWell()
        loadLevel()
        setupHUD()
    }

    // MARK: - Setup

    private func setupStars() {
        for _ in 0..<150 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.6))
            s.fillColor   = .white.withAlphaComponent(CGFloat.random(in: 0.2...0.8))
            s.strokeColor = .clear
            s.position    = CGPoint(x: CGFloat.random(in: -size.width/2...size.width/2),
                                    y: CGFloat.random(in: -size.height/2...size.height/2))
            s.zPosition   = -10
            addChild(s)
        }
    }

    private func setupWell() {
        wellNode = SKNode()
        for (r, a) in [(80.0, 0.06), (55.0, 0.10), (35.0, 0.16)] {
            let ring = SKShapeNode(circleOfRadius: CGFloat(r))
            ring.fillColor   = .clear
            ring.strokeColor = UIColor(red: 0.4, green: 0.1, blue: 0.9, alpha: CGFloat(a))
            ring.lineWidth   = CGFloat(r) * 0.4
            wellNode.addChild(ring)
        }
        let core = SKShapeNode(circleOfRadius: 18)
        core.fillColor   = UIColor(red: 0.15, green: 0.0, blue: 0.35, alpha: 1)
        core.strokeColor = UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 0.8)
        core.lineWidth   = 2
        wellNode.addChild(core)
        core.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.9),
            SKAction.scale(to: 0.90, duration: 0.9)
        ])))
        addChild(wellNode)
    }

    private func loadLevel() {
        // Clear old moons / gate
        moonNodes.forEach { $0.removeFromParent() }; moonNodes.removeAll()
        moonAngles.removeAll()
        exitGateNode?.removeFromParent();  exitGateNode  = nil
        entryZoneNode?.removeFromParent(); entryZoneNode = nil
        bonusMoonSpawned = false
        orbitTime   = 0
        transitDone = false
        survived    = false

        // Moons
        for cfg in levelConfig.moons {
            let moon = makeMoonNode(cfg: cfg)
            let x = cos(cfg.startAngle) * cfg.orbitRadius
            let y = sin(cfg.startAngle) * cfg.orbitRadius
            moon.position = CGPoint(x: x, y: y)
            addChild(moon)
            moonNodes.append(moon)
            moonAngles.append(cfg.startAngle)

            // Orbit ring (faint)
            let orbit = SKShapeNode(circleOfRadius: cfg.orbitRadius)
            orbit.fillColor   = .clear
            orbit.strokeColor = cfg.color.withAlphaComponent(0.07)
            orbit.lineWidth   = 1
            orbit.zPosition   = -5
            addChild(orbit)
        }

        // Transit: entry zone + exit gate
        if levelConfig.mode == .transit {
            if let ea = levelConfig.entryAngle {
                entryZoneNode = makeEntryZone(angle: ea, radius: 230)
                addChild(entryZoneNode!)
            }
            if let exA = levelConfig.exitAngle, let exR = levelConfig.exitRadius {
                exitGateNode = makeExitGate(angle: exA, radius: exR)
                addChild(exitGateNode!)
            }
        }
    }

    private func makeMoonNode(cfg: MoonConfig) -> SKNode {
        let node = SKNode()
        let body = SKShapeNode(circleOfRadius: cfg.size)
        body.fillColor   = cfg.color
        body.strokeColor = cfg.color.withAlphaComponent(0.4)
        body.lineWidth   = 2
        node.addChild(body)
        return node
    }

    private func makeEntryZone(angle: CGFloat, radius: CGFloat) -> SKNode {
        let node = SKNode()
        // Arc indicating launch zone
        let arcPath = CGMutablePath()
        arcPath.addArc(center: .zero, radius: radius,
                       startAngle: angle - 0.35, endAngle: angle + 0.35,
                       clockwise: false)
        let arc = SKShapeNode(path: arcPath)
        arc.strokeColor = UIColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 0.6)
        arc.lineWidth   = 6
        node.addChild(arc)

        let lbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        lbl.text     = "LAUNCH"
        lbl.fontSize  = 10
        lbl.fontColor = UIColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 0.7)
        lbl.position  = CGPoint(x: cos(angle) * (radius + 18),
                                y: sin(angle) * (radius + 18))
        lbl.horizontalAlignmentMode = .center
        node.addChild(lbl)
        return node
    }

    private func makeExitGate(angle: CGFloat, radius: CGFloat) -> SKNode {
        let node  = SKNode()
        node.name = "exitGate"
        let gateW: CGFloat = 50, gateH: CGFloat = 8

        let gate = SKShapeNode(rectOf: CGSize(width: gateW, height: gateH), cornerRadius: 3)
        gate.fillColor   = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.85)
        gate.strokeColor = .white.withAlphaComponent(0.5)
        gate.lineWidth   = 1
        gate.zRotation   = angle + .pi/2
        gate.name        = "exitGateRect"
        node.addChild(gate)

        // Glow
        let glow = SKShapeNode(rectOf: CGSize(width: gateW + 10, height: gateH + 10), cornerRadius: 5)
        glow.fillColor   = .clear
        glow.strokeColor = UIColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.25)
        glow.lineWidth   = 6
        glow.zRotation   = angle + .pi/2
        node.addChild(glow)

        node.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6)
        ])
        node.run(SKAction.repeatForever(pulse))
        return node
    }

    // MARK: - HUD

    private func setupHUD() {
        let cfg = levelConfig

        let titleLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        titleLbl.text     = "L\(cfg.number)  \(cfg.title)"
        titleLbl.fontSize  = 15
        titleLbl.fontColor = UIColor(white: 0.8, alpha: 1)
        titleLbl.horizontalAlignmentMode = .left
        titleLbl.position  = CGPoint(x: -size.width/2 + 14, y: size.height/2 - 50)
        titleLbl.zPosition = 50
        addChild(titleLbl)

        scoreLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLbl.text      = cfg.mode == .survival ? "0.0s" : "LAUNCH"
        scoreLbl.fontSize   = 18
        scoreLbl.fontColor  = UIColor(red: 0.7, green: 1.0, blue: 0.7, alpha: 1)
        scoreLbl.horizontalAlignmentMode = .right
        scoreLbl.position   = CGPoint(x: size.width/2 - 14, y: size.height/2 - 50)
        scoreLbl.zPosition  = 50
        addChild(scoreLbl)

        if cfg.mode == .survival, let target = cfg.targetTime {
            let par = SKLabelNode(fontNamed: "AvenirNext-Regular")
            par.text     = "Par: \(Int(target))s"
            par.fontSize  = 11
            par.fontColor = UIColor(white: 0.4, alpha: 1)
            par.horizontalAlignmentMode = .right
            par.position  = CGPoint(x: size.width/2 - 14, y: size.height/2 - 68)
            par.zPosition = 50
            addChild(par)
        }

        statusLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        statusLbl.text     = ""
        statusLbl.fontSize  = 13
        statusLbl.fontColor = UIColor(white: 0.6, alpha: 1)
        statusLbl.position  = CGPoint(x: 0, y: -size.height/2 + 48)
        statusLbl.zPosition = 50
        addChild(statusLbl)

        tipLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        tipLbl.text     = cfg.tip
        tipLbl.fontSize  = 11
        tipLbl.fontColor = UIColor(white: 0.35, alpha: 1)
        tipLbl.position  = CGPoint(x: 0, y: -size.height/2 + 30)
        tipLbl.zPosition = 50
        addChild(tipLbl)

        // Back + levels nav
        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text     = "☰"
        back.fontSize  = 20
        back.fontColor = UIColor(white: 0.4, alpha: 1)
        back.position  = CGPoint(x: -size.width/2 + 24, y: size.height/2 - 68)
        back.name      = "levels"
        back.zPosition = 50
        addChild(back)
    }

    // MARK: - Touch

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = dragStart else { return }
        let end = touch.location(in: self)
        updateDragIndicator(from: start, to: end)
        updateTrajectoryPreview(from: start, dragEnd: end)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = dragStart else { return }
        let end = touch.location(in: self)
        dragStart = nil
        dragIndicator?.removeFromParent(); dragIndicator = nil
        clearTrajectoryDots()

        let dx = (start.x - end.x) * 1.1
        let dy = (start.y - end.y) * 1.1
        launchPlanet(at: start, velocity: CGVector(dx: dx, dy: dy))
    }

    // MARK: - Drag indicator

    private func spawnDragIndicator(at point: CGPoint) {
        dragIndicator?.removeFromParent()
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor   = UIColor(white: 1, alpha: 0.12)
        node.strokeColor = UIColor(white: 1, alpha: 0.5)
        node.lineWidth   = 1.5
        node.position    = point
        node.zPosition   = 30
        addChild(node)
        dragIndicator = node
    }

    private func updateDragIndicator(from start: CGPoint, to end: CGPoint) {
        dragIndicator?.position = start
        dragIndicator?.removeAllChildren()
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: (start.x - end.x)*0.4, y: (start.y - end.y)*0.4))
        let arrow = SKShapeNode(path: path)
        arrow.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 0.7)
        arrow.lineWidth   = 2
        dragIndicator?.addChild(arrow)
    }

    // MARK: - Trajectory preview

    private func updateTrajectoryPreview(from start: CGPoint, dragEnd: CGPoint) {
        clearTrajectoryDots()
        let vel = CGVector(dx: (start.x - dragEnd.x) * 1.1,
                           dy: (start.y - dragEnd.y) * 1.1)
        let pts = predictedPath(from: start, velocity: vel, steps: 120, dt: 0.05)
        for (i, pt) in pts.enumerated() {
            guard i % 4 == 0 else { continue }
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor   = UIColor(red: 0.3, green: 1, blue: 0.5,
                                      alpha: (1 - CGFloat(i)/CGFloat(pts.count)) * 0.55)
            dot.strokeColor = .clear
            dot.position    = pt
            dot.zPosition   = 8
            addChild(dot)
            trajectoryDots.append(dot)
        }
    }

    private func clearTrajectoryDots() {
        trajectoryDots.forEach { $0.removeFromParent() }
        trajectoryDots.removeAll()
    }

    private func predictedPath(from pos: CGPoint, velocity: CGVector,
                                steps: Int, dt: CGFloat) -> [CGPoint] {
        var p = pos, v = velocity, pts: [CGPoint] = []
        for _ in 0..<steps {
            let dx = -p.x, dy = -p.y
            let d2 = max(dx*dx + dy*dy, 400)
            let d  = sqrt(d2)
            let f  = G / d2
            v.dx += f * (dx/d) * dt
            v.dy += f * (dy/d) * dt
            p.x  += v.dx * dt
            p.y  += v.dy * dt
            if d < 28 { break }
            pts.append(p)
        }
        return pts
    }

    // MARK: - Planet launch

    private func launchPlanet(at position: CGPoint, velocity: CGVector) {
        planetNode?.removeFromParent()
        trailNodes.forEach { $0.removeFromParent() }
        trailNodes.removeAll()
        orbitTime = 0

        let planet = SKShapeNode(circleOfRadius: 9)
        planet.fillColor   = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)
        planet.strokeColor = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 0.8)
        planet.lineWidth   = 2
        planet.position    = position
        planet.zPosition   = 10
        addChild(planet)

        planetNode     = planet
        planetVelocity = velocity
        planetActive   = true
        scoreLbl.text  = levelConfig.mode == .survival ? "0.0s" : "→"
        statusLbl.text = ""
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0.016 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime

        updateMoons(dt: dt)

        guard planetActive, let planet = planetNode else { return }

        // Gravity
        let dx = -planet.position.x, dy = -planet.position.y
        let d2   = max(dx*dx + dy*dy, 400)
        let dist = sqrt(d2)
        let f    = G / d2
        planetVelocity.dx += f * (dx/dist) * CGFloat(dt)
        planetVelocity.dy += f * (dy/dist) * CGFloat(dt)
        planet.position.x += planetVelocity.dx * CGFloat(dt)
        planet.position.y += planetVelocity.dy * CGFloat(dt)

        spawnTrailDot(at: planet.position)

        // Absorbed by well
        if dist < 28 { endLevel(success: false, reason: "Absorbed!"); return }

        // Out of bounds
        let hw = size.width/2 + 50, hh = size.height/2 + 50
        if abs(planet.position.x) > hw || abs(planet.position.y) > hh {
            endLevel(success: false, reason: "Lost to the void…"); return
        }

        // Moon collision
        for (i, moon) in moonNodes.enumerated() {
            let mcfg = levelConfig.moons[i < levelConfig.moons.count ? i : levelConfig.moons.count-1]
            if hypot(planet.position.x - moon.position.x,
                     planet.position.y - moon.position.y) < mcfg.size + 9 {
                endLevel(success: false, reason: "Moon collision!"); return
            }
        }
        // Bonus moon collision (if spawned as extra child)
        if bonusMoonSpawned, let bm = childNode(withName: "bonusMoon") {
            if hypot(planet.position.x - bm.position.x,
                     planet.position.y - bm.position.y) < 25 {
                endLevel(success: false, reason: "Moon collision!"); return
            }
        }

        if levelConfig.mode == .survival {
            updateSurvival(dt: dt, planet: planet, dist: dist)
        } else {
            updateTransit(planet: planet)
        }
    }

    private func updateMoons(dt: TimeInterval) {
        for i in 0..<moonNodes.count {
            let cfg = levelConfig.moons[i < levelConfig.moons.count ? i : levelConfig.moons.count-1]
            moonAngles[i] += cfg.speed * CGFloat(dt)
            moonNodes[i].position = CGPoint(
                x: cos(moonAngles[i]) * cfg.orbitRadius,
                y: sin(moonAngles[i]) * cfg.orbitRadius
            )
        }
    }

    private func updateSurvival(dt: TimeInterval, planet: SKNode, dist: CGFloat) {
        orbitTime += dt
        let speed = hypot(planetVelocity.dx, planetVelocity.dy)
        let orbSpeed = sqrt(G / dist)
        let isOrbiting = abs(speed - orbSpeed) < orbSpeed * 0.7 && dist < 340

        scoreLbl.fontColor = isOrbiting
            ? UIColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1)
            : UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1)
        scoreLbl.text = String(format: "%.1fs", orbitTime)

        // Bonus moon spawn
        if let bAt = levelConfig.bonusMoonAt,
           orbitTime >= bAt && !bonusMoonSpawned {
            bonusMoonSpawned = true
            spawnBonusMoon()
        }

        // Check target
        if let target = levelConfig.targetTime, orbitTime >= target && !survived {
            survived = true
            endLevel(success: true, reason: "Par beaten! \(String(format: "%.1f", orbitTime))s")
        }
    }

    private func updateTransit(planet: SKNode) {
        guard !transitDone, let gate = exitGateNode else { return }
        let dx = planet.position.x - gate.position.x
        let dy = planet.position.y - gate.position.y
        if hypot(dx, dy) < 35 {
            transitDone = true
            endLevel(success: true, reason: "Gate cleared! 🎯")
        }
    }

    private func spawnBonusMoon() {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let r: CGFloat = 200
        let moon = SKShapeNode(circleOfRadius: 13)
        moon.fillColor   = UIColor(red: 0.9, green: 0.3, blue: 0.9, alpha: 1)
        moon.strokeColor = UIColor(red: 1.0, green: 0.5, blue: 1.0, alpha: 0.4)
        moon.lineWidth   = 2
        moon.position    = CGPoint(x: cos(angle)*r, y: sin(angle)*r)
        moon.name        = "bonusMoon"
        moon.zPosition   = 5
        addChild(moon)

        let orbit = SKShapeNode(circleOfRadius: r)
        orbit.fillColor   = .clear
        orbit.strokeColor = UIColor(red: 0.9, green: 0.3, blue: 0.9, alpha: 0.08)
        orbit.lineWidth   = 1
        addChild(orbit)

        var bmAngle = angle
        run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.016),
            SKAction.run { [weak self, weak moon] in
                bmAngle += 0.7 * 0.016
                moon?.position = CGPoint(x: cos(bmAngle)*r, y: sin(bmAngle)*r)
                _ = self
            }
        ])), withKey: "bonusMoonOrbit")

        // Warning flash
        statusLbl.text      = "⚠ New moon!"
        statusLbl.fontColor = UIColor(red: 1, green: 0.4, blue: 1, alpha: 1)
        statusLbl.run(SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.run { [weak self] in
                self?.statusLbl.text = ""
                self?.statusLbl.fontColor = UIColor(white: 0.6, alpha: 1)
            }
        ]))
    }

    private func spawnTrailDot(at point: CGPoint) {
        let dot = SKShapeNode(circleOfRadius: 2.5)
        dot.fillColor   = UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.55)
        dot.strokeColor = .clear
        dot.position    = point
        dot.zPosition   = 5
        addChild(dot)
        trailNodes.append(dot)
        dot.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
        if trailNodes.count > 100 { trailNodes.removeFirst() }
    }

    // MARK: - End

    private func endLevel(success: Bool, reason: String) {
        planetActive = false
        removeAction(forKey: "bonusMoonOrbit")

        // Burst
        if let planet = planetNode {
            burstEffect(at: planet.position, success: success)
            planet.removeFromParent()
            planetNode = nil
        }

        let nextIdx = GravityWellLevels.all.firstIndex(where: { $0.number == levelConfig.number })
            .map { $0 + 1 }
        let hasNext = nextIdx != nil && nextIdx! < GravityWellLevels.all.count

        showEndOverlay(success: success, reason: reason, hasNext: hasNext)
    }

    private func burstEffect(at point: CGPoint, success: Bool) {
        for _ in 0..<14 {
            let spark = SKShapeNode(circleOfRadius: 3)
            spark.fillColor   = success
                ? UIColor(red: 0.4, green: 1, blue: 0.5, alpha: 0.9)
                : UIColor(red: 1, green: 0.3, blue: 0.2, alpha: 0.9)
            spark.strokeColor = .clear
            spark.position    = point
            spark.zPosition   = 20
            addChild(spark)
            let a = CGFloat.random(in: 0...(2 * .pi))
            let s = CGFloat.random(in: 50...140)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(a)*s, y: sin(a)*s, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showEndOverlay(success: Bool, reason: String, hasNext: Bool) {
        let overlay = SKShapeNode(rectOf: CGSize(width: 280, height: 190), cornerRadius: 14)
        overlay.fillColor   = UIColor(red: 0.04, green: 0.04, blue: 0.12, alpha: 0.96)
        overlay.strokeColor = success
            ? UIColor(red: 0.3, green: 1, blue: 0.5, alpha: 0.8)
            : UIColor(red: 1, green: 0.3, blue: 0.2, alpha: 0.8)
        overlay.lineWidth   = 2
        overlay.zPosition   = 100
        overlay.name        = "overlay"
        addChild(overlay)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text     = success ? "✓  Clear!" : "✗  Destroyed"
        title.fontSize  = 20
        title.fontColor = success ? UIColor(red: 0.4, green: 1, blue: 0.5, alpha: 1)
                                  : UIColor(red: 1, green: 0.4, blue: 0.3, alpha: 1)
        title.verticalAlignmentMode = .center
        title.position  = CGPoint(x: 0, y: 58)
        title.zPosition = 101
        overlay.addChild(title)

        let reasonLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        reasonLbl.text     = reason
        reasonLbl.fontSize  = 14
        reasonLbl.fontColor = UIColor(white: 0.75, alpha: 1)
        reasonLbl.verticalAlignmentMode = .center
        reasonLbl.position  = CGPoint(x: 0, y: 24)
        reasonLbl.zPosition = 101
        overlay.addChild(reasonLbl)

        let retryLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        retryLbl.text     = "Retry"
        retryLbl.fontSize  = 14
        retryLbl.fontColor = UIColor(white: 0.6, alpha: 1)
        retryLbl.verticalAlignmentMode = .center
        retryLbl.position  = CGPoint(x: hasNext ? -60 : 0, y: -20)
        retryLbl.zPosition = 101
        retryLbl.name      = "retry"
        overlay.addChild(retryLbl)

        if success && hasNext {
            let nextLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
            nextLbl.text     = "Next →"
            nextLbl.fontSize  = 14
            nextLbl.fontColor = UIColor(red: 0.3, green: 0.8, blue: 1, alpha: 1)
            nextLbl.verticalAlignmentMode = .center
            nextLbl.position  = CGPoint(x: 55, y: -20)
            nextLbl.zPosition = 101
            nextLbl.name      = "next"
            overlay.addChild(nextLbl)
        }

        let levelsLbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
        levelsLbl.text     = "Level Select"
        levelsLbl.fontSize  = 12
        levelsLbl.fontColor = UIColor(white: 0.4, alpha: 1)
        levelsLbl.verticalAlignmentMode = .center
        levelsLbl.position  = CGPoint(x: 0, y: -52)
        levelsLbl.zPosition = 101
        levelsLbl.name      = "select"
        overlay.addChild(levelsLbl)

        overlay.setScale(0.05)
        overlay.run(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.2),
            SKAction.scale(to: 1.00, duration: 0.08)
        ]))

        // Tap handler via name lookup in touchesBegan
    }

    // MARK: - Overlay taps (second pass in touchesBegan)
    // We re-route through touchesBegan using node names

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let names = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name ?? $0.parent?.parent?.name }

        if names.contains("levels") { goToSelect(); return }

        if names.contains("retry") {
            children.filter { $0.name == "overlay" }.forEach { $0.removeFromParent() }
            resetForRetry(); return
        }
        if names.contains("next") {
            if let idx = GravityWellLevels.all.firstIndex(where: { $0.number == levelConfig.number }),
               idx + 1 < GravityWellLevels.all.count {
                levelConfig = GravityWellLevels.all[idx + 1]
                children.filter { $0.name == "overlay" }.forEach { $0.removeFromParent() }
                resetForRetry()
            }
            return
        }
        if names.contains("select") { goToSelect(); return }

        if transitDone || survived { return }

        dragStart = loc
        spawnDragIndicator(at: loc)
    }

    private func resetForRetry() {
        trailNodes.forEach { $0.removeFromParent() }; trailNodes.removeAll()
        trajectoryDots.forEach { $0.removeFromParent() }; trajectoryDots.removeAll()
        childNode(withName: "bonusMoon")?.removeFromParent()
        removeAction(forKey: "bonusMoonOrbit")
        // Remove orbit rings
        children.filter { ($0 as? SKShapeNode)?.strokeColor == UIColor(white: 0, alpha: 0.07) }
                .forEach { $0.removeFromParent() }
        loadLevel()
    }

    private func goToSelect() {
        let scene = GravityWellSelectScene(size: size)
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
    }
}
