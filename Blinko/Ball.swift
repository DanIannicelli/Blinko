import SpriteKit

class Ball: SKNode {

    static let radius: CGFloat = 12

    let ballType: BallType
    let keyColor: String?   // which gate color this key ball unlocks

    private var shape: SKShapeNode!

    init(type: BallType = .normal, keyColor: String? = nil) {
        self.ballType = type
        self.keyColor = keyColor
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let r = Ball.radius
        shape = SKShapeNode(circleOfRadius: r)
        shape.zPosition = 10

        let baseColor: UIColor
        if ballType == .key, let kc = keyColor {
            baseColor = TempleTheme.gateColor(for: kc)
        } else {
            baseColor = ballType.color
        }
        shape.fillColor = baseColor
        shape.strokeColor = baseColor.withAlphaComponent(0.5)
        shape.lineWidth = 2

        switch ballType {
        case .ghost:
            shape.alpha = 0.72
        case .heavy:
            let inner = SKShapeNode(circleOfRadius: r * 0.45)
            inner.fillColor = UIColor(red: 0.32, green: 0.25, blue: 0.42, alpha: 1)
            inner.strokeColor = .clear
            inner.zPosition = 1
            shape.addChild(inner)
        case .bomb:
            // fuse
            let fuse = SKShapeNode(rectOf: CGSize(width: 3, height: 9))
            fuse.fillColor = TempleTheme.gold
            fuse.strokeColor = .clear
            fuse.position = CGPoint(x: 1, y: r + 3)
            fuse.zPosition = 1
            shape.addChild(fuse)
            // spark
            let spark = SKShapeNode(circleOfRadius: 3)
            spark.fillColor = .yellow
            spark.strokeColor = .clear
            spark.position = CGPoint(x: 1, y: r + 9)
            spark.zPosition = 2
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.6, duration: 0.25),
                SKAction.scale(to: 0.8, duration: 0.25)
            ])
            spark.run(SKAction.repeatForever(pulse))
            shape.addChild(spark)
        case .key:
            let dot = SKShapeNode(circleOfRadius: r * 0.35)
            dot.fillColor = .white.withAlphaComponent(0.8)
            dot.strokeColor = .clear
            dot.zPosition = 1
            shape.addChild(dot)
        default:
            break
        }

        addChild(shape)
        setupPhysics()
    }

    private func setupPhysics() {
        let r = Ball.radius
        let body = SKPhysicsBody(circleOfRadius: r)
        body.categoryBitMask    = PhysicsCategory.ball
        body.contactTestBitMask = PhysicsCategory.bucket
                                | PhysicsCategory.peg
                                | PhysicsCategory.powerUp
                                | PhysicsCategory.trapSensor
                                | PhysicsCategory.gate

        switch ballType {
        case .ghost:
            body.collisionBitMask = PhysicsCategory.wall | PhysicsCategory.bucket
            body.restitution = 0.65
            body.friction = 0.0
            body.linearDamping = 0.05
            body.density = 0.6
        case .heavy:
            body.collisionBitMask = PhysicsCategory.peg | PhysicsCategory.wall
                                  | PhysicsCategory.gate | PhysicsCategory.trap
            body.restitution = 0.25
            body.friction = 0.15
            body.density = 4.5
            body.linearDamping = 0.18
        case .bomb:
            body.collisionBitMask = PhysicsCategory.peg | PhysicsCategory.wall
                                  | PhysicsCategory.gate | PhysicsCategory.trap
            body.restitution = 0.55
            body.friction = 0.05
            body.density = 1.2
            body.linearDamping = 0.1
        default:
            body.collisionBitMask = PhysicsCategory.peg | PhysicsCategory.wall
                                  | PhysicsCategory.gate | PhysicsCategory.trap
            body.restitution = 0.60
            body.friction = 0.05
            body.density = 1.0
            body.linearDamping = 0.10
        }

        body.allowsRotation = true
        physicsBody = body
    }
}
