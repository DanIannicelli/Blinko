import SpriteKit

class HUD: SKNode {

    private var scoreLabel:  SKLabelNode!
    private var ballsLabel:  SKLabelNode!
    private var levelLabel:  SKLabelNode!
    private var targetLabel: SKLabelNode!
    private var selectorRow: SKNode!

    private(set) var score: Int = 0 {
        didSet { scoreLabel.text = "Score  \(score)" }
    }
    private(set) var ballsLeft: Int = 0 {
        didSet { ballsLabel.text = "\(ballsLeft) ●" }
    }

    var onBallTypeSelected: ((BallType, String?) -> Void)?

    // Ball-type selector state
    private var availableTypes: [(BallType, String?)] = []   // (type, keyColor)
    private var selectedIndex = 0
    private var typeButtons: [SKNode] = []

    var selectedBallType: BallType { availableTypes[selectedIndex].0 }
    var selectedKeyColor: String?  { availableTypes[selectedIndex].1 }

    // MARK: - Setup

    override init() {
        super.init()
        buildHUD()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildHUD() {
        // Background panel
        let panel = SKShapeNode(rectOf: CGSize(width: 420, height: 110), cornerRadius: 0)
        panel.fillColor   = TempleTheme.hudBG
        panel.strokeColor = UIColor(red: 0.25, green: 0.20, blue: 0.12, alpha: 0.8)
        panel.lineWidth   = 1
        panel.zPosition   = 0
        addChild(panel)

        // Gold top border line
        let border = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -210, y: -28))
        path.addLine(to: CGPoint(x: 210, y: -28))
        let b = SKShapeNode(path: path)
        b.strokeColor = TempleTheme.gold.withAlphaComponent(0.4)
        b.lineWidth = 1
        b.zPosition = 1
        addChild(b)
        _ = border

        levelLabel = makeLabel(font: TempleTheme.smallFont, size: 12, color: TempleTheme.gold)
        levelLabel.position = CGPoint(x: 0, y: 17)
        levelLabel.zPosition = 1
        addChild(levelLabel)

        scoreLabel = makeLabel(font: TempleTheme.bodyFont, size: 17, color: TempleTheme.brightText)
        scoreLabel.position = CGPoint(x: -75, y: -2)
        scoreLabel.zPosition = 1
        addChild(scoreLabel)

        ballsLabel = makeLabel(font: TempleTheme.bodyFont, size: 17, color: TempleTheme.torchOrange)
        ballsLabel.position = CGPoint(x: 75, y: -2)
        ballsLabel.zPosition = 1
        addChild(ballsLabel)

        targetLabel = makeLabel(font: TempleTheme.smallFont, size: 11, color: TempleTheme.dimText)
        targetLabel.position = CGPoint(x: 0, y: -20)
        targetLabel.zPosition = 1
        addChild(targetLabel)

