import SpriteKit

class GravityWellSelectScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.01, green: 0.01, blue: 0.06, alpha: 1)
        setupStars()
        setupTitle()
        setupGrid()
        setupBack()
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
        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text     = "🌑  ORBITAL"
        title.fontSize  = 26
        title.fontColor = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1)
        title.position  = CGPoint(x: 0, y: size.height/2 - 55)
        addChild(title)

        // Section labels
        for (text, y) in [("— TRANSIT —", size.height/2 - 105),
                           ("— SURVIVAL —", size.height/2 - 105 - CGFloat(5) * 68)] {
            let lbl = SKLabelNode(fontNamed: "AvenirNext-Regular")
            lbl.text     = text
            lbl.fontSize  = 11
            lbl.fontColor = UIColor(white: 0.4, alpha: 1)
            lbl.position  = CGPoint(x: 0, y: y)
            addChild(lbl)
        }
    }

    private func setupGrid() {
        let cols:      Int     = 5
        let btnSize:   CGFloat = 50
        let gap:       CGFloat = 10
        let startX     = -CGFloat(cols) * (btnSize + gap) / 2 + (btnSize + gap) / 2

        let transitY:  CGFloat = size.height/2 - 140
        let survivalY: CGFloat = transitY - 5 * (btnSize + gap) - 50

        for cfg in GravityWellLevels.all {
            let localNum = ((cfg.number - 1) % 10)
            let col      = localNum % cols
            let row      = localNum / cols
            let baseY    = cfg.mode == .transit ? transitY : survivalY

            let x = startX + CGFloat(col) * (btnSize + gap)
            let y = baseY  - CGFloat(row) * (btnSize + gap)

            let btn = makeButton(cfg: cfg)
            btn.position = CGPoint(x: x, y: y)
            addChild(btn)
        }
    }

    private func makeButton(cfg: GravityWellLevelConfig) -> SKNode {
        let node = SKNode()
        node.name = "level_\(cfg.number)"

        let isTransit  = cfg.mode == .transit
        let accentColor: UIColor = isTransit
            ? UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
            : UIColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1)

        let bg = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 8)
        bg.fillColor   = UIColor(white: 1, alpha: 0.04)
        bg.strokeColor = accentColor.withAlphaComponent(0.5)
        bg.lineWidth   = 1.5
        node.addChild(bg)

        // Mode icon
        let icon = SKLabelNode(fontNamed: "AvenirNext-Regular")
        icon.text     = isTransit ? "→" : "⏱"
        icon.fontSize  = 11
        icon.fontColor = accentColor.withAlphaComponent(0.7)
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: 10)
        node.addChild(icon)

        let num = SKLabelNode(fontNamed: "AvenirNext-Bold")
        num.text     = "\(cfg.number)"
        num.fontSize  = 16
        num.fontColor = .white
        num.verticalAlignmentMode = .center
        num.position = CGPoint(x: 0, y: -8)
        node.addChild(num)

        return node
    }

    private func setupBack() {
        let back = SKLabelNode(fontNamed: "AvenirNext-Regular")
        back.text     = "← Lab"
        back.fontSize  = 14
        back.fontColor = UIColor(white: 0.4, alpha: 1)
        back.position  = CGPoint(x: 0, y: -size.height/2 + 30)
        back.name      = "back"
        addChild(back)
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
              let cfg = GravityWellLevels.all.first(where: { $0.number == num })
        else { return }

        let scene = GravityWellScene(size: size)
        scene.levelConfig = cfg
        go(scene)
    }

    private func go(_ scene: SKScene) {
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.scaleMode   = .resizeFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.35))
    }
}
