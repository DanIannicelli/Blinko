import SpriteKit

class Gate: SKNode {

    enum GateState { case open, closed }

    let colorKey: String?           // nil = timed gate, non-nil = key-locked gate
    let toggleInterval: TimeInterval
    private(set) var state: GateState
    let gateWidth: CGFloat

    private var bar: SKShapeNode!
    private var lockIcon: SKLabelNode?

    init(width: CGFloat, colorKey: String? = nil, initialState: GateState = .closed, toggleInterval: TimeInterval = 0) {
        self.gateWidth = width
        self.colorKey = colorKey
        self.toggleInterval = toggleInterval
        self.state = initialState
        super.init()
        setup()
        if initialState == .open { openGate(animated: false) }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        let h: CGFloat = 10
        bar = SKShapeNode(rectOf: CGSize(width: gateWidth, height: h), cornerRadius: 3)
        bar.zPosition = 6

        let color = colorKey.map { TempleTheme.gateColor(for: $0) }
                  ?? UIColor(red: 0.70, green: 0.28, blue: 0.12, alpha: 1)
        bar.fillColor   = color
        bar.strokeColor = color.withAlphaComponent(0.5)
        bar.lineWidth   = 2
        addChild(bar)

        // Decorative segments (portcullis look)
        let segments = 4
        let segW = gateWidth / CGFloat(segments + 1)
        for i in 1...segments {
            let seg = SKShapeNode(rectOf: CGSize(width: 2, height: h + 8))
            seg.fillColor = color.withAlphaComponent(0.7)
            seg.strokeColor = .clear
            seg.position = CGPoint(x: -gateWidth / 2 + segW * CGFloat(i), y: 0)
            bar.addChild(seg)
        }

        if let ck = colorKey {
            // Lock icon showing the color
            let lock = SKLabelNode(fontNamed: TempleTheme.bodyFont)
            lock.text = "◆"
            lock.fontSize = 11
            lock.fontColor = TempleTheme.gateColor(for: ck).withAlphaComponent(0.9)
            lock.verticalAlignmentMode = .center
            lock.zPosition = 7
            lock.position = CGPoint(x: 0, y: 0)
            bar.addChild(lock)
            lockIcon = lock
        }

        applyPhysics()
    }

    private func applyPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: gateWidth, height: 10))
        body.isDynamic    = false
        body.restitution  = 0.2
        body.friction     = 0.1
        body.categoryBitMask  = PhysicsCategory.gate
        body.collisionBitMask = PhysicsCategory.ball
        body.contactTestBitMask = PhysicsCategory.ball
        physicsBody = body
    }

    func toggle(animated: Bool = true) {
        state == .closed ? openGate(animated: animated) : closeGate(animated: animated)
    }

    func openGate(animated: Bool = true) {
        guard state == .closed else { return }
        state = .open
        physicsBody = nil
        if animated {
            let slide = SKAction.scaleX(to: 0.01, duration: 0.22)
            slide.timingMode = .easeIn
            bar.run(slide)
        } else {
            bar.xScale = 0.01
        }
    }

    func closeGate(animated: Bool = true) {
        guard state == .open else { return }
        state = .closed
        if animated {
            bar.xScale = 0.01
            let slide = SKAction.scaleX(to: 1.0, duration: 0.22)
            slide.timingMode = .easeOut
            bar.run(slide) { [weak self] in self?.applyPhysics() }
        } else {
            bar.xScale = 1.0
            applyPhysics()
        }
    }
}
