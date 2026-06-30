import SpriteKit

class Bucket: SKNode {

    let points: Int
    private let w: CGFloat
    static let height: CGFloat = 50

    init(points: Int, width: CGFloat) {
        self.points = points
        self.w = width
        super.init()
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let fill = SKShapeNode(rectOf: CGSize(width: w - 2, height: Bucket.height), cornerRadius: 3)
        fill.fillColor   = TempleTheme.bucketColor(for: points)
        fill.strokeColor = fill.fillColor.withAlphaComponent(0.4)
        fill.lineWidth   = 1
        fill.zPosition   = 2
        addChild(fill)

        let label = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        if points == 0 {
            label.text = "✕"
            label.fontColor = UIColor(red: 0.45, green: 0.38, blue: 0.28, alpha: 1)
        } else {
            label.text = points >= 1000 ? "\(points/1000)K" : "\(points)"
            label.fontColor = TempleTheme.brightText
        }
        label.fontSize = 15
        label.verticalAlignmentMode = .center
        label.zPosition = 3
        addChild(label)

        let body = SKPhysicsBody(rectangleOf: CGSize(width: w - 4, height: Bucket.height))
        body.isDynamic          = false
        body.categoryBitMask    = PhysicsCategory.bucket
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.none
        physicsBody = body
    }

    func flash() {
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.07),
            SKAction.scale(to: 1.00, duration: 0.12)
        ])
        run(pop)
    }
}
