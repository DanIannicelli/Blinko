import SpriteKit

class WorldBallSelectScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)
        setupStars()
        setupTitle()
        setupGrid()
    }

    private func setupStars() {
        for _ in 0..<100 {
            let s = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.4...1.4))
            s.fillColor   = .white.withAlphaComponent(CGFloat.random(in: 0.2...0.7))
            s.strokeColor = .clear
            s.position    = CGPoint(x: CGFloat.random(in: -size.width/2...size.width/2),
                                    y: CGFloat.random(in: -size.height/2...size.height/2))
            s.zPosition   = -10
            addChild(s)
        }
    }

    private func setupTitle() {
        let t = SKLabelNode(fontNamed: "AvenirNext-Bold")
        t.text = "🪐  WORLD BALL"
        t.fontSize = 24; t.fontColor = UIColor(red:0.7,green:0.9,blue:0.7,alpha:1)
        t.position = CGPoint(x:0, y: size.height/2 - 55)
        addChild(t)

        let s = SKLabelNode(fontNamed: "AvenirNext-Regular")
        s.text = "Reach the flag on each world"
        s.fontSize = 12; s.fontColor = UIColor(white:0.4,alpha:1)
        s.position = CGPoint(x:0, y: size.height/2 - 78)
        addChild(s)

        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text = "← Lab"; back.fontSize = 14
        back.fontColor = UIColor(white:0.4,alpha:1)
        back.position  = CGPoint(x:0, y: -size.height/2 + 30)
        back.name = "back"
        addChild(back)
    }

    private func setupGrid() {
        let cols:    Int     = 5
        let btnW:    CGFloat = 56
        let gap:     CGFloat = 10
        let startX   = -CGFloat(cols) * (btnW + gap) / 2 + (btnW + gap) / 2
        let startY   = size.height/2 - 115

        for cfg in WorldBallLevels.all {
            let i   = cfg.number - 1
            let col = i % cols
            let row = i / cols
            let btn = makeButton(cfg: cfg)
            btn.position = CGPoint(x: startX + CGFloat(col) * (btnW + gap),
                                   y: startY  - CGFloat(row) * (btnW + gap))
            addChild(btn)
        }
    }

    private func makeButton(cfg: WorldBallLevelConfig) -> SKNode {
        let node = SKNode()
        node.name = "level_\(cfg.number)"

        let bg = SKShapeNode(rectOf: CGSize(width: 56, height: 56), cornerRadius: 8)
        bg.fillColor   = UIColor(white:1,alpha:0.04)
        bg.strokeColor = UIColor(red:0.4,green:0.9,blue:0.5,alpha:0.4)
        bg.lineWidth   = 1.5
        node.addChild(bg)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Regular")
        icon.text = "🚩"; icon.fontSize = 12
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x:0, y:10)
        node.addChild(icon)

        let num = SKLabelNode(fontNamed: "AvenirNext-Bold")
        num.text = "\(cfg.number)"; num.fontSize = 16
        num.fontColor = .white
        num.verticalAlignmentMode = .center
        num.position = CGPoint(x:0, y:-10)
        node.addChild(num)

        return node
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let loc = touches.first?.location(in: self) else { return }
        let name = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first

        if name == "back" {
            go(ExperimentsMenuScene(size: size)); return
        }

        guard let name,
              name.hasPrefix("level_"),
              let num = Int(name.dropFirst(6)),
              let cfg = WorldBallLevels.all.first(where: { $0.number == num })
        else { return }

        let scene = WorldBallScene(size: size)
        scene.levelConfig = cfg
        go(scene)
    }

    private func go(_ scene: SKScene) {
        scene.anchorPoint = CGPoint(x:0.5,y:0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.35))
    }
}
