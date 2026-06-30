import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - State
    var levelNumber = 1
    private var levelCfg: LevelConfig!
    private var activeBalls:    [Ball] = []
    private var ballsInFlight   = 0
    private var canDrop         = true
    private var aimX:  CGFloat  = 0
    private var lightningActive = false

    // MARK: - Node layers
    private var hud:          HUD!
    private var aimIndicator: SKShapeNode!
    private var bgLayer       = SKNode()
    private var pegLayer      = SKNode()
    private var gateNodes:    [Gate]    = []
    private var trapNodes:    [Trap]    = []
    private var powerUpNodes: [PowerUp] = []
    private var bucketNodes:  [Bucket]  = []

    // MARK: - Stuck detection
    private var lastPositions: [ObjectIdentifier: (point: CGPoint, time: TimeInterval)] = [:]

    // MARK: - Computed geometry (all in scene-center coordinates)
    private var W: CGFloat { size.width  }
    private var H: CGFloat { size.height }
    private var dropY: CGFloat { H / 2 - 100 }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = TempleTheme.background
        physicsWorld.gravity           = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate   = self
        physicsWorld.speed             = 1.0

        addChild(bgLayer)
        addChild(pegLayer)
        setupWalls()
        setupAimIndicator()
        setupHUD()
        loadLevel(levelNumber)
        #if DEBUG
        setupDevControls()
        #endif
    }

    // MARK: - Setup

    private func setupBackground(for level: Int) {
        bgLayer.removeAllChildren()

        let palettes: [(base: UIColor, fill: UIColor, mortar: UIColor)] = [
            (UIColor(red:0.14,green:0.10,blue:0.06,alpha:1),   // sandy ochre
             UIColor(red:0.22,green:0.17,blue:0.11,alpha:1),
             UIColor(red:0.10,green:0.08,blue:0.05,alpha:1)),
            (UIColor(red:0.08,green:0.10,blue:0.14,alpha:1),   // deep slate
             UIColor(red:0.13,green:0.15,blue:0.21,alpha:1),
             UIColor(red:0.06,green:0.07,blue:0.10,alpha:1)),
            (UIColor(red:0.06,green:0.11,blue:0.07,alpha:1),   // forest stone
             UIColor(red:0.10,green:0.17,blue:0.11,alpha:1),
             UIColor(red:0.04,green:0.08,blue:0.05,alpha:1)),
            (UIColor(red:0.12,green:0.06,blue:0.05,alpha:1),   // volcanic
             UIColor(red:0.20,green:0.09,blue:0.07,alpha:1),
             UIColor(red:0.09,green:0.04,blue:0.03,alpha:1)),
            (UIColor(red:0.09,green:0.07,blue:0.14,alpha:1),   // amethyst
             UIColor(red:0.15,green:0.11,blue:0.22,alpha:1),
             UIColor(red:0.07,green:0.05,blue:0.10,alpha:1)),
        ]
        let p   = palettes[((level - 1) / 10) % palettes.count]
        backgroundColor = p.base

        let hw  = W / 2; let hh = H / 2
        var rng = SeededRandom(seed: UInt64(level))

        // Build a jittered grid of shared points so every cell edge is exact
        let cols = 6; let rows = 10
        let cellW = W / CGFloat(cols)
        let cellH = H / CGFloat(rows)
        let jitterX = cellW * 0.28
        let jitterY = cellH * 0.28

        // pts[row][col] — (rows+1) × (cols+1) shared corner points
        var pts = [[CGPoint]]()
        for row in 0...rows {
            var rowPts = [CGPoint]()
            for col in 0...cols {
                let base = CGPoint(x: -hw + CGFloat(col) * cellW,
                                   y: -hh + CGFloat(row) * cellH)
                // Lock border points to the screen edge so no gap at sides
                let jx = (col == 0 || col == cols) ? 0 : rng.next() * jitterX * 2 - jitterX
                let jy = (row == 0 || row == rows) ? 0 : rng.next() * jitterY * 2 - jitterY
                rowPts.append(CGPoint(x: base.x + jx, y: base.y + jy))
            }
            pts.append(rowPts)
        }

        // Draw each cell using the 4 shared corners
        for row in 0..<rows {
            for col in 0..<cols {
                let tl = pts[row+1][col];   let tr = pts[row+1][col+1]
                let bl = pts[row][col];     let br = pts[row][col+1]

                let path = CGMutablePath()
                path.move(to: bl)
                path.addLine(to: br)
                path.addLine(to: tr)
                path.addLine(to: tl)
                path.closeSubpath()

                let node = SKShapeNode(path: path)
                // Subtle brightness variation per cell
                let bright = 0.55 + rng.next() * 0.90
                node.fillColor   = p.fill.withAlphaComponent(0.52 * bright)
                node.strokeColor = p.mortar.withAlphaComponent(0.85)
                node.lineWidth   = 1.0
                node.zPosition   = -10
                bgLayer.addChild(node)
            }
        }
    }

    private func setupWalls() {
        let hw = W / 2, hh = H / 2
        let edges: [(CGPoint, CGPoint)] = [
            (CGPoint(x: -hw, y: -hh), CGPoint(x: -hw, y: hh)),   // left
            (CGPoint(x:  hw, y: -hh), CGPoint(x:  hw, y: hh)),   // right
            (CGPoint(x: -hw, y: -hh), CGPoint(x:  hw, y: -hh))   // floor
        ]
        for (s, e) in edges {
            let n = SKNode()
            let b = SKPhysicsBody(edgeFrom: s, to: e)
            b.restitution         = 0.3
            b.friction            = 0.1
            b.categoryBitMask     = PhysicsCategory.wall
            b.collisionBitMask    = PhysicsCategory.ball
            n.physicsBody = b
            addChild(n)
        }
    }

    private func setupAimIndicator() {
        aimIndicator = SKShapeNode(circleOfRadius: Ball.radius + 5)
        aimIndicator.fillColor   = TempleTheme.torchOrange.withAlphaComponent(0.25)
        aimIndicator.strokeColor = TempleTheme.torchOrange.withAlphaComponent(0.85)
        aimIndicator.lineWidth   = 2
        aimIndicator.zPosition   = 20
        aimX = 0
        aimIndicator.position = CGPoint(x: aimX, y: dropY)
        addChild(aimIndicator)

        // Dotted guide line
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: -44))
        let dashed = path.copy(dashingWithPhase: 0, lengths: [5, 4])
        let line = SKShapeNode(path: dashed)
        line.strokeColor = TempleTheme.torchOrange.withAlphaComponent(0.4)
        line.lineWidth   = 1.5
        line.zPosition   = 19
        aimIndicator.addChild(line)
    }

    private func setupHUD() {
        hud = HUD()
        // Push below Dynamic Island / notch using safe area top inset
        let topInset = view?.safeAreaInsets.top ?? 0
        let hudOffset = max(topInset + 36, 60)
        hud.position  = CGPoint(x: 0, y: H / 2 - hudOffset)
        hud.zPosition = 50
        hud.onBallTypeSelected = { [weak self] _, _ in }
        addChild(hud)
    }

    // MARK: - Level Loading

    func loadLevel(_ number: Int) {
        // Clear
        pegLayer.removeAllChildren()
        gateNodes.forEach    { $0.removeFromParent() }; gateNodes.removeAll()
        trapNodes.forEach    { $0.removeFromParent() }; trapNodes.removeAll()
        powerUpNodes.forEach { $0.removeFromParent() }; powerUpNodes.removeAll()
        bucketNodes.forEach  { $0.removeFromParent() }; bucketNodes.removeAll()
        activeBalls.forEach  { $0.removeFromParent() }; activeBalls.removeAll()
        children.filter { $0.name == "divider" || $0.name == "endOverlay" }.forEach { $0.removeFromParent() }
        ballsInFlight = 0
        canDrop       = true
        lightningActive = false
        lastPositions.removeAll()

        levelCfg = LevelLoader.shared.config(for: number, screenWidth: W, screenHeight: H)
        setupBackground(for: number)

        // Ball type options (de-duplicate while preserving order)
        var seen = Set<String>()
        var typeOptions: [(BallType, String?)] = []
        for typeName in levelCfg.availableBallTypes {
            guard let bt = BallType(rawValue: typeName), !seen.contains(typeName) else { continue }
            seen.insert(typeName)
            if bt == .key {
                for kc in (levelCfg.keyColors.isEmpty ? ["cyan"] : levelCfg.keyColors) {
                    let key = "key_\(kc)"
                    if !seen.contains(key) { seen.insert(key); typeOptions.append((.key, kc)) }
                }
            } else {
                typeOptions.append((bt, nil))
            }
        }
        if typeOptions.isEmpty { typeOptions = [(.normal, nil)] }

        hud.configure(level: number, title: levelCfg.title,
                      balls: levelCfg.ballCount, target: levelCfg.targetScore,
                      ballTypes: typeOptions)

        // Pegs
        let pattern = PegPattern(rawValue: levelCfg.pegPattern) ?? .classic
        let positions = PegPatternGenerator.generate(
            pattern:     pattern,
            screenWidth: W,
            screenHeight: H,
            rows:        levelCfg.pegRows ?? 8,
            cols:        levelCfg.pegCols ?? 7
        )
        for p in positions {
            let peg = Peg(type: p.type)
            peg.position = CGPoint(x: p.x, y: p.y)
            pegLayer.addChild(peg)
        }

        // Gates
        for cfg in levelCfg.gates {
            let gate = Gate(
                width:          cfg.widthFrac * W,
                colorKey:       cfg.colorKey,
                initialState:   cfg.startOpen ? .open : .closed,
                toggleInterval: cfg.toggleInterval
            )
            gate.position = CGPoint(x: cfg.xFrac * W, y: cfg.yFrac * H)
            addChild(gate)
            gateNodes.append(gate)

            if cfg.toggleInterval > 0 {
                let wait   = SKAction.wait(forDuration: cfg.toggleInterval)
                let toggle = SKAction.run { [weak gate] in gate?.toggle() }
                gate.run(SKAction.repeatForever(SKAction.sequence([wait, toggle])))
            }
        }

        // Traps
        for cfg in levelCfg.traps {
            let trap = Trap(width: cfg.widthFrac * W)
            trap.position = CGPoint(x: cfg.xFrac * W, y: cfg.yFrac * H)
            addChild(trap)
            trapNodes.append(trap)
        }

        // Power-ups
        for cfg in levelCfg.powerUps {
            guard let pt = PowerUpType(rawValue: cfg.type) else { continue }
            let pu = PowerUp(type: pt)
            pu.position = CGPoint(x: cfg.xFrac * W, y: cfg.yFrac * H)
            addChild(pu)
            powerUpNodes.append(pu)
        }

        // Buckets
        let bCount = levelCfg.bucketPoints.count
        let bWidth = W / CGFloat(bCount)
        let bY     = -H / 2 + Bucket.height / 2 + 4

        for (i, pts) in levelCfg.bucketPoints.enumerated() {
            let bucket = Bucket(points: pts, width: bWidth)
            bucket.position = CGPoint(x: -W / 2 + bWidth * (CGFloat(i) + 0.5), y: bY)
            addChild(bucket)
            bucketNodes.append(bucket)
        }

        // Dividers between buckets
        for i in 1..<bCount {
            let div = SKShapeNode(rectOf: CGSize(width: 2, height: Bucket.height))
            div.fillColor   = UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1)
            div.strokeColor = .clear
            div.position    = CGPoint(x: -W / 2 + bWidth * CGFloat(i), y: bY)
            div.zPosition   = 4
            div.name        = "divider"
            addChild(div)
        }

        // Aim indicator reset
        aimX = 0
        aimIndicator.position = CGPoint(x: 0, y: dropY)
    }

    // MARK: - Input

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateAim(x: touch.location(in: self).x)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dropBall()
    }

    private func updateAim(x: CGFloat) {
        let halfW = W / 2 - Ball.radius - 6
        aimX = max(-halfW, min(halfW, x))
        aimIndicator.position = CGPoint(x: aimX, y: dropY)
    }

    private func dropBall() {
        guard canDrop, hud.ballsLeft > 0 else { return }
        canDrop = false

        let ball = Ball(type: hud.selectedBallType, keyColor: hud.selectedKeyColor)
        ball.position = CGPoint(x: aimX, y: dropY)
        ball.alpha = 0
        addChild(ball)
        activeBalls.append(ball)
        ballsInFlight += 1
        hud.decrementBalls()

        ball.run(SKAction.fadeIn(withDuration: 0.08))
        let nudge = CGFloat.random(in: -2.0...2.0)
        ball.physicsBody?.applyImpulse(CGVector(dx: nudge, dy: 0))
        // Allow next ball after short delay (don't block on in-flight ball)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.canDrop = true }
        ]))
    }

    // MARK: - Update (stuck detection)

    override func update(_ currentTime: TimeInterval) {
        for ball in activeBalls {
            let id = ObjectIdentifier(ball)
            if let last = lastPositions[id] {
                let d = hypot(ball.position.x - last.point.x, ball.position.y - last.point.y)
                if d > 2.0 {
                    lastPositions[id] = (ball.position, currentTime)
                } else if currentTime - last.time > 0.55 {
                    let nudge = CGFloat.random(in: -10...10)
                    ball.physicsBody?.applyImpulse(CGVector(dx: nudge, dy: -3))
                    lastPositions[id] = (ball.position, currentTime)
                }
            } else {
                lastPositions[id] = (ball.position, currentTime)
            }
        }
        lastPositions = lastPositions.filter { id, _ in
            activeBalls.contains { ObjectIdentifier($0) == id }
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask
        let combined = catA | catB

        func node<T: SKNode>(of type: T.Type) -> T? {
            (contact.bodyA.node as? T) ?? (contact.bodyB.node as? T)
        }
        func ballNode() -> Ball? { node(of: Ball.self) }

        // Ball ↔ Peg
        if combined == (PhysicsCategory.ball | PhysicsCategory.peg) {
            if let peg = node(of: Peg.self), let ball = ballNode() {
                peg.onHit()
                Effects.pegSpark(at: contact.contactPoint, in: self)
                if peg.type == .multiplier {
                    hud.addPoints(500)
                    Effects.floatingScore(500, at: peg.position, in: self)
                }
                // Heavy ball destroys normal/fragile pegs
                if ball.ballType == .heavy && peg.type != .multiplier {
                    peg.destroy()
                }
            }
        }

        // Ball ↔ Bucket
        if combined == (PhysicsCategory.ball | PhysicsCategory.bucket) {
            if let ball = ballNode(), let bucket = node(of: Bucket.self) {
                ballLanded(ball: ball, bucket: bucket)
            }
        }

        // Ball ↔ Gate (key ball unlocking)
        if combined == (PhysicsCategory.ball | PhysicsCategory.gate) {
            if let ball = ballNode(), ball.ballType == .key,
               let gate = node(of: Gate.self),
               let gck = gate.colorKey,
               gck == ball.keyColor {
                gate.openGate()
                // Remove gate permanently
                gate.removeAction(forKey: "toggle")
            }
        }

        // Ball ↔ TrapSensor
        if combined == (PhysicsCategory.ball | PhysicsCategory.trapSensor) {
            if let sensorNode = (contact.bodyA.categoryBitMask == PhysicsCategory.trapSensor
                                 ? contact.bodyA.node : contact.bodyB.node),
               let trap = sensorNode.parent as? Trap {
                trap.trigger()
            }
        }

        // Ball ↔ PowerUp
        if combined == (PhysicsCategory.ball | PhysicsCategory.powerUp) {
            if let ball = ballNode(), let pu = node(of: PowerUp.self) {
                pu.collect { [weak self] in
                    self?.triggerPowerUp(pu.powerType, ball: ball)
                }
            }
        }
    }

    // MARK: - Ball Landed

    private func ballLanded(ball: Ball, bucket: Bucket) {
        guard activeBalls.contains(ball) else { return }
        activeBalls.removeAll { $0 === ball }
        ballsInFlight -= 1

        bucket.flash()
        let mult = levelCfg.multiplier ?? 1
        var pts  = bucket.points * mult

        if ball.ballType == .bomb {
            triggerBombExplosion(at: ball.position)
            pts += 500
        }

        hud.addPoints(pts)
        if pts > 0 { Effects.floatingScore(pts, at: bucket.position, in: self) }

        ball.run(SKAction.sequence([
            SKAction.scale(to: 0, duration: 0.22),
            SKAction.removeFromParent()
        ]))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.checkRoundEnd()
        }
    }

    private func checkRoundEnd() {
        if hud.ballsLeft == 0 && ballsInFlight == 0 {
            showRoundEnd()
        }
    }

    // MARK: - Power-up Effects

    private func triggerPowerUp(_ type: PowerUpType, ball: Ball) {
        switch type {
        case .lightning:
            guard !lightningActive else { return }
            lightningActive = true
            Effects.lightning(in: self) { [weak self] in self?.lightningActive = false }
            // Destroy all non-multiplier pegs with a delay-cascade
            let pegs = pegLayer.children.compactMap { $0 as? Peg }.filter { $0.type == .normal || $0.type == .fragile }
            for (i, peg) in pegs.enumerated() {
                let delay = SKAction.wait(forDuration: Double(i) * 0.04)
                peg.run(SKAction.sequence([delay, SKAction.run { peg.destroy() }]))
            }
            hud.addPoints(2000)
            Effects.floatingScore(2000, at: .zero, in: self)

        case .extraBall:
            hud.addBall()
            Effects.floatingScore(0, at: ball.position, in: self) // visual feedback
            let lbl = SKLabelNode(fontNamed: TempleTheme.titleFont)
            lbl.text = "+1 Ball!"
            lbl.fontSize = 22
            lbl.fontColor = TempleTheme.powerExtraBall
            lbl.position = ball.position
            lbl.zPosition = 80
            addChild(lbl)
            lbl.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 60, duration: 0.8),
                    SKAction.sequence([SKAction.wait(forDuration: 0.4), SKAction.fadeOut(withDuration: 0.4)])
                ]),
                SKAction.removeFromParent()
            ]))

        case .bomb:
            triggerBombExplosion(at: ball.position, radius: 120)
            hud.addPoints(3000)
            Effects.floatingScore(3000, at: ball.position, in: self)
        }
    }

    private func triggerBombExplosion(at point: CGPoint, radius: CGFloat = 80) {
        Effects.bombExplosion(at: point, in: self, radius: radius)
        // Destroy pegs within blast radius
        for peg in pegLayer.children.compactMap({ $0 as? Peg }) {
            let dist = hypot(peg.position.x - point.x, peg.position.y - point.y)
            if dist < radius && peg.type != .multiplier {
                let delay = SKAction.wait(forDuration: Double(dist / radius) * 0.2)
                peg.run(SKAction.sequence([delay, SKAction.run { peg.destroy() }]))
            }
        }
    }

    // MARK: - Round End Overlay

    private func showRoundEnd() {
        let passed = hud.score >= levelCfg.targetScore
        let isLast = levelNumber >= LevelLoader.shared.totalCount

        let overlay = SKShapeNode(rectOf: CGSize(width: min(W - 40, 300), height: 210), cornerRadius: 16)
        overlay.fillColor   = TempleTheme.overlayBG
        overlay.strokeColor = passed ? TempleTheme.gold : UIColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1)
        overlay.lineWidth   = 2
        overlay.zPosition   = 100
        overlay.name        = "endOverlay"
        addChild(overlay)

        let titleLbl = SKLabelNode(fontNamed: TempleTheme.titleFont)
        titleLbl.text     = passed ? (isLast ? "YOU WIN! 🏆" : "Level Clear!") : "Try Again"
        titleLbl.fontSize  = 22
        titleLbl.fontColor = passed ? TempleTheme.gold : UIColor(red: 0.85, green: 0.35, blue: 0.15, alpha: 1)
        titleLbl.position  = CGPoint(x: 0, y: 68)
        titleLbl.zPosition = 101
        overlay.addChild(titleLbl)

        let scoreLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        scoreLbl.text      = "Score: \(hud.score)"
        scoreLbl.fontSize   = 20
        scoreLbl.fontColor  = TempleTheme.brightText
        scoreLbl.position   = CGPoint(x: 0, y: 30)
        scoreLbl.zPosition  = 101
        overlay.addChild(scoreLbl)

        let targetLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        targetLbl.text     = "Target: \(levelCfg.targetScore)"
        targetLbl.fontSize  = 14
        targetLbl.fontColor = TempleTheme.dimText
        targetLbl.position  = CGPoint(x: 0, y: 4)
        targetLbl.zPosition = 101
        overlay.addChild(targetLbl)

        let hintLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        hintLbl.text      = passed ? (isLast ? "Tap to play again" : "Tap to continue") : "Tap to retry"
        hintLbl.fontSize   = 13
        hintLbl.fontColor  = TempleTheme.dimText
        hintLbl.position   = CGPoint(x: 0, y: -30)
        hintLbl.zPosition  = 101
        overlay.addChild(hintLbl)

        // Level select button
        let selectLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        selectLbl.text     = "Level Select"
        selectLbl.fontSize  = 13
        selectLbl.fontColor = TempleTheme.gold.withAlphaComponent(0.7)
        selectLbl.position  = CGPoint(x: 0, y: -58)
        selectLbl.zPosition = 101
        selectLbl.name      = "levelSelectBtn"
        overlay.addChild(selectLbl)

        overlay.setScale(0.05)
        overlay.run(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.22),
            SKAction.scale(to: 1.00, duration: 0.10)
        ]))

        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.run { [weak self, weak overlay] in
                guard let self = self else { return }
                // Allow tap to proceed
                overlay?.run(SKAction.sequence([
                    SKAction.wait(forDuration: 30),
                    SKAction.removeFromParent()
                ]))
            }
        ]))
    }

    // handleOverlayTap is called from the extension's touchesBegan override
    private func handleOverlayTap(at location: CGPoint) -> Bool {
        guard let overlay = childNode(withName: "endOverlay") else { return false }

        if let selectBtn = overlay.childNode(withName: "levelSelectBtn") {
            let btnLocal = overlay.convert(location, from: self)
            if selectBtn.contains(btnLocal) {
                overlay.removeFromParent()
                goToLevelSelect()
                return true
            }
        }

        overlay.removeFromParent()
        let passed = hud.score >= levelCfg.targetScore
        let isLast = levelNumber >= LevelLoader.shared.totalCount
        if passed && !isLast {
            levelNumber += 1
        }
        if isLast && passed { levelNumber = 1 }
        loadLevel(levelNumber)
        return true
    }

    private func goToLevelSelect() {
        let scene = LevelSelectScene(size: size)
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Dev Tools (DEBUG only)
    #if DEBUG
    func setupDevControls() {
        let total = LevelLoader.shared.totalCount
        let btnY  = -H / 2 + 30

        let prevBtn = makeDevButton(text: "◀", name: "devPrev", x: -W / 2 + 36, y: btnY)
        let nextBtn = makeDevButton(text: "▶", name: "devNext", x:  W / 2 - 36, y: btnY)
        addChild(prevBtn)
        addChild(nextBtn)

        let lvlBtn = makeDevButton(text: "L:\(levelNumber)/\(total)", name: "devLvlLabel",
                                   x: 0, y: btnY)
        lvlBtn.name = "devLvlLabel"
        addChild(lvlBtn)
    }

    private func makeDevButton(text: String, name: String, x: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.name     = name
        node.position = CGPoint(x: x, y: y)
        node.zPosition = 200

        let bg = SKShapeNode(rectOf: CGSize(width: 52, height: 26), cornerRadius: 5)
        bg.fillColor   = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.85)
        bg.strokeColor = TempleTheme.gold.withAlphaComponent(0.5)
        bg.lineWidth   = 1
        node.addChild(bg)

        let lbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        lbl.text     = text
        lbl.fontSize  = 12
        lbl.fontColor = TempleTheme.gold
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)
        return node
    }

    private func handleDevTap(at loc: CGPoint) -> Bool {
        let total = LevelLoader.shared.totalCount
        let names = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }
        if names.contains("devPrev") {
            levelNumber = max(1, levelNumber - 1)
            loadLevel(levelNumber)
            updateDevLabel()
            return true
        }
        if names.contains("devNext") {
            levelNumber = min(total, levelNumber + 1)
            loadLevel(levelNumber)
            updateDevLabel()
            return true
        }
        return false
    }

    private func updateDevLabel() {
        if let node = childNode(withName: "devLvlLabel"),
           let lbl = node.children.compactMap({ $0 as? SKLabelNode }).first {
            lbl.text = "L:\(levelNumber)/\(LevelLoader.shared.totalCount)"
        }
    }
    #endif
}

// MARK: - touchesBegan override to intercept overlay

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)

        if handleOverlayTap(at: loc) { return }

        #if DEBUG
        if handleDevTap(at: loc) { return }
        #endif

        let hudLoc = convert(loc, to: hud)
        if hud.handleTap(at: hudLoc) { return }

        updateAim(x: loc.x)
    }
}

// MARK: - Seeded RNG (reproducible per level)
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 1 }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
}
