import SpriteKit

/// A stone cage. Ball enters from the top; a slab slams shut, trapping it forever.
class Trap: SKNode {

    private let w: CGFloat
    private let h: CGFloat
    private var topGate: SKShapeNode!
    private var triggered = false

    init(width: CGFloat, height: CGFloat = 60) {
        self.w = width
        self.h = height
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let wallColor   = UIColor(red: 0.38, green: 0.30, blue: 0.20, alpha: 1)
        let strokeColor = UIColor(red: 0.22, green: 0.17, blue: 0.10, alpha: 1)
        let thick: CGFloat = 8

        // Left wall
        addWall(rect: CGRect(x: -w / 2 - thick / 2, y: -h / 2, width: thick, height: h),
                color: wallColor, stroke: strokeColor)
        // Right wall
        addWall(rect: CGRect(x:  w / 2 - thick / 2, y: -h / 2, width: thick, height: h),
                color: wallColor, stroke: strokeColor)
        // Bottom wall
        addWall(rect: CGRect(x: -w / 2, y: -h / 2 - thick / 2, width: w + thick, height: thick),
                color: wallColor, stroke: strokeColor)

        // Top gate (stone slab — starts open / invisible until triggered)
        topGate = SKShapeNode(rectOf: CGSize(width: w - 2, height: thick))
        topGate.fillColor   = UIColor(red: 0.52, green: 0.42, blue: 0.28, alpha: 1)
        topGate.strokeColor = strokeColor
        topGate.lineWidth   = 2
        topGate.position    = CGPoint(x: 0, y: h / 2 + thick / 2)
        topGate.zPosition   = 6
        topGate.alpha       = 0
        topGate.xScale      = 0.05
        addChild(topGate)

        // Entry sensor — slightly below the trap opening
        let sensor = SKNode()
        sensor.position = CGPoint(x: 0, y: h / 2 - 4)
        let sensorBody = SKPhysicsBody(rectangleOf: CGSize(width: w - thick * 2, height: 6))
        sensorBody.isDynamic  = false
        sensorBody.categoryBitMask    = PhysicsCategory.trapSensor
        sensorBody.contactTestBitMask = PhysicsCategory.ball
        sensorBody.collisionBitMask   = PhysicsCategory.none
        sensor.physicsBody = sensorBody
        sensor.name = "trapSensor"
        addChild(sensor)

        // Skull symbol (warning)
        let skull = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        skull.text = "☠"
        skull.fontSize = 14
        skull.fontColor = UIColor(red: 0.80, green: 0.60, blue: 0.20, alpha: 0.70)
        skull.verticalAlignmentMode = .center
        skull.position = CGPoint(x: 0, y: 0)
        skull.zPosition = 7
        addChild(skull)
    }

    private func addWall(rect: CGRect, color: UIColor, stroke: UIColor) {
        let shape = SKShapeNode(rect: rect)
        shape.fillColor   = color
        shape.strokeColor = stroke
        shape.lineWidth   = 1
        shape.zPosition   = 5
        addChild(shape)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: rect.width, height: rect.height),
                                 center: CGPoint(x: rect.midX, y: rect.midY))
        body.isDynamic    = false
        body.restitution  = 0.3
        body.friction     = 0.5
        body.categoryBitMask  = PhysicsCategory.trap
        body.collisionBitMask = PhysicsCategory.ball
        shape.physicsBody = body
    }

    func trigger() {
        guard !triggered else { return }
        triggered = true

        // Slam the top gate shut
        let slam = SKAction.group([
            SKAction.fadeIn(withDuration: 0.05),
            SKAction.scaleX(to: 1.0, duration: 0.18)
        ])
        slam.timingMode = .easeIn
        topGate.run(slam) { [weak self] in
            guard let self = self else { return }
            let body = SKPhysicsBody(rectangleOf: CGSize(width: self.w - 2, height: 8))
            body.isDynamic    = false
            body.restitution  = 0.3
            body.categoryBitMask  = PhysicsCategory.trap
            body.collisionBitMask = PhysicsCategory.ball
            self.topGate.physicsBody = body
        }

        // Rumble
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -3, y: 0, duration: 0.04),
            SKAction.moveBy(x:  6, y: 0, duration: 0.04),
            SKAction.moveBy(x: -3, y: 0, duration: 0.04)
        ])
        run(shake)
    }
}
