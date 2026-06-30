import SpriteKit

struct Effects {

    // MARK: - Lightning strike

    static func lightning(in scene: SKScene, completion: @escaping () -> Void) {
        let w = scene.size.width
        let h = scene.size.height
        let center = CGPoint.zero

        // Screen flash
        let flash = SKShapeNode(rectOf: CGSize(width: w, height: h))
        flash.fillColor = UIColor(red: 1, green: 0.95, blue: 0.4, alpha: 0.55)
        flash.strokeColor = .clear
        flash.zPosition = 90
        flash.position = center
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.55, duration: 0.05),
            SKAction.fadeAlpha(to: 0.0,  duration: 0.30),
            SKAction.removeFromParent()
        ]))

        // Radial bolts
        let boltCount = 16
        for i in 0..<boltCount {
            let angle = CGFloat(i) * (.pi * 2 / CGFloat(boltCount))
            let length = CGFloat.random(in: w * 0.3 ... w * 0.6)
            let bolt = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: center)

            // Jagged bolt segments
            var cur = center
            let steps = 5
            for s in 1...steps {
                let t = CGFloat(s) / CGFloat(steps)
                let base = CGPoint(x: cos(angle) * length * t, y: sin(angle) * length * t)
                let jitter = CGPoint(x: CGFloat.random(in: -15...15),
                                     y: CGFloat.random(in: -15...15))
                cur = s == steps
                    ? CGPoint(x: cos(angle) * length, y: sin(angle) * length)
                    : CGPoint(x: base.x + jitter.x, y: base.y + jitter.y)
                path.addLine(to: cur)
            }
            bolt.path = path
            bolt.strokeColor = UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.9)
            bolt.lineWidth = CGFloat.random(in: 1.5 ... 3.5)
            bolt.glowWidth = 4
            bolt.zPosition = 91
            bolt.position = center
            scene.addChild(bolt)

            let delay = SKAction.wait(forDuration: Double.random(in: 0...0.08))
            let fade  = SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.04),
                SKAction.wait(forDuration: Double.random(in: 0.1...0.4)),
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent()
            ])
            bolt.alpha = 0
            bolt.run(SKAction.sequence([delay, fade]))
        }

        // Second weaker flash
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let flash2 = SKShapeNode(rectOf: CGSize(width: w, height: h))
            flash2.fillColor = UIColor(red: 1, green: 0.95, blue: 0.4, alpha: 0.3)
            flash2.strokeColor = .clear
            flash2.zPosition = 90
            flash2.position = center
            scene.addChild(flash2)
            flash2.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ]))
        }

        // Callback after full effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: completion)
    }

    // MARK: - Bomb explosion

    static func bombExplosion(at point: CGPoint, in scene: SKScene, radius: CGFloat) {
        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: 1)
        ring.fillColor = .clear
        ring.strokeColor = UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.9)
        ring.lineWidth = 4
        ring.position = point
        ring.zPosition = 85
        scene.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: radius / 1, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35)
            ]),
            SKAction.removeFromParent()
        ]))

        // Inner flash
        let flash = SKShapeNode(circleOfRadius: radius * 0.5)
        flash.fillColor = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.7)
        flash.strokeColor = .clear
        flash.position = point
        flash.zPosition = 86
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.28),
            SKAction.removeFromParent()
        ]))

        // Debris sparks
        for _ in 0..<12 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            spark.fillColor = [TempleTheme.torchOrange, TempleTheme.gold,
                               UIColor(red: 1, green: 0.4, blue: 0.1, alpha: 1)].randomElement()!
            spark.strokeColor = .clear
            spark.position = point
            spark.zPosition = 87
            scene.addChild(spark)
            let angle  = CGFloat.random(in: 0 ... .pi * 2)
            let dist   = CGFloat.random(in: radius * 0.3 ... radius * 0.9)
            let move   = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.4)
            move.timingMode = .easeOut
            spark.run(SKAction.sequence([
                SKAction.group([move, SKAction.fadeOut(withDuration: 0.4)]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Floating score label

    static func floatingScore(_ pts: Int, at pos: CGPoint, in scene: SKScene) {
        let label = SKLabelNode(fontNamed: TempleTheme.titleFont)
        label.text = "+\(pts)"
        label.fontSize = pts >= 1000 ? 24 : 20
        label.fontColor = pts >= 1000 ? TempleTheme.gold : TempleTheme.brightText
        label.position = pos
        label.zPosition = 80
        scene.addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 65, duration: 0.9),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.4),
                    SKAction.fadeOut(withDuration: 0.5)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Peg hit spark

    static func pegSpark(at pos: CGPoint, in scene: SKScene) {
        for _ in 0..<5 {
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = TempleTheme.gold.withAlphaComponent(0.85)
            dot.strokeColor = .clear
            dot.position = pos
            dot.zPosition = 70
            scene.addChild(dot)
            let angle = CGFloat.random(in: 0 ... .pi * 2)
            let dist  = CGFloat.random(in: 8 ... 22)
            dot.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.25),
                    SKAction.fadeOut(withDuration: 0.25)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
