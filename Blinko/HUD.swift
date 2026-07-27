import SpriteKit

class HUD: SKNode {

    private var scoreLabel:  SKLabelNode!
    private var ballsLabel:  SKLabelNode!
    private var levelLabel:  SKLabelNode!
    private var targetLabel: SKLabelNode!

    private(set) var score: Int = 0 {
        didSet { scoreLabel.text = "Score  \(score)" }
    }
    private(set) var ballsLeft: Int = 0 {
        didSet { ballsLabel.text = "\(ballsLeft) ●" }
    }

    // Ball-type state (selection managed by BallTypeDrawer, stored here)
    private var availableTypes: [(BallType, String?)] = []
    private(set) var selectedIndex = 0

    var selectedBallType: BallType { availableTypes.isEmpty ? .normal : availableTypes[selectedIndex].0 }
    var selectedKeyColor: String?  { availableTypes.isEmpty ? nil    : availableTypes[selectedIndex].1 }

    // MARK: - Setup

    override init() {
        super.init()
        buildHUD()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildHUD() {
        let panel = SKShapeNode(rectOf: CGSize(width: 420, height: 68), cornerRadius: 0)
        panel.fillColor   = TempleTheme.hudBG
        panel.strokeColor = UIColor(red: 0.25, green: 0.20, blue: 0.12, alpha: 0.8)
        panel.lineWidth   = 1
        panel.zPosition   = 0
        addChild(panel)

        let border = CGMutablePath()
        border.move(to: CGPoint(x: -210, y: -34))
        border.addLine(to: CGPoint(x: 210, y: -34))
        let b = SKShapeNode(path: border)
        b.strokeColor = TempleTheme.gold.withAlphaComponent(0.4)
        b.lineWidth = 1; b.zPosition = 1
        addChild(b)

        levelLabel = makeLabel(font: TempleTheme.smallFont, size: 12, color: TempleTheme.gold)
        levelLabel.position = CGPoint(x: 0, y: 17); levelLabel.zPosition = 1
        addChild(levelLabel)

        scoreLabel = makeLabel(font: TempleTheme.bodyFont, size: 17, color: TempleTheme.brightText)
        scoreLabel.position = CGPoint(x: -75, y: -2); scoreLabel.zPosition = 1
        addChild(scoreLabel)

        ballsLabel = makeLabel(font: TempleTheme.bodyFont, size: 17, color: TempleTheme.torchOrange)
        ballsLabel.position = CGPoint(x: 75, y: -2); ballsLabel.zPosition = 1
        addChild(ballsLabel)

        targetLabel = makeLabel(font: TempleTheme.smallFont, size: 11, color: TempleTheme.dimText)
        targetLabel.position = CGPoint(x: 0, y: -20); targetLabel.zPosition = 1
        addChild(targetLabel)
    }

    // MARK: - Configure

    func configure(level: Int, title: String, balls: Int, target: Int,
                   ballTypes: [(BallType, String?)]) {
        levelLabel.text  = "Level \(level)  ·  \(title)"
        targetLabel.text = "Target  \(target)"
        ballsLeft        = balls
        score            = 0
        availableTypes   = ballTypes.isEmpty ? [(.normal, nil)] : ballTypes
        selectedIndex    = 0
    }

    func selectType(at index: Int) {
        guard index < availableTypes.count else { return }
        selectedIndex = index
    }

    func availableTypesList() -> [(BallType, String?)] { availableTypes }

    // MARK: - Mutations

    func addPoints(_ pts: Int) {
        score += pts
        scoreLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.06),
            SKAction.scale(to: 1.00, duration: 0.10)
        ]))
    }

    func decrementBalls() { ballsLeft = max(0, ballsLeft - 1) }

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
        l.fontSize = size; l.fontColor = color
        l.verticalAlignmentMode  = .center
        l.horizontalAlignmentMode = .center
        return l
    }
}
