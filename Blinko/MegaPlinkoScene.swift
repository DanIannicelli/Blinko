import SpriteKit
import CoreMotion

// MARK: - Powerup type

private enum PowerupKind: CaseIterable {
    case lightning, ghost, heavy, magnet, tiny

    var emoji: String {
        switch self {
        case .lightning: return "⚡"
        case .ghost:     return "👻"
        case .heavy:     return "🪨"
        case .magnet:    return "🧲"
        case .tiny:      return "🔮"
        }
    }
    var label: String {
        switch self {
        case .lightning: return "LIGHTNING"
        case .ghost:     return "GHOST"
        case .heavy:     return "HEAVY"
        case .magnet:    return "MAGNET"
        case .tiny:      return "TINY"
        }
    }
    var color: UIColor {
        switch self {
        case .lightning: return UIColor(red:1.0,green:0.9,blue:0.1,alpha:1)
        case .ghost:     return UIColor(red:0.7,green:0.9,blue:1.0,alpha:1)
        case .heavy:     return UIColor(red:0.7,green:0.4,blue:0.1,alpha:1)
        case .magnet:    return UIColor(red:0.3,green:0.8,blue:1.0,alpha:1)
        case .tiny:      return UIColor(red:0.8,green:0.4,blue:1.0,alpha:1)
        }
    }
    var duration: TimeInterval {
        switch self {
        case .lightning: return 0       // instant
        case .ghost:     return 4.0
        case .heavy:     return 5.0
        case .magnet:    return 5.0
        case .tiny:      return 6.0
        }
    }
}

// MARK: - Active effect

private struct ActiveEffect {
    let kind: PowerupKind
    var remaining: TimeInterval
}

// MARK: - MegaPlinkoScene

class MegaPlinkoScene: SKScene, SKPhysicsContactDelegate {

    // MARK: Constants
    private let boardScale: CGFloat = 20
    private var boardH: CGFloat { size.height * boardScale }
    private var W: CGFloat { size.width }
    private var H: CGFloat { size.height }
    private let ballRadius: CGFloat = 14
    private let tiltSensitivity: CGFloat = 18.0

    // MARK: Nodes
    private var cam = SKCameraNode()
    private var worldNode = SKNode()
    private var ball: SKShapeNode?
    private var ballGlow: SKShapeNode?
    private var goalNode: SKShapeNode!

    // MARK: HUD nodes (parented to cam)
    private var depthLabel: SKLabelNode!
    private var powerupBadge: SKShapeNode!
    private var powerupEmoji: SKLabelNode!
    private var powerupTimer: SKLabelNode!
    private var powerupBar: SKShapeNode!
    private var powerupBarFill: SKShapeNode!
    private var depthFillNode: SKShapeNode!   // depth meter fill

    // MARK: Motion
    private let motionManager = CMMotionManager()
    private var tiltX: CGFloat = 0           // smoothed lateral tilt

    // MARK: State
    private var dropped = false
    private var levelComplete = false
    private var aimX: CGFloat = 0
    private var aimIndicator: SKShapeNode!
    private var activeEffect: ActiveEffect?
    private var pegNodes: [SKShapeNode] = []  // track for heavy-smash
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        camera = cam
        addChild(cam)
        addChild(worldNode)

        buildBoard()
        spawnPowerups()
        setupHUD()
        setupAim()

