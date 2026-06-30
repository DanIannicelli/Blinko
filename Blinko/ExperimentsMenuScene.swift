import SpriteKit

class ExperimentsMenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1)
        setupStars()
        setupUI()
    }

    private func setupStars() {
        for _ in 0..<120 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.8))
            star.fillColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(
                x: CGFloat.random(in: -size.width/2...size.width/2),
                y: CGFloat.random(in: -size.height/2...size.height/2)
            )
            addChild(star)
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.1...0.4), duration: Double.random(in: 0.8...2.0)),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: Double.random(in: 0.8...2.0))
            ])
            star.run(SKAction.repeatForever(twinkle))
        }
    }

    private func setupUI() {
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "⚗️  LAB"
        title.fontSize = 28
        title.fontColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1)
        title.position = CGPoint(x: 0, y: size.height * 0.28)
        addChild(title)

        let sub = SKLabelNode(fontNamed: "AvenirNext-Regular")
        sub.text = "Experimental Concepts"
        sub.fontSize = 13
        sub.fontColor = UIColor(white: 0.5, alpha: 1)
        sub.position = CGPoint(x: 0, y: size.height * 0.28 - 32)
        addChild(sub)

        makeCard(
            name:    "gravityWell",
            title:   "🌑  Gravity Well",
            detail:  "Fling a planet into orbit\naround a gravitational singularity",
            yFrac:   0.05
        )
        makeCard(
            name:    "worldBall",
            title:   "🪐  World Ball",
            detail:  "Roll between tiny worlds,\neach with its own gravity",
            yFrac:   -0.22
        )

        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text = "← Back to Menu"
        back.fontSize = 14
        back.fontColor = UIColor(white: 0.5, alpha: 1)
        back.position = CGPoint(x: 0, y: -size.height * 0.44)
        back.name = "back"
        addChild(back)
    }

    private func makeCard(name: String, title: String, detail: String, yFrac: CGFloat) {
        let node = SKNode()
        node.name = name
        node.position = CGPoint(x: 0, y: size.height * yFrac)

        let bg = SKShapeNode(rectOf: CGSize(width: min(size.width - 48, 320), height: 110), cornerRadius: 14)
        bg.fillColor   = UIColor(white: 1, alpha: 0.05)
        bg.strokeColor = UIColor(white: 1, alpha: 0.15)
        bg.lineWidth   = 1
        node.addChild(bg)

        let t = SKLabelNode(fontNamed: "AvenirNext-Bold")
        t.text = title
        t.fontSize = 19
        t.fontColor = .white
        t.verticalAlignmentMode = .center
        t.position = CGPoint(x: 0, y: 22)
        node.addChild(t)

        let lines = detail.components(separatedBy: "\n")
        for (i, line) in lines.enumerated() {
            let d = SKLabelNode(fontNamed: "AvenirNext-Regular")
            d.text = line
            d.fontSize = 12
            d.fontColor = UIColor(white: 0.6, alpha: 1)
            d.verticalAlignmentMode = .center
            d.position = CGPoint(x: 0, y: -10 - CGFloat(i) * 17)
            node.addChild(d)
        }

        addChild(node)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let hit = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first

        func go(_ scene: SKScene) {
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            scene.scaleMode = .resizeFill
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
        }

        switch hit {
        case "gravityWell":
            go(GravityWellSelectScene(size: size))
        case "worldBall":
            go(WorldBallSelectScene(size: size))
        case "back":
            let menu = MenuScene(size: size)
            menu.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            menu.scaleMode = .resizeFill
            view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.3))
        default:
            break
        }
    }
}