        selectorRow = SKNode()
        selectorRow.position = CGPoint(x: 0, y: -52)
        selectorRow.zPosition = 2
        addChild(selectorRow)
    }

    // MARK: - Configure

    func configure(level: Int, title: String, balls: Int, target: Int,
                   ballTypes: [(BallType, String?)]) {
        levelLabel.text  = "Level \(level)  ·  \(title)"
        targetLabel.text = "Target  \(target)"
        ballsLeft = balls
        score     = 0
        buildSelector(types: ballTypes)
    }

    // MARK: - Ball type selector

    private var descLabel: SKLabelNode!

    private func buildSelector(types: [(BallType, String?)]) {
        availableTypes = types
        selectedIndex  = 0
        typeButtons.removeAll()
        selectorRow.removeAllChildren()

        // Always show selector (even single type so player knows what ball they have)
        let btnW: CGFloat    = 64
        let btnH: CGFloat    = 38
        let spacing: CGFloat = 8
        let totalW = CGFloat(types.count) * (btnW + spacing) - spacing
        let startX = -totalW / 2 + btnW / 2

        for (i, (type, keyColor)) in types.enumerated() {
            let btn = buildTypeButton(type: type, keyColor: keyColor, index: i, w: btnW, h: btnH)
            btn.position = CGPoint(x: startX + CGFloat(i) * (btnW + spacing), y: 0)
            selectorRow.addChild(btn)
            typeButtons.append(btn)
        }

        // Description label below buttons
        descLabel = SKLabelNode(fontNamed: TempleTheme.smallFont)
        descLabel.fontSize  = 11
        descLabel.fontColor = TempleTheme.gold.withAlphaComponent(0.75)
        descLabel.verticalAlignmentMode = .center
        descLabel.position  = CGPoint(x: 0, y: -(btnH / 2 + 12))
        descLabel.zPosition = 2
        selectorRow.addChild(descLabel)

        highlightSelected()
    }

    private func buildTypeButton(type: BallType, keyColor: String?, index: Int,
                                  w: CGFloat, h: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "ballBtn_\(index)"

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 7)
        bg.fillColor   = UIColor(red: 0.12, green: 0.10, blue: 0.07, alpha: 1)
        bg.strokeColor = TempleTheme.dimText.withAlphaComponent(0.4)
        bg.lineWidth   = 1
        bg.name        = "bg"
        node.addChild(bg)

        let color = (type == .key && keyColor != nil)
            ? TempleTheme.gateColor(for: keyColor!)
            : type.color

        let iconLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        iconLbl.text     = type.icon
        iconLbl.fontSize = 16
        iconLbl.fontColor = color
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position  = CGPoint(x: 0, y: 8)
        iconLbl.name      = "icon"
        node.addChild(iconLbl)

        let nameLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        nameLbl.text     = type.displayName
        nameLbl.fontSize = 10
        nameLbl.fontColor = TempleTheme.dimText
        nameLbl.verticalAlignmentMode = .center
        nameLbl.position  = CGPoint(x: 0, y: -9)
        nameLbl.name      = "lbl"
        node.addChild(nameLbl)

        return node
    }

    private func highlightSelected() {
        for (i, btn) in typeButtons.enumerated() {
            let isSelected = i == selectedIndex
            if let bg = btn.childNode(withName: "bg") as? SKShapeNode {
                bg.strokeColor = isSelected ? TempleTheme.gold : TempleTheme.dimText.withAlphaComponent(0.4)
                bg.lineWidth   = isSelected ? 2 : 1
                bg.fillColor   = isSelected
                    ? UIColor(red: 0.22, green: 0.17, blue: 0.08, alpha: 1)
                    : UIColor(red: 0.12, green: 0.10, blue: 0.07, alpha: 1)
            }
            if let lbl = btn.childNode(withName: "lbl") as? SKLabelNode {
                lbl.fontColor = isSelected ? TempleTheme.brightText : TempleTheme.dimText
            }
            if let icon = btn.childNode(withName: "icon") as? SKLabelNode {
                icon.setScale(isSelected ? 1.15 : 1.0)
            }
        }
        // Update description
        if descLabel != nil, !availableTypes.isEmpty {
            descLabel.text = availableTypes[selectedIndex].0.descriptionText
            descLabel.removeAllActions()
            descLabel.alpha = 1
            descLabel.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5),
                SKAction.fadeAlpha(to: 0.3, duration: 0.6)
            ]))
        }
    }

    func handleTap(at point: CGPoint) -> Bool {
        let local = selectorRow.convert(point, from: parent ?? self)
        for (i, btn) in typeButtons.enumerated() {
            if btn.contains(local) {
                selectedIndex = i
                highlightSelected()
                let sel = availableTypes[i]
                onBallTypeSelected?(sel.0, sel.1)
                return true
            }
        }
        return false
    }

    // MARK: - Mutations

    func addPoints(_ pts: Int) {
        score += pts
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.06),
            SKAction.scale(to: 1.00, duration: 0.10)
        ])
        scoreLabel.run(pop)
    }

    func decrementBalls() {
        ballsLeft = max(0, ballsLeft - 1)
    }

    func addBall() {
        ballsLeft += 1
        let flash = SKAction.sequence([
            SKAction.colorize(with: TempleTheme.powerExtraBall, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(with: TempleTheme.torchOrange,   colorBlendFactor: 0.0, duration: 0.2)
        ])
        ballsLabel.run(flash)
    }

    // MARK: - Helpers

    private func makeLabel(font: String, size: CGFloat, color: UIColor) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: font)
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }
}
