import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = TempleTheme.background
        setupDecor()
        setupTitle()
        setupButtons()
    }

    // MARK: - Decorative stone pegs in background
    private func setupDecor() {
        let positions: [(CGFloat, CGFloat)] = [
            (-0.35, 0.2), (0.35, 0.2), (-0.2, 0.0), (0.2, 0.0),
            (-0.35, -0.2), (0.35, -0.2), (0.0, 0.1), (-0.15, -0.1),
            (0.15, -0.1), (0.0, -0.3)
        ]
        for (xf, yf) in positions {
            let peg = SKShapeNode(circleOfRadius: 10)
            peg.fillColor   = TempleTheme.pegNormal.withAlphaComponent(0.35)
            peg.strokeColor = TempleTheme.pegNormalStroke.withAlphaComponent(0.2)
            peg.lineWidth   = 1
            peg.position    = CGPoint(x: xf * size.width, y: yf * size.height)
            addChild(peg)
        }

        // Torch-like side accents
        for xSide: CGFloat in [-1, 1] {
            let torch = SKShapeNode(rectOf: CGSize(width: 8, height: 30), cornerRadius: 3)
            torch.fillColor   = UIColor(red: 0.28, green: 0.20, blue: 0.12, alpha: 1)
            torch.strokeColor = .clear
            torch.position    = CGPoint(x: xSide * (size.width / 2 - 24), y: size.height * 0.1)
            addChild(torch)
            let flame = SKShapeNode(circleOfRadius: 10)
            flame.fillColor   = TempleTheme.torchOrange.withAlphaComponent(0.7)
            flame.strokeColor = .clear
            flame.position    = CGPoint(x: xSide * (size.width / 2 - 24), y: size.height * 0.1 + 22)
            addChild(flame)
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.18),
                SKAction.fadeAlpha(to: 0.9, duration: 0.22)
            ])
            flame.run(SKAction.repeatForever(flicker))
        }
    }

    private func setupTitle() {
        // Decorative line
        for dy: CGFloat in [-1, 1] {
            let _ = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -120, y: 0))
            path.addLine(to: CGPoint(x: 120, y: 0))
            let n = SKShapeNode(path: path)
            n.strokeColor = TempleTheme.gold.withAlphaComponent(0.4)
            n.lineWidth   = 1
            n.position    = CGPoint(x: 0, y: size.height * 0.22 + dy * 38)
            addChild(n)
        }

        let title = SKLabelNode(fontNamed: TempleTheme.titleFont)
        title.text      = "BLINKO"
        title.fontSize   = 52
        title.fontColor  = TempleTheme.gold
        title.position   = CGPoint(x: 0, y: size.height * 0.22)
        addChild(title)

        // Subtle glow
        let glow = SKLabelNode(fontNamed: TempleTheme.titleFont)
        glow.text      = "BLINKO"
        glow.fontSize   = 52
        glow.fontColor  = TempleTheme.torchOrange.withAlphaComponent(0.15)
        glow.position   = CGPoint(x: 2, y: size.height * 0.22 - 2)
        addChild(glow)

        let sub = SKLabelNode(fontNamed: TempleTheme.smallFont)
        sub.text      = "Temple of Plinko"
        sub.fontSize   = 16
        sub.fontColor  = TempleTheme.dimText
        sub.position   = CGPoint(x: 0, y: size.height * 0.22 - 44)
        addChild(sub)
    }

    private func setupButtons() {
        makeButton(text: "▶  PLAY", name: "play",
                   position: CGPoint(x: 0, y: -size.height * 0.05),
                   primary: true)
        makeButton(text: "☰  LEVELS", name: "levels",
                   position: CGPoint(x: 0, y: -size.height * 0.05 - 68),
                   primary: false)
        makeButton(text: "⚗️  LAB", name: "lab",
                   position: CGPoint(x: 0, y: -size.height * 0.05 - 136),
                   primary: false)

        let version = SKLabelNode(fontNamed: TempleTheme.smallFont)
        version.text     = "200 Levels  ·  5 Ball Types"
        version.fontSize  = 11
        version.fontColor = TempleTheme.dimText.withAlphaComponent(0.6)
        version.position  = CGPoint(x: 0, y: -size.height * 0.42)
        addChild(version)
    }

    @discardableResult
    private func makeButton(text: String, name: String, position: CGPoint, primary: Bool) -> SKNode {
        let node = SKNode()
        node.name     = name
        node.position = position

        let w: CGFloat = 200, h: CGFloat = 52
        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 12)
        bg.fillColor   = primary
            ? UIColor(red: 0.55, green: 0.38, blue: 0.08, alpha: 1)
            : UIColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1)
        bg.strokeColor = primary ? TempleTheme.gold : TempleTheme.dimText.withAlphaComponent(0.5)
        bg.lineWidth   = primary ? 2 : 1
        node.addChild(bg)

        let lbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        lbl.text     = text
        lbl.fontSize  = primary ? 20 : 17
        lbl.fontColor = primary ? TempleTheme.brightText : TempleTheme.dimText
        lbl.verticalAlignmentMode = .center
        node.addChild(lbl)

        addChild(node)
        return node
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let hit = nodes(at: loc).compactMap { $0.name ?? $0.parent?.name }.first

        switch hit {
        case "play":
            let scene = GameScene(size: size)
            scene.scaleMode = .resizeFill
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
        case "levels":
            let scene = LevelSelectScene(size: size)
            scene.scaleMode = .resizeFill
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
        case "lab":
            let scene = ExperimentsMenuScene(size: size)
            scene.scaleMode = .resizeFill
            scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.3))
        default:
            break
        }
    }
}
