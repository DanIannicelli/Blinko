import SpriteKit

class MegaPlinkoScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Constants
    private let boardScale: CGFloat = 20          // 20x taller than screen
    private var boardH:     CGFloat { size.height * boardScale }
    private var W:          CGFloat { size.width  }
    private var H:          CGFloat { size.height }

    // MARK: - Nodes
    private var cam:        SKCameraNode!
    private var worldNode   = SKNode()
    private var ball:       SKShapeNode?
    private var goalNode:   SKShapeNode!

    // MARK: - State
    private var dropped       = false
    private var levelComplete = false
    private var aimX:  CGFloat = 0
    private var aimIndicator: SKShapeNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)

        physicsWorld.gravity         = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        cam = SKCameraNode()
        camera = cam
        addChild(cam)

        addChild(worldNode)
        buildBoard()
        setupHUD()
        setupAim()

        // Camera starts at top of board
        cam.position = CGPoint(x: 0, y: boardH / 2 - H / 2)
    }

    // MARK: - Board

    private func buildBoard() {
        buildBackground()
        buildWalls()
        buildPegs()
        buildGoal()
    }

    private func buildBackground() {
        // Subtle vertical gradient via stacked rects
        let segCount = 40
        let segH = boardH / CGFloat(segCount)
        for i in 0..<segCount {
            let t  = CGFloat(i) / CGFloat(segCount)
            let bg = SKShapeNode(rectOf: CGSize(width: W, height: segH))
            let r  = 0.04 + t * 0.08
            let g  = 0.03 + t * 0.04
            let b  = 0.08 + t * 0.12
            bg.fillColor   = UIColor(red: r, green: g, blue: b, alpha: 1)
            bg.strokeColor = .clear
            bg.position    = CGPoint(x: 0, y: boardH / 2 - segH * (CGFloat(i) + 0.5))
            worldNode.addChild(bg)
        }

        // Rock grid — same style as main game but taller
        addRockGrid()

        // Waterfall streaks
        addWaterfalls()

        // Depth markers every screen-height
        for i in 1..<Int(boardScale) {
            let y   = boardH / 2 - H * CGFloat(i)
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
        var rng   = SeededRandom2(seed: 77)
        let cols  = 5; let rows = 80
        let cellW = W / CGFloat(cols)
        let cellH = boardH / CGFloat(rows)
        let jx = cellW * 0.25; let jy = cellH * 0.25

        var pts = [[CGPoint]]()
        for row in 0...rows {
            var rowPts = [CGPoint]()
            for col in 0...cols {
                let base = CGPoint(x: -W/2 + CGFloat(col)*cellW,
                                   y: boardH/2 - CGFloat(row)*cellH)
                let ox = (col == 0 || col == cols) ? 0 : rng.next()*jx*2 - jx
                let oy = (row == 0 || row == rows) ? 0 : rng.next()*jy*2 - jy
                rowPts.append(CGPoint(x: base.x + ox, y: base.y + oy))
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
                let bright = 0.5 + rng.next() * 0.8
                node.fillColor   = UIColor(red:0.14,green:0.10,blue:0.06,alpha:0.45 * bright)
                node.strokeColor = UIColor(red:0.10,green:0.08,blue:0.05,alpha:0.7)
                node.lineWidth   = 0.8
                node.zPosition   = -10
                worldNode.addChild(node)

                // Cracks
                if rng.next() < 0.25 {
                    let cx = (bl.x+br.x+tr.x+tl.x)/4; let cy = (bl.y+br.y+tr.y+tl.y)/4
                    let cp = CGMutablePath()
                    cp.move(to: CGPoint(x: cx+rng.next()*cellW*0.3-cellW*0.15,
                                        y: cy+rng.next()*cellH*0.3-cellH*0.15))
                    cp.addLine(to: CGPoint(x: cx+rng.next()*cellW*0.3-cellW*0.15,
                                            y: cy+rng.next()*cellH*0.3-cellH*0.15))
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
            let x     = (rng.next() * W * 0.9) - W * 0.45
            let sH    = boardH * (0.25 + rng.next() * 0.5)
            let startY = boardH / 2 - rng.next() * boardH * 0.3
            let wid   = 3 + rng.next() * 9
            let alpha = 0.05 + rng.next() * 0.12
            let spd   = 2.0 + rng.next() * 5.0

            let streak = SKShapeNode(rectOf: CGSize(width: wid, height: sH), cornerRadius: wid/2)
            streak.fillColor   = UIColor(red:0.5,green:0.75,blue:1.0,alpha:alpha)
            streak.strokeColor = .clear; streak.zPosition = -8
            streak.position    = CGPoint(x: x, y: startY)
            worldNode.addChild(streak)

            let fall  = SKAction.moveBy(x: 0, y: -sH * 1.5, duration: spd)
            let reset = SKAction.moveBy(x: 0, y: sH * 1.5, duration: 0)
            streak.run(SKAction.repeatForever(SKAction.sequence([fall, reset])))
            streak.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: alpha * 0.3, duration: 1.2),
                SKAction.fadeAlpha(to: alpha,        duration: 1.2)
            ])))
        }
    }

    private func buildWalls() {
        let top    = boardH / 2
        let bottom = -boardH / 2
        let edges: [(CGPoint, CGPoint)] = [
            (CGPoint(x: -W/2, y: bottom), CGPoint(x: -W/2, y: top)),
            (CGPoint(x:  W/2, y: bottom), CGPoint(x:  W/2, y: top)),
            (CGPoint(x: -W/2, y: bottom), CGPoint(x:  W/2, y: bottom))
        ]
        for (s, e) in edges {
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
        // Dense peg grid across full board height
        let pegRows    = 140
        let pegCols    = 7
        let rowSpacing = boardH / CGFloat(pegRows + 1)
        let colSpacing = W / CGFloat(pegCols + 1)
        let pegR: CGFloat = 6

        for row in 1...pegRows {
            let y      = boardH / 2 - rowSpacing * CGFloat(row)
            let offset = (row % 2 == 0) ? colSpacing / 2 : 0
            for col in 1...pegCols {
                let x = -W/2 + colSpacing * CGFloat(col) + offset
                if abs(x) > W/2 - pegR { continue }

                // Alternate peg styles for visual depth
                let isGold = (row + col) % 12 == 0
                let peg = SKShapeNode(circleOfRadius: pegR)
                peg.fillColor   = isGold
                    ? UIColor(red:0.72,green:0.55,blue:0.12,alpha:1)
                    : UIColor(red:0.32,green:0.26,blue:0.18,alpha:1)
                peg.strokeColor = isGold
                    ? UIColor(red:1.0,green:0.85,blue:0.3,alpha:0.7)
                    : UIColor(red:0.48,green:0.38,blue:0.22,alpha:0.6)
                peg.lineWidth  = isGold ? 2 : 1
                peg.position   = CGPoint(x: x, y: y)
                peg.zPosition  = 5

                // Glowing ring on gold pegs
                if isGold {
                    let glow = SKShapeNode(circleOfRadius: pegR + 5)
                    glow.fillColor   = .clear
                    glow.strokeColor = UIColor(red:1,green:0.85,blue:0.3,alpha:0.25)
                    glow.lineWidth   = 3
                    glow.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to:0.05, duration:0.7),
                        SKAction.fadeAlpha(to:0.5,  duration:0.7)
                    ])))
                    peg.addChild(glow)
                }

                let body = SKPhysicsBody(circleOfRadius: pegR)
                body.isDynamic          = false
                body.restitution        = 0.5
                body.friction           = 0.2
                body.categoryBitMask    = PhysicsCategory.peg
                body.collisionBitMask   = PhysicsCategory.ball
                body.contactTestBitMask = PhysicsCategory.ball
                peg.physicsBody = body
                worldNode.addChild(peg)
            }
        }
    }

    private func buildGoal() {
        let goalW: CGFloat = W * 0.35
        let goalY = -boardH / 2 + 40

        // Glowing floor platform
        let base = SKShapeNode(rectOf: CGSize(width: goalW, height: 18), cornerRadius: 9)
        base.fillColor   = UIColor(red:0.9,green:0.75,blue:0.1,alpha:1)
        base.strokeColor = UIColor(red:1,green:0.95,blue:0.4,alpha:0.9)
        base.lineWidth   = 2.5; base.zPosition = 10
        base.position    = CGPoint(x: 0, y: goalY)
        worldNode.addChild(base)

        // Pulsing outer glow
        for r in [CGFloat(30), 55, 80] {
            let ring = SKShapeNode(circleOfRadius: r)
            ring.fillColor   = .clear
            ring.strokeColor = UIColor(red:1,green:0.9,blue:0.2,alpha:0.18)
            ring.lineWidth   = 6; ring.zPosition = 9
            ring.position    = CGPoint(x: 0, y: goalY + 4)
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
        lbl.position = CGPoint(x: 0, y: goalY + 30); lbl.zPosition = 11
        worldNode.addChild(lbl)

        // Physics sensor on goal
        goalNode = base
        let body = SKPhysicsBody(rectangleOf: CGSize(width: goalW, height: 18))
        body.isDynamic          = false
        body.categoryBitMask    = PhysicsCategory.bucket
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = 0
        base.physicsBody = body
    }

    // MARK: - HUD & Aim

    private func setupHUD() {
        let depth = SKLabelNode(fontNamed: "AvenirNext-Bold")
        depth.text      = "Mega Plinko"
        depth.fontSize  = 16
        depth.fontColor = TempleTheme.gold
        depth.position  = CGPoint(x: -W/2 + 12, y: H/2 - 50)
        depth.horizontalAlignmentMode = .left
        depth.zPosition = 100
        cam.addChild(depth)

        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text      = "☰"; back.fontSize = 22
        back.fontColor = UIColor(white:0.5,alpha:1)
        back.horizontalAlignmentMode = .right
        back.position  = CGPoint(x: W/2 - 16, y: H/2 - 52)
        back.zPosition = 100; back.name = "back"
        cam.addChild(back)

        let tip = SKLabelNode(fontNamed: "AvenirNext-Regular")
        tip.text      = "Tap to drop  ·  reach the ★ goal"
        tip.fontSize  = 11
        tip.fontColor = UIColor(white:0.4,alpha:1)
        tip.position  = CGPoint(x: 0, y: -H/2 + 20)
        tip.zPosition = 100
        cam.addChild(tip)

        // Depth meter on right edge
        let meterBg = SKShapeNode(rectOf: CGSize(width: 6, height: H * 0.6), cornerRadius: 3)
        meterBg.fillColor   = UIColor(white:1,alpha:0.06)
        meterBg.strokeColor = UIColor(white:1,alpha:0.12)
        meterBg.lineWidth   = 1
        meterBg.position    = CGPoint(x: W/2 - 14, y: 0)
        meterBg.zPosition   = 100
        cam.addChild(meterBg)
    }

    private func setupAim() {
        aimIndicator = SKShapeNode(circleOfRadius: 14)
        aimIndicator.fillColor   = TempleTheme.torchOrange.withAlphaComponent(0.3)
        aimIndicator.strokeColor = TempleTheme.torchOrange.withAlphaComponent(0.9)
        aimIndicator.lineWidth   = 2; aimIndicator.zPosition = 50
        aimIndicator.position    = CGPoint(x: 0, y: boardH/2 - 80)
        worldNode.addChild(aimIndicator)
        aimIndicator.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to:1.2, duration:0.5),
            SKAction.scale(to:0.9, duration:0.5)
        ])))
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let hit = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first
        if hit == "back" { goBack(); return }
        if hit == "retry" { restartScene(); return }

        if !dropped {
            let worldLoc = cam.convert(loc, to: worldNode)
            aimX = max(-W/2 + 20, min(W/2 - 20, worldLoc.x))
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

        let b = SKShapeNode(circleOfRadius: 14)
        b.fillColor   = TempleTheme.ballNormal
        b.strokeColor = TempleTheme.ballNormal.withAlphaComponent(0.5)
        b.lineWidth   = 2; b.zPosition = 20
        b.position    = CGPoint(x: aimX, y: boardH/2 - 60)
        worldNode.addChild(b)

        // Trail sparkle
        let trail = SKShapeNode(circleOfRadius: 5)
        trail.fillColor   = TempleTheme.torchOrange.withAlphaComponent(0.5)
        trail.strokeColor = .clear
        b.addChild(trail)
        trail.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to:1.5, duration:0.1),
            SKAction.scale(to:0.5, duration:0.1)
        ])))

        let body = SKPhysicsBody(circleOfRadius: 14)
        body.restitution        = 0.55
        body.friction           = 0.05
        body.density            = 1.0
        body.linearDamping      = 0.08
        body.categoryBitMask    = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.peg | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.bucket | PhysicsCategory.peg
        b.physicsBody = body
        body.applyImpulse(CGVector(dx: CGFloat.random(in: -2...2), dy: 0))
        ball = b
    }

    // MARK: - Update (camera follows ball)

    override func update(_ currentTime: TimeInterval) {
        guard let b = ball else { return }
        let ballWorldY = b.position.y
        // Camera follows ball, clamped to board bounds
        let minY = -boardH/2 + H/2
        let maxY =  boardH/2 - H/2
        let targetY = max(minY, min(maxY, ballWorldY))
        cam.position.y += (targetY - cam.position.y) * 0.10

        // Check if ball fell off floor without hitting goal
        if ballWorldY < -boardH/2 - 50 && !levelComplete {
            showResult(won: false)
        }
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let combined = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        guard combined == (PhysicsCategory.ball | PhysicsCategory.bucket) else { return }
        guard !levelComplete else { return }
        levelComplete = true
        showResult(won: true)
    }

    // MARK: - Result

    private func showResult(won: Bool) {
        ball?.physicsBody?.velocity = .zero
        ball?.physicsBody?.isDynamic = false

        // Camera snap to goal area
        let goalY = -boardH/2 + 40
        cam.run(SKAction.moveTo(y: max(-boardH/2 + H/2, goalY), duration: 0.8))

        if won {
            for _ in 0..<28 {
                let spark = SKShapeNode(circleOfRadius: CGFloat.random(in:3...7))
                spark.fillColor   = [UIColor.yellow,.cyan,.green,.white].randomElement()!
                spark.strokeColor = .clear
                spark.position    = CGPoint(x: 0, y: -boardH/2 + 40)
                spark.zPosition   = 30
                worldNode.addChild(spark)
                let a = CGFloat.random(in:0...(2 * .pi))
                let s = CGFloat.random(in:80...240)
                spark.run(SKAction.sequence([
                    SKAction.group([SKAction.moveBy(x:cos(a)*s,y:sin(a)*s,duration:0.7),
                                    SKAction.fadeOut(withDuration:0.7)]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        let overlay = SKShapeNode(rectOf: CGSize(width: 240, height: 140), cornerRadius: 14)
        overlay.fillColor   = UIColor(red:0.04,green:0.04,blue:0.12,alpha:0.96)
        overlay.strokeColor = won ? TempleTheme.gold : UIColor(red:0.7,green:0.2,blue:0.1,alpha:1)
        overlay.lineWidth   = 2; overlay.zPosition = 120
        cam.addChild(overlay)

        let t = SKLabelNode(fontNamed: "AvenirNext-Bold")
        t.text = won ? "★  Goal reached!" : "Missed!"
        t.fontSize = 20
        t.fontColor = won ? TempleTheme.gold : UIColor(red:1,green:0.4,blue:0.2,alpha:1)
        t.verticalAlignmentMode = .center; t.position = CGPoint(x:0,y:30)
        overlay.addChild(t)

        let sub = SKLabelNode(fontNamed:"AvenirNext-Regular")
        sub.text = won ? "20x depth conquered" : "2000m of pegs, try again"
        sub.fontSize = 12; sub.fontColor = UIColor(white:0.6,alpha:1)
        sub.verticalAlignmentMode = .center; sub.position = CGPoint(x:0,y:4)
        overlay.addChild(sub)

        let retry = SKLabelNode(fontNamed:"AvenirNext-Bold")
        retry.text = "↺  Try Again"; retry.fontSize = 14
        retry.fontColor = TempleTheme.gold.withAlphaComponent(0.8)
        retry.verticalAlignmentMode = .center; retry.position = CGPoint(x:0,y:-28)
        retry.name = "retry"; overlay.addChild(retry)

        overlay.setScale(0.05)
        overlay.run(SKAction.sequence([
            SKAction.scale(to:1.05, duration:0.2),
            SKAction.scale(to:1.0,  duration:0.08)
        ]))
    }

    private func restartScene() {
        let scene = MegaPlinkoScene(size: size)
        scene.anchorPoint = CGPoint(x:0.5,y:0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration:0.3))
    }

    private func goBack() {
        let scene = ExperimentsMenuScene(size: size)
        scene.anchorPoint = CGPoint(x:0.5,y:0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration:0.3))
    }
}

// Seeded RNG for reproducible board (private to this file)
private struct SeededRandom2 {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 1 }
    mutating func next() -> CGFloat {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return CGFloat(state & 0xFFFFFF) / CGFloat(0xFFFFFF)
    }
}
