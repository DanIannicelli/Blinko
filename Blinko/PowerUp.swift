import SpriteKit

enum PowerUpType: String, Codable {
    case lightning  // radial burst, clears pegs, score multiplier
    case extraBall  // adds one ball to remaining count
    case bomb       // destroys all pegs in large radius
}

class PowerUp: SKNode {

    let powerType: PowerUpType
    private var collected = false

    init(type: PowerUpType) {
        self.powerType = type
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let size: CGFloat = 22

        // Outer glow ring
        let ring = SKShapeNode(circleOfRadius: size + 6)
        ring.fillColor = .clear
        ring.strokeColor = ringColor.withAlphaComponent(0.4)
        ring.lineWidth = 2
        ring.zPosition = 8
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: 0.6),
            SKAction.fadeAlpha(to: 0.7, duration: 0.6)
        ])
        ring.run(SKAction.repeatForever(pulse))
        addChild(ring)

        // Body
        let body = SKShapeNode(circleOfRadius: size)
        body.fillColor   = ringColor.withAlphaComponent(0.25)
        body.strokeColor = ringColor
        body.lineWidth   = 2.5
        body.zPosition   = 9
        addChild(body)

        // Icon
        let icon = SKLabelNode(fontNamed: TempleTheme.titleFont)
        icon.text = symbol
        icon.fontSize = 20
        icon.fontColor = iconColor
        icon.verticalAlignmentMode = .center
        icon.zPosition = 10
        addChild(icon)

        // Float bob animation
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 0.9),
            SKAction.moveBy(x: 0, y: -5, duration: 0.9)
        ])
        run(SKAction.repeatForever(bob))

        setupPhysics(radius: size)
    }

    private var ringColor: UIColor {
        switch powerType {
        case .lightning: return TempleTheme.powerLightning
        case .extraBall: return TempleTheme.powerExtraBall
        case .bomb:      return TempleTheme.powerBomb
        }
    }

    private var iconColor: UIColor {
        switch powerType {
        case .lightning: return UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1)
        case .extraBall: return UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1)
        case .bomb:      return UIColor(red: 1.0, green: 0.85, blue: 0.6, alpha: 1)
        }
    }

    private var symbol: String {
        switch powerType {
        case .lightning: return "⚡"
        case .extraBall: return "+"
        case .bomb:      return "✦"
        }
    }

    private func setupPhysics(radius: CGFloat) {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic    = false
        body.categoryBitMask    = PhysicsCategory.powerUp
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.none
        physicsBody = body
    }

    func collect(completion: @escaping () -> Void) {
        guard !collected else { return }
        collected = true
        physicsBody = nil
        let burst = SKAction.sequence([
            SKAction.scale(to: 1.8, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ])
        run(burst, completion: completion)
    }
}
