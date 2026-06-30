import SpriteKit

enum PegType: String, Codable {
    case normal      // standard stone peg
    case multiplier  // rune peg — bonus points on hit
    case fragile     // shatters after one hit (disappears)
}

class Peg: SKNode {

    static let radius: CGFloat = 8

    let type: PegType
    private var circle: SKShapeNode!
    private var broken = false

    init(type: PegType = .normal) {
        self.type = type
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let r = Peg.radius
        circle = SKShapeNode(circleOfRadius: r)
        circle.lineWidth = 2
        circle.zPosition = 5

        switch type {
        case .normal:
            circle.fillColor   = TempleTheme.pegNormal
            circle.strokeColor = TempleTheme.pegNormalStroke
        case .multiplier:
            circle.fillColor   = TempleTheme.pegRune
            circle.strokeColor = TempleTheme.pegRuneStroke
            // glowing ring
            let ring = SKShapeNode(circleOfRadius: r + 4)
            ring.fillColor = .clear
            ring.strokeColor = TempleTheme.pegRune.withAlphaComponent(0.35)
            ring.lineWidth = 2
            ring.zPosition = -1
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: 0.7),
                SKAction.fadeAlpha(to: 0.6, duration: 0.7)
            ])
            ring.run(SKAction.repeatForever(pulse))
            addChild(ring)
        case .fragile:
            circle.fillColor   = UIColor(red: 0.70, green: 0.55, blue: 0.35, alpha: 1)
            circle.strokeColor = UIColor(red: 0.50, green: 0.38, blue: 0.22, alpha: 1)
            // crack lines
            for angle in [CGFloat(0.4), CGFloat(1.9), CGFloat(3.4)] {
                let crack = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: cos(angle) * 2, y: sin(angle) * 2))
                path.addLine(to: CGPoint(x: cos(angle) * r, y: sin(angle) * r))
                crack.path = path
                crack.strokeColor = UIColor(red: 0.30, green: 0.22, blue: 0.14, alpha: 0.8)
                crack.lineWidth = 1
                crack.zPosition = 1
                circle.addChild(crack)
            }
        }

        addChild(circle)
        setupPhysics()
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: Peg.radius)
        body.isDynamic    = false
        body.restitution  = 0.65
        body.friction     = 0.0
        body.categoryBitMask    = PhysicsCategory.peg
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.ball
        physicsBody = body
    }

    func onHit() {
        guard !broken else { return }

        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.06),
            SKAction.colorize(with: circle.fillColor, colorBlendFactor: 0, duration: 0.18)
        ])
        circle.run(flash)

        if type == .fragile {
            broken = true
            let shatter = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.08),
                SKAction.fadeOut(withDuration: 0.18),
                SKAction.removeFromParent()
            ])
            run(shatter)
        }
    }

    func destroy(animated: Bool = true) {
        guard animated else { removeFromParent(); return }
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.07),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        run(pop)
    }
}
