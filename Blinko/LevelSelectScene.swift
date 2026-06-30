import SpriteKit

class LevelSelectScene: SKScene {

    private let cols   = 5
    private let btnSize: CGFloat = 56
    private let gap:   CGFloat = 10
    private var scrollNode = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = TempleTheme.background
        setupBackground()
        setupTitle()
        setupGrid()
    }

    private func setupBackground() {
        // Subtle stone texture via dots
        for _ in 0..<60 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            dot.fillColor = UIColor(red: 0.15, green: 0.12, blue: 0.08,
                                    alpha: CGFloat.random(in: 0.3...0.7))
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat.random(in: -size.width/2 ... size.width/2),
                                   y: CGFloat.random(in: -size.height/2 ... size.height/2))
            addChild(dot)
        }
    }

    private func setupTitle() {
        let title = SKLabelNode(fontNamed: TempleTheme.titleFont)
        title.text      = "☥  SELECT LEVEL  ☥"
        title.fontSize   = 22
        title.fontColor  = TempleTheme.gold
        title.position   = CGPoint(x: 0, y: size.height / 2 - 55)
        title.zPosition  = 10
        addChild(title)

        let sub = SKLabelNode(fontNamed: TempleTheme.smallFont)
        sub.text      = "Tap a level to begin"
        sub.fontSize   = 12
        sub.fontColor  = TempleTheme.dimText
        sub.position   = CGPoint(x: 0, y: size.height / 2 - 78)
        sub.zPosition  = 10
        addChild(sub)
    }

    private func setupGrid() {
        addChild(scrollNode)
        let total      = LevelLoader.shared.totalCount
        let rows       = Int(ceil(Double(total) / Double(cols)))
        let totalH     = CGFloat(rows) * (btnSize + gap)
        let startX     = -CGFloat(cols) * (btnSize + gap) / 2 + btnSize / 2 + gap / 2
        let startY     = size.height / 2 - 100

        for i in 0..<total {
            let row = i / cols
            let col = i % cols
            let x   = startX + CGFloat(col) * (btnSize + gap)
            let y   = startY - CGFloat(row) * (btnSize + gap)

            let btn = makeLevelButton(number: i + 1)
            btn.position = CGPoint(x: x, y: y)
            scrollNode.addChild(btn)
        }
        _ = totalH
    }

    private func makeLevelButton(number: Int) -> SKNode {
        let node = SKNode()
        node.name = "level_\(number)"

        let bg = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 8)
        bg.fillColor   = UIColor(red: 0.12, green: 0.09, blue: 0.06, alpha: 1)
        bg.strokeColor = TempleTheme.pegNormalStroke
        bg.lineWidth   = 1.5
        node.addChild(bg)

        let numLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        numLbl.text     = "\(number)"
        numLbl.fontSize  = 18
        numLbl.fontColor = TempleTheme.brightText
        numLbl.verticalAlignmentMode = .center
        node.addChild(numLbl)

        // Milestone markers
        if number % 10 == 0 {
            bg.strokeColor = TempleTheme.gold
            bg.lineWidth   = 2
            numLbl.fontColor = TempleTheme.gold
        }
        if number <= 5 {
            bg.strokeColor = TempleTheme.pegNormal
        }

        return node
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc  = touch.location(in: scrollNode)
        let node = scrollNode.atPoint(loc)

        func findLevelNode(_ n: SKNode) -> SKNode? {
            if let name = n.name, name.hasPrefix("level_") { return n }
            if let name = n.parent?.name, name.hasPrefix("level_") { return n.parent }
            return nil
        }

        if let found = findLevelNode(node),
           let name  = found.name,
           let num   = Int(name.replacingOccurrences(of: "level_", with: "")) {
            launchLevel(num)
        }
    }

    private func launchLevel(_ number: Int) {
        let scene = GameScene(size: size)
        scene.scaleMode   = .resizeFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.levelNumber = number
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.35))
    }
}