        cam.position = CGPoint(x: 0, y: boardH / 2 - H / 2)
        startTilt()
    }

    override func willMove(from view: SKView) {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Tilt

    private func startTilt() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates()
    }

    // MARK: - Board

    private func buildBoard() {
        buildBackground()
        buildWalls()
        buildPegs()
        buildGoal()
    }

    private func buildBackground() {
        let segCount = 40
        let segH = boardH / CGFloat(segCount)
        for i in 0..<segCount {
            let t  = CGFloat(i) / CGFloat(segCount)
            let bg = SKShapeNode(rectOf: CGSize(width: W, height: segH))
            bg.fillColor   = UIColor(red: 0.04 + t*0.08, green: 0.03 + t*0.04, blue: 0.08 + t*0.12, alpha: 1)
            bg.strokeColor = .clear
            bg.position    = CGPoint(x: 0, y: boardH/2 - segH*(CGFloat(i)+0.5))
            worldNode.addChild(bg)
        }
        addRockGrid()
        addWaterfalls()
        addDepthMarkers()
    }

    private func addDepthMarkers() {
        for i in 1..<Int(boardScale) {
            let y   = boardH/2 - H * CGFloat(i)
            let lbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
            lbl.text      = "— \(i * 100)m —"
            lbl.fontSize  = 12
            lbl.fontColor = UIColor(white: 1, alpha: 0.15)
            lbl.verticalAlignmentMode = .center
            lbl.position  = CGPoint(x: 0, y: y)
            worldNode.addChild(lbl)
        }
    }

    private func addRockGrid() {
        var rng  = SeededRandom2(seed: 77)
        let cols = 5; let rows = 80
        let cellW = W / CGFloat(cols)
        let cellH = boardH / CGFloat(rows)
        let jx = cellW * 0.25; let jy = cellH * 0.25

        var pts = [[CGPoint]]()
        for row in 0...rows {
            var rowPts = [CGPoint]()
            for col in 0...cols {
                let base = CGPoint(x: -W/2 + CGFloat(col)*cellW,
                                   y:  boardH/2 - CGFloat(row)*cellH)
                let ox = (col == 0 || col == cols) ? 0 : rng.next()*jx*2 - jx
                let oy = (row == 0 || row == rows) ? 0 : rng.next()*jy*2 - jy
                rowPts.append(CGPoint(x: base.x+ox, y: base.y+oy))
            }
            pts.append(rowPts)
        }
        for row in 0..<rows {
            for col in 0..<cols {
                let tl = pts[row][col]; let tr = pts[row][col+1]
                let bl = pts[row+1][col]; let br = pts[row+1][col+1]
                let path = CGMutablePath()
                path.move(to: bl); path.addLine(to: br)
                path.addLine(to: tr); path.addLine(to: tl)
                path.closeSubpath()
                let node = SKShapeNode(path: path)
                let bright = 0.5 + rng.next()*0.8
                node.fillColor   = UIColor(red:0.14,green:0.10,blue:0.06,alpha:0.45*bright)
                node.strokeColor = UIColor(red:0.10,green:0.08,blue:0.05,alpha:0.7)
                node.lineWidth   = 0.8; node.zPosition = -10
                worldNode.addChild(node)
                if rng.next() < 0.25 {
                    let cx = (bl.x+br.x+tr.x+tl.x)/4; let cy = (bl.y+br.y+tr.y+tl.y)/4
                    let cp = CGMutablePath()
                    cp.move(to: CGPoint(x:cx+rng.next()*cellW*0.3-cellW*0.15, y:cy+rng.next()*cellH*0.3-cellH*0.15))
                    cp.addLine(to: CGPoint(x:cx+rng.next()*cellW*0.3-cellW*0.15, y:cy+rng.next()*cellH*0.3-cellH*0.15))
                    let crack = SKShapeNode(path: cp)
                    crack.strokeColor = UIColor(red:0.10,green:0.08,blue:0.05,alpha:0.5)
                    crack.lineWidth = 0.7; crack.zPosition = -9
                    worldNode.addChild(crack)
                }
            }
        }
    }

    private func addWaterfalls() {
        var rng = SeededRandom2(seed: 42)
        for _ in 0..<8 {
            let x     = rng.next()*W*0.9 - W*0.45
            let sH    = boardH * (0.25 + rng.next()*0.5)
            let startY = boardH/2 - rng.next()*boardH*0.3
            let wid   = 3 + rng.next()*9
            let alpha = 0.05 + rng.next()*0.12
            let spd   = 2.0 + rng.next()*5.0
            let streak = SKShapeNode(rectOf: CGSize(width:wid, height:sH), cornerRadius:wid/2)
            streak.fillColor   = UIColor(red:0.5,green:0.75,blue:1.0,alpha:alpha)
            streak.strokeColor = .clear; streak.zPosition = -8
            streak.position    = CGPoint(x:x, y:startY)
            worldNode.addChild(streak)
            streak.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x:0, y:-sH*1.5, duration:spd),
                SKAction.moveBy(x:0, y: sH*1.5, duration:0)
            ])))
            streak.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to:alpha*0.3, duration:1.2),
                SKAction.fadeAlpha(to:alpha,      duration:1.2)
            ])))
        }
    }

    private func buildWalls() {
        let top = boardH/2; let bottom = -boardH/2
        for (s,e) in [(CGPoint(x:-W/2,y:bottom), CGPoint(x:-W/2,y:top)),
                      (CGPoint(x: W/2,y:bottom), CGPoint(x: W/2,y:top)),
                      (CGPoint(x:-W/2,y:bottom), CGPoint(x: W/2,y:bottom))] {
            let n = SKNode()
            let b = SKPhysicsBody(edgeFrom: s, to: e)
            b.restitution = 0.3; b.friction = 0.1
            b.categoryBitMask  = PhysicsCategory.wall
            b.collisionBitMask = PhysicsCategory.ball
            n.physicsBody = b
            worldNode.addChild(n)
        }
    }

    private func buildPegs() {
        let pegRows = 140; let pegCols = 7
        let rowSpacing = boardH / CGFloat(pegRows+1)
        let colSpacing = W     / CGFloat(pegCols+1)
        let pegR: CGFloat = 6

        for row in 1...pegRows {
            let y      = boardH/2 - rowSpacing*CGFloat(row)
            let offset = (row%2==0) ? colSpacing/2 : 0
            for col in 1...pegCols {
                let x = -W/2 + colSpacing*CGFloat(col) + offset
                if abs(x) > W/2 - pegR { continue }
                let isGold = (row+col)%12 == 0
                let peg = SKShapeNode(circleOfRadius: pegR)
                peg.fillColor   = isGold ? UIColor(red:0.72,green:0.55,blue:0.12,alpha:1)
                                         : UIColor(red:0.32,green:0.26,blue:0.18,alpha:1)
                peg.strokeColor = isGold ? UIColor(red:1.0,green:0.85,blue:0.3,alpha:0.7)
                                         : UIColor(red:0.48,green:0.38,blue:0.22,alpha:0.6)
                peg.lineWidth  = isGold ? 2 : 1
                peg.position   = CGPoint(x:x, y:y)
                peg.zPosition  = 5
                if isGold {
                    let glow = SKShapeNode(circleOfRadius: pegR+5)
                    glow.fillColor = .clear
                    glow.strokeColor = UIColor(red:1,green:0.85,blue:0.3,alpha:0.25)
                    glow.lineWidth = 3
                    glow.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to:0.05, duration:0.7),
                        SKAction.fadeAlpha(to:0.5,  duration:0.7)
                    ])))
                    peg.addChild(glow)
                }
                let body = SKPhysicsBody(circleOfRadius: pegR)
                body.isDynamic = false; body.restitution = 0.5; body.friction = 0.2
                body.categoryBitMask    = PhysicsCategory.peg
                body.collisionBitMask   = PhysicsCategory.ball
                body.contactTestBitMask = PhysicsCategory.ball
                peg.physicsBody = body
                worldNode.addChild(peg)
                pegNodes.append(peg)
            }
        }
    }

    private func buildGoal() {
        let goalW: CGFloat = W * 0.35
        let goalY = -boardH/2 + 40
        let base = SKShapeNode(rectOf: CGSize(width:goalW, height:18), cornerRadius:9)
        base.fillColor   = UIColor(red:0.9,green:0.75,blue:0.1,alpha:1)
        base.strokeColor = UIColor(red:1,green:0.95,blue:0.4,alpha:0.9)
        base.lineWidth   = 2.5; base.zPosition = 10
        base.position    = CGPoint(x:0, y:goalY)
        worldNode.addChild(base)
        for r in [CGFloat(30),55,80] {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.fillColor = .clear
            ring.strokeColor = UIColor(red:1,green:0.9,blue:0.2,alpha:0.18)
            ring.lineWidth = 6; ring.zPosition = 9
            ring.position = CGPoint(x:0, y:goalY+4)
            ring.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to:0.03, duration:1.0),
                SKAction.fadeAlpha(to:0.35, duration:1.0)
            ])))
            worldNode.addChild(ring)
        }
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
        lbl.text = "★  GOAL  ★"; lbl.fontSize = 16
        lbl.fontColor = UIColor(red:1,green:0.95,blue:0.3,alpha:1)
        lbl.verticalAlignmentMode = .center
        lbl.position = CGPoint(x:0, y:goalY+30); lbl.zPosition = 11
        worldNode.addChild(lbl)
        goalNode = base
        let body = SKPhysicsBody(rectangleOf: CGSize(width:goalW, height:18))
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.bucket
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = 0
        base.physicsBody = body
    }

    // MARK: - Powerup spawning

    private func spawnPowerups() {
        var rng = SeededRandom2(seed: 123)
        let count = 30          // powerups across full board
        let kinds = PowerupKind.allCases
        for i in 0..<count {
            // distribute evenly in depth, random horizontal
            let depthFrac = (CGFloat(i) + 0.5 + rng.next()*0.4 - 0.2) / CGFloat(count)
            let y = boardH/2 - depthFrac * (boardH - 100) - 80
            let x = (rng.next() - 0.5) * (W - 60)
            let kind = kinds[Int(rng.next() * CGFloat(kinds.count)) % kinds.count]
            makePowerupNode(kind: kind, at: CGPoint(x:x, y:y))
        }
    }

    private func makePowerupNode(kind: PowerupKind, at pos: CGPoint) {
        let container = SKNode()
        container.position = pos; container.zPosition = 15
        container.name = "powerup_\(kind.label)"

        // Outer ring
        let ring = SKShapeNode(circleOfRadius: 20)
        ring.fillColor   = kind.color.withAlphaComponent(0.12)
        ring.strokeColor = kind.color.withAlphaComponent(0.8)
        ring.lineWidth   = 2
        ring.name = "powerup_\(kind.label)"
        container.addChild(ring)

        // Pulse ring
        let pulse = SKShapeNode(circleOfRadius: 20)
        pulse.fillColor = .clear
        pulse.strokeColor = kind.color.withAlphaComponent(0.4)
        pulse.lineWidth = 4
        pulse.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.group([SKAction.scale(to:2.0, duration:0.9),
                            SKAction.fadeOut(withDuration:0.9)]),
            SKAction.group([SKAction.scale(to:1.0, duration:0),
                            SKAction.fadeIn(withDuration:0)])
        ])))
        container.addChild(pulse)

        let emoji = SKLabelNode(text: kind.emoji)
        emoji.fontSize = 20; emoji.verticalAlignmentMode = .center
        emoji.name = "powerup_\(kind.label)"
        container.addChild(emoji)

        // Float animation
        container.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x:0, y:8, duration:1.0),
            SKAction.moveBy(x:0, y:-8, duration:1.0)
        ])))

        // Physics sensor
        let body = SKPhysicsBody(circleOfRadius: 20)
        body.isDynamic = false
        body.categoryBitMask    = PhysicsCategory.powerUp
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = 0
        container.physicsBody = body
        worldNode.addChild(container)
    }

    // MARK: - HUD

    private func setupHUD() {
        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "Mega Plinko"; title.fontSize = 16
        title.fontColor = TempleTheme.gold
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -W/2+12, y: H/2-50)
        title.zPosition = 100
        cam.addChild(title)

        // Depth label (live)
        depthLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
        depthLabel.fontSize = 12
        depthLabel.fontColor = UIColor(white:0.5,alpha:1)
        depthLabel.horizontalAlignmentMode = .left
        depthLabel.position = CGPoint(x: -W/2+12, y: H/2-68)
        depthLabel.zPosition = 100
        cam.addChild(depthLabel)

        // Back
        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text = "☰"; back.fontSize = 22
        back.fontColor = UIColor(white:0.5,alpha:1)
        back.horizontalAlignmentMode = .right
        back.position = CGPoint(x: W/2-16, y: H/2-52)
        back.zPosition = 100; back.name = "back"
        cam.addChild(back)

        // Bottom tip
        let tip = SKLabelNode(fontNamed: "AvenirNext-Regular")
        tip.text = "Tap to drop  ·  tilt to steer"
        tip.fontSize = 11; tip.fontColor = UIColor(white:0.3,alpha:1)
        tip.position = CGPoint(x:0, y:-H/2+20); tip.zPosition = 100
        cam.addChild(tip)

        // Depth meter (right edge)
        let meterBg = SKShapeNode(rectOf: CGSize(width:6, height:H*0.6), cornerRadius:3)
        meterBg.fillColor   = UIColor(white:1,alpha:0.06)
        meterBg.strokeColor = UIColor(white:1,alpha:0.12)
        meterBg.lineWidth   = 1
        meterBg.position    = CGPoint(x: W/2-14, y: 0)
        meterBg.zPosition   = 100
        cam.addChild(meterBg)

        depthFillNode = SKShapeNode(rectOf: CGSize(width:4, height:1), cornerRadius:2)
        depthFillNode.fillColor   = TempleTheme.gold
        depthFillNode.strokeColor = .clear
        depthFillNode.zPosition   = 101
        depthFillNode.position    = CGPoint(x: W/2-14, y: H*0.3)
        cam.addChild(depthFillNode)

        // Powerup badge (hidden until active)
        setupPowerupBadge()
    }

    private func setupPowerupBadge() {
        powerupBadge = SKShapeNode(rectOf: CGSize(width:130, height:42), cornerRadius:10)
        powerupBadge.fillColor   = UIColor(red:0.08,green:0.06,blue:0.12,alpha:0.95)
        powerupBadge.strokeColor = UIColor(white:1,alpha:0.2)
        powerupBadge.lineWidth   = 1.5
        powerupBadge.position    = CGPoint(x: 0, y: H/2-54)
        powerupBadge.zPosition   = 110
        powerupBadge.alpha       = 0
        cam.addChild(powerupBadge)

        powerupEmoji = SKLabelNode(text:"")
        powerupEmoji.fontSize = 20; powerupEmoji.verticalAlignmentMode = .center
        powerupEmoji.position = CGPoint(x:-44, y:4)
        powerupBadge.addChild(powerupEmoji)

        powerupTimer = SKLabelNode(fontNamed:"AvenirNext-Bold")
        powerupTimer.fontSize = 14; powerupTimer.fontColor = .white
        powerupTimer.verticalAlignmentMode = .center
        powerupTimer.horizontalAlignmentMode = .left
        powerupTimer.position = CGPoint(x:-24, y:4)
        powerupBadge.addChild(powerupTimer)

        // Progress bar
        let barBg = SKShapeNode(rectOf: CGSize(width:100, height:4), cornerRadius:2)
        barBg.fillColor = UIColor(white:1,alpha:0.1); barBg.strokeColor = .clear
        barBg.position = CGPoint(x:0, y:-13)
        powerupBadge.addChild(barBg)

        powerupBarFill = SKShapeNode(rectOf: CGSize(width:100, height:4), cornerRadius:2)
        powerupBarFill.fillColor = TempleTheme.gold; powerupBarFill.strokeColor = .clear
        powerupBarFill.position = CGPoint(x:0, y:-13)
        powerupBadge.addChild(powerupBarFill)
    }

    private func setupAim() {
        aimIndicator = SKShapeNode(circleOfRadius: ballRadius)
        aimIndicator.fillColor   = TempleTheme.torchOrange.withAlphaComponent(0.3)
        aimIndicator.strokeColor = TempleTheme.torchOrange.withAlphaComponent(0.9)
        aimIndicator.lineWidth   = 2; aimIndicator.zPosition = 50
        aimIndicator.position    = CGPoint(x:0, y:boardH/2-80)
        worldNode.addChild(aimIndicator)
        aimIndicator.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to:1.2, duration:0.5),
            SKAction.scale(to:0.9, duration:0.5)
        ])))

        // Dashed drop line
        let line = SKShapeNode()
        let lp = CGMutablePath()
        lp.move(to: CGPoint(x:0, y:boardH/2-40))
        lp.addLine(to: CGPoint(x:0, y:boardH/2-76))
        line.path = lp
        line.strokeColor = TempleTheme.torchOrange.withAlphaComponent(0.4)
        line.lineWidth = 1
        line.zPosition = 49
        worldNode.addChild(line)
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let hit = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first
        if hit == "back" { goBack(); return }
        if hit == "retry" { restartScene(); return }
        if !dropped {
            let worldLoc = cam.convert(loc, to: worldNode)
            aimX = max(-W/2+20, min(W/2-20, worldLoc.x))
            aimIndicator.position.x = aimX
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !dropped else { return }
        guard let loc = touches.first?.location(in: self) else { return }
        let hit = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first
        if hit == "back" || hit == "retry" { return }
        dropBall()
    }

    private func dropBall() {
        guard !dropped else { return }
        dropped = true
        aimIndicator.removeFromParent()

        let b = SKShapeNode(circleOfRadius: ballRadius)
        b.fillColor   = TempleTheme.ballNormal
        b.strokeColor = TempleTheme.ballNormal.withAlphaComponent(0.5)
        b.lineWidth   = 2; b.zPosition = 20
        b.position    = CGPoint(x:aimX, y:boardH/2-60)
        worldNode.addChild(b)

        // Inner glow
        ballGlow = SKShapeNode(circleOfRadius: ballRadius+6)
        ballGlow!.fillColor = .clear
        ballGlow!.strokeColor = TempleTheme.ballNormal.withAlphaComponent(0.3)
        ballGlow!.lineWidth = 4
        b.addChild(ballGlow!)

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.restitution        = 0.55
        body.friction           = 0.05
        body.density            = 1.0
        body.linearDamping      = 0.08
        body.categoryBitMask    = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.peg | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
        b.physicsBody = body
        body.applyImpulse(CGVector(dx: CGFloat.random(in:-2...2), dy:0))
        ball = b
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0.016 : min(currentTime - lastUpdateTime, 0.05)
        lastUpdateTime = currentTime

        guard let b = ball, !levelComplete else { return }

        // Tilt steering
        applyTilt(to: b)

        // Magnet: pull toward center X
        if activeEffect?.kind == .magnet {
            let pullForce = -b.position.x * 0.5
            b.physicsBody?.applyForce(CGVector(dx: pullForce, dy: 0))
        }

        // Camera follow
        let ballY = b.position.y
        let minY  = -boardH/2 + H/2
        let maxY  =  boardH/2 - H/2
        let targetY = max(minY, min(maxY, ballY))
        cam.position.y += (targetY - cam.position.y) * 0.12

        // Off bottom
        if ballY < -boardH/2 - 50 { showResult(won: false); return }

        // Update active effect timer
        if var eff = activeEffect {
            eff.remaining -= dt
            activeEffect = eff
            if eff.remaining <= 0 {
                expireEffect(eff.kind)
                activeEffect = nil
                hidePowerupBadge()
            } else {
                updatePowerupBadge(eff)
            }
        }

        // Depth HUD
        let traveled = boardH/2 - ballY
        let depthM   = Int(traveled / boardH * 2000)
        depthLabel.text = "\(depthM)m"

        // Depth fill bar
        let fillFrac = max(0, min(1, traveled / boardH))
        let fillH    = fillFrac * H * 0.6
        let fillRect = CGRect(x:-2, y:-fillH/2, width:4, height:fillH)
        depthFillNode.path = CGPath(roundedRect: fillRect, cornerWidth:2, cornerHeight:2, transform: nil)
        depthFillNode.position.y = H*0.3 - fillH/2
    }

    private func applyTilt(to b: SKShapeNode) {
        guard let data = motionManager.accelerometerData else { return }
        let raw = CGFloat(data.acceleration.x)
        tiltX += (raw - tiltX) * 0.25   // smooth
        let force = tiltX * tiltSensitivity
        b.physicsBody?.applyForce(CGVector(dx: force, dy: 0))
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let combined = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if combined == (PhysicsCategory.ball | PhysicsCategory.bucket) {
            guard !levelComplete else { return }
            levelComplete = true
            showResult(won: true)
            return
        }

        if combined == (PhysicsCategory.ball | PhysicsCategory.powerUp) {
            let powerupNode = contact.bodyA.categoryBitMask == PhysicsCategory.powerUp
                ? contact.bodyA.node : contact.bodyB.node
            if let node = powerupNode, let name = node.name,
               name.hasPrefix("powerup_") {
                let label = String(name.dropFirst("powerup_".count))
                if let kind = PowerupKind.allCases.first(where: { $0.label == label }) {
                    DispatchQueue.main.async { [weak self] in
                        self?.collectPowerup(kind: kind, node: node)
                    }
                }
            }
        }
    }

    // MARK: - Powerup effects

    private func collectPowerup(kind: PowerupKind, node: SKNode?) {
        // Collect animation
        node?.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to:2.0, duration:0.2),
                            SKAction.fadeOut(withDuration:0.2)]),
            SKAction.removeFromParent()
        ]))

        // Flash screen color briefly
        let flash = SKShapeNode(rectOf: CGSize(width:W, height:H))
        flash.fillColor   = kind.color.withAlphaComponent(0.25)
        flash.strokeColor = .clear; flash.zPosition = 105
        cam.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Cancel current effect first
        if let cur = activeEffect { expireEffect(cur.kind) }

        switch kind {
        case .lightning:
            applyLightning()
            // lightning is instant, no active effect
            return
        case .ghost:
            applyGhost()
        case .heavy:
            applyHeavy()
        case .magnet:
            break   // handled in update loop
        case .tiny:
            applyTiny()
        }

        activeEffect = ActiveEffect(kind: kind, remaining: kind.duration)
        showPowerupBadge(kind: kind)
    }

    private func applyLightning() {
        guard let b = ball else { return }
        // Massive downward burst
        b.physicsBody?.velocity = CGVector(dx: b.physicsBody?.velocity.dx ?? 0, dy: -800)
        b.fillColor   = PowerupKind.lightning.color
        b.strokeColor = PowerupKind.lightning.color
        ballGlow?.strokeColor = PowerupKind.lightning.color.withAlphaComponent(0.6)
        // Spawn lightning sparks around ball
        for _ in 0..<16 {
            let spark = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in:2...5), height: CGFloat.random(in:6...18)))
            spark.fillColor   = PowerupKind.lightning.color
            spark.strokeColor = .clear; spark.zPosition = 25
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist  = CGFloat.random(in: 16...40)
            spark.position = CGPoint(x: b.position.x + cos(angle)*dist,
                                     y: b.position.y + sin(angle)*dist)
            spark.zRotation = angle
            worldNode.addChild(spark)
            spark.run(SKAction.sequence([
                SKAction.fadeOut(withDuration:0.4),
                SKAction.removeFromParent()
            ]))
        }
        // Restore color after 0.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.restoreBallAppearance()
        }
    }

    private func applyGhost() {
        guard let b = ball else { return }
        b.physicsBody?.collisionBitMask = PhysicsCategory.wall   // pass through pegs
        b.physicsBody?.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
        b.alpha = 0.45
        b.fillColor   = PowerupKind.ghost.color
        b.strokeColor = PowerupKind.ghost.color
        ballGlow?.strokeColor = PowerupKind.ghost.color.withAlphaComponent(0.6)
    }

    private func applyHeavy() {
        guard let b = ball else { return }
        b.physicsBody?.density = 6.0
        b.fillColor   = PowerupKind.heavy.color
        b.strokeColor = PowerupKind.heavy.color
        ballGlow?.strokeColor = PowerupKind.heavy.color.withAlphaComponent(0.6)
        // Smash pegs within radius on each peg contact — handled by watching contacts
        b.physicsBody?.contactTestBitMask |= PhysicsCategory.peg
    }

    private func applyTiny() {
        guard let b = ball else { return }
        b.run(SKAction.scale(to: 0.5, duration: 0.2))
        b.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius * 0.5)
        b.physicsBody?.restitution        = 0.65
        b.physicsBody?.friction           = 0.04
        b.physicsBody?.density            = 1.0
        b.physicsBody?.linearDamping      = 0.06
        b.physicsBody?.categoryBitMask    = PhysicsCategory.ball
        b.physicsBody?.collisionBitMask   = PhysicsCategory.peg | PhysicsCategory.wall
        b.physicsBody?.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
        b.fillColor   = PowerupKind.tiny.color
        b.strokeColor = PowerupKind.tiny.color
        ballGlow?.strokeColor = PowerupKind.tiny.color.withAlphaComponent(0.6)
    }

    private func expireEffect(_ kind: PowerupKind) {
        guard let b = ball else { return }
        switch kind {
        case .ghost:
            b.physicsBody?.collisionBitMask   = PhysicsCategory.peg | PhysicsCategory.wall
            b.physicsBody?.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
            b.alpha = 1.0
        case .heavy:
            b.physicsBody?.density = 1.0
            b.physicsBody?.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
        case .tiny:
            b.run(SKAction.scale(to: 1.0, duration: 0.2))
            b.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
            b.physicsBody?.restitution        = 0.55
            b.physicsBody?.friction           = 0.05
            b.physicsBody?.density            = 1.0
            b.physicsBody?.linearDamping      = 0.08
            b.physicsBody?.categoryBitMask    = PhysicsCategory.ball
            b.physicsBody?.collisionBitMask   = PhysicsCategory.peg | PhysicsCategory.wall
            b.physicsBody?.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.powerUp
        case .magnet, .lightning:
            break
        }
        restoreBallAppearance()
    }

    private func restoreBallAppearance() {
        ball?.fillColor   = TempleTheme.ballNormal
        ball?.strokeColor = TempleTheme.ballNormal.withAlphaComponent(0.5)
        ballGlow?.strokeColor = TempleTheme.ballNormal.withAlphaComponent(0.3)
    }

    // MARK: - Powerup badge HUD

    private func showPowerupBadge(kind: PowerupKind) {
        powerupBadge.strokeColor = kind.color
        powerupEmoji.text = kind.emoji
        powerupTimer.fontColor = kind.color
        powerupBarFill.fillColor = kind.color
        powerupBadge.removeAllActions()
        powerupBadge.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func updatePowerupBadge(_ eff: ActiveEffect) {
        let secs = Int(ceil(eff.remaining))
        powerupTimer.text = "\(eff.kind.label)  \(secs)s"
        let frac = max(0, CGFloat(eff.remaining / eff.kind.duration))
        let fillRect = CGRect(x: -50, y: -2, width: frac * 100, height: 4)
        powerupBarFill.path = CGPath(roundedRect: fillRect, cornerWidth:2, cornerHeight:2, transform:nil)
        if eff.remaining < 1.0 {
            powerupBadge.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to:0.3, duration:0.12),
                SKAction.fadeAlpha(to:1.0, duration:0.12)
            ])))
        }
    }

    private func hidePowerupBadge() {
        powerupBadge.removeAllActions()
        powerupBadge.run(SKAction.fadeOut(withDuration: 0.3))
    }

    // MARK: - Result

    private func showResult(won: Bool) {
        motionManager.stopAccelerometerUpdates()
        ball?.physicsBody?.velocity  = .zero
        ball?.physicsBody?.isDynamic = false

        let goalY = -boardH/2 + 40
        cam.run(SKAction.moveTo(y: max(-boardH/2+H/2, goalY), duration: 0.8))

        if won {
            for _ in 0..<30 {
                let spark = SKShapeNode(circleOfRadius: CGFloat.random(in:3...7))
                spark.fillColor   = [UIColor.yellow,.cyan,.green,.white,
                                     PowerupKind.lightning.color].randomElement()!
                spark.strokeColor = .clear; spark.zPosition = 30
                spark.position    = CGPoint(x:0, y:-boardH/2+40)
                worldNode.addChild(spark)
                let a = CGFloat.random(in:0...(2 * .pi))
                let s = CGFloat.random(in:80...260)
                spark.run(SKAction.sequence([
                    SKAction.group([SKAction.moveBy(x:cos(a)*s, y:sin(a)*s, duration:0.8),
                                    SKAction.fadeOut(withDuration:0.8)]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        let overlay = SKShapeNode(rectOf: CGSize(width:260, height:150), cornerRadius:16)
        overlay.fillColor   = UIColor(red:0.04,green:0.04,blue:0.12,alpha:0.97)
        overlay.strokeColor = won ? TempleTheme.gold : UIColor(red:0.7,green:0.2,blue:0.1,alpha:1)
        overlay.lineWidth   = 2; overlay.zPosition = 120
        cam.addChild(overlay)

        let t = SKLabelNode(fontNamed:"AvenirNext-Bold")
        t.text = won ? "★  Goal reached!" : "Missed!"
        t.fontSize = 22
        t.fontColor = won ? TempleTheme.gold : UIColor(red:1,green:0.4,blue:0.2,alpha:1)
        t.verticalAlignmentMode = .center; t.position = CGPoint(x:0, y:38)
        overlay.addChild(t)

        let sub = SKLabelNode(fontNamed:"AvenirNext-Regular")
        sub.text = won ? "2000m of pegs conquered" : "2000m of pegs, try again"
        sub.fontSize = 13; sub.fontColor = UIColor(white:0.6,alpha:1)
        sub.verticalAlignmentMode = .center; sub.position = CGPoint(x:0, y:10)
        overlay.addChild(sub)

        let tip = SKLabelNode(fontNamed:"AvenirNext-Regular")
        tip.text = won ? "You collected powerups on the way!" : "Find powerups on the way down"
        tip.fontSize = 10; tip.fontColor = UIColor(white:0.4,alpha:1)
        tip.verticalAlignmentMode = .center; tip.position = CGPoint(x:0, y:-10)
        overlay.addChild(tip)

        let retry = SKLabelNode(fontNamed:"AvenirNext-Bold")
        retry.text = "↺  Try Again"; retry.fontSize = 15
        retry.fontColor = TempleTheme.gold.withAlphaComponent(0.9)
        retry.verticalAlignmentMode = .center; retry.position = CGPoint(x:0, y:-38)
        retry.name = "retry"; overlay.addChild(retry)

        overlay.setScale(0.05)
        overlay.run(SKAction.sequence([
            SKAction.scale(to:1.05, duration:0.22),
            SKAction.scale(to:1.0,  duration:0.08)
        ]))
    }

    private func restartScene() {
        let scene = MegaPlinkoScene(size: size)
        scene.anchorPoint = CGPoint(x:0.5, y:0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration:0.3))
    }

    private func goBack() {
        let scene = ExperimentsMenuScene(size: size)
        scene.anchorPoint = CGPoint(x:0.5, y:0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration:0.3))
    }
}

// MARK: - Seeded RNG

private struct SeededRandom2 {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 1 }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
}
