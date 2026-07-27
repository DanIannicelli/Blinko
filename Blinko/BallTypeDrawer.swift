import SpriteKit

class BallTypeDrawer: SKNode {

    // MARK: - Public state
    private(set) var isOpen = false
    private(set) var selectedIndex = 0
    var onSelect: ((Int) -> Void)?   // called when user picks a type

    // MARK: - Private
    private var types: [(BallType, String?)] = []
    private var pillBtn:    SKShapeNode!
    private var pillIcon:   SKLabelNode!
    private var panel:      SKShapeNode!
    private var typeButtons: [SKNode] = []

    private let pillW:   CGFloat = 44
    private let pillH:   CGFloat = 44
    private let panelW:  CGFloat = 160
    private var panelH:  CGFloat = 0
    private var sceneH:  CGFloat = 0
    private var sceneW:  CGFloat = 0

    // MARK: - Init

    init(sceneSize: CGSize) {
        self.sceneW = sceneSize.width
        self.sceneH = sceneSize.height
        super.init()
        buildPill()
        buildPanel()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildPill() {
        pillBtn = SKShapeNode(rectOf: CGSize(width: pillW, height: pillH), cornerRadius: pillW / 2)
        pillBtn.fillColor   = UIColor(red: 0.18, green: 0.13, blue: 0.08, alpha: 0.92)
        pillBtn.strokeColor = TempleTheme.gold.withAlphaComponent(0.6)
        pillBtn.lineWidth   = 1.5
        pillBtn.zPosition   = 200
        pillBtn.name        = "drawerBtn"
        // right edge, vertically centered
        pillBtn.position = CGPoint(x: sceneW / 2 - pillW / 2 - 6, y: 0)
        addChild(pillBtn)

        pillIcon = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        pillIcon.fontSize = 22
        pillIcon.verticalAlignmentMode = .center
        pillIcon.zPosition = 201
        pillIcon.name = "drawerBtn"
        pillBtn.addChild(pillIcon)
    }

    private func buildPanel() {
        panel = SKShapeNode()   // sized in configure()
        panel.fillColor   = UIColor(red: 0.10, green: 0.08, blue: 0.05, alpha: 0.97)
        panel.strokeColor = TempleTheme.gold.withAlphaComponent(0.45)
        panel.lineWidth   = 1.5
        panel.zPosition   = 190
        panel.alpha       = 0
        panel.isHidden    = true
        // parked off-screen right
        panel.position = CGPoint(x: sceneW / 2 + panelW, y: 0)
        addChild(panel)
    }

    // MARK: - Configure

    func configure(types newTypes: [(BallType, String?)], selectedIndex idx: Int) {
        types         = newTypes.isEmpty ? [(.normal, nil)] : newTypes
        selectedIndex = min(idx, types.count - 1)
        rebuildPanelContent()
        refreshPill()
    }

    private func rebuildPanelContent() {
        panel.removeAllChildren()
        typeButtons.removeAll()

        let btnH: CGFloat   = 52
        let padding: CGFloat = 12
        panelH = CGFloat(types.count) * (btnH + padding) + padding + 36

        let rect = CGRect(x: -panelW / 2, y: -panelH / 2,
                          width: panelW,  height: panelH)
        panel.path = CGPath(roundedRect: rect, cornerWidth: 12, cornerHeight: 12, transform: nil)

        // Title
        let title = SKLabelNode(fontNamed: TempleTheme.smallFont)
        title.text = "BALL TYPE"
        title.fontSize = 11
        title.fontColor = TempleTheme.gold.withAlphaComponent(0.7)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: panelH / 2 - 20)
        panel.addChild(title)

        let startY = panelH / 2 - 44
        for (i, (type, keyColor)) in types.enumerated() {
            let btn = makeTypeBtn(type: type, keyColor: keyColor, index: i,
                                  w: panelW - 24, h: btnH)
            btn.position = CGPoint(x: 0, y: startY - CGFloat(i) * (btnH + padding))
            panel.addChild(btn)
            typeButtons.append(btn)
        }
        highlightSelected()
    }

    private func makeTypeBtn(type: BallType, keyColor: String?,
                              index: Int, w: CGFloat, h: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "typeBtn_\(index)"

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 8)
        bg.fillColor   = UIColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1)
        bg.strokeColor = TempleTheme.dimText.withAlphaComponent(0.35)
        bg.lineWidth   = 1; bg.name = "bg"
        node.addChild(bg)

        let color = (type == .key && keyColor != nil)
            ? TempleTheme.gateColor(for: keyColor!) : type.color

        let iconLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        iconLbl.text  = type.icon; iconLbl.fontSize = 20
        iconLbl.fontColor = color
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position = CGPoint(x: -w / 2 + 22, y: 4)
        node.addChild(iconLbl)

        let nameLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        nameLbl.text  = type.displayName; nameLbl.fontSize = 14
        nameLbl.fontColor = TempleTheme.brightText
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.verticalAlignmentMode   = .center
        nameLbl.position = CGPoint(x: -w / 2 + 44, y: 5)
        nameLbl.name = "lbl"
        node.addChild(nameLbl)

        let descLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        descLbl.text  = type.descriptionText; descLbl.fontSize = 9
        descLbl.fontColor = TempleTheme.dimText
        descLbl.horizontalAlignmentMode = .left
        descLbl.verticalAlignmentMode   = .center
        descLbl.position = CGPoint(x: -w / 2 + 44, y: -10)
        node.addChild(descLbl)

        return node
    }

    private func highlightSelected() {
        for (i, btn) in typeButtons.enumerated() {
            let sel = i == selectedIndex
            if let bg = btn.childNode(withName: "bg") as? SKShapeNode {
                bg.strokeColor = sel ? TempleTheme.gold : TempleTheme.dimText.withAlphaComponent(0.35)
                bg.lineWidth   = sel ? 2 : 1
                bg.fillColor   = sel
                    ? UIColor(red: 0.22, green: 0.17, blue: 0.08, alpha: 1)
                    : UIColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1)
            }
            if let lbl = btn.childNode(withName: "lbl") as? SKLabelNode {
                lbl.fontColor = sel ? TempleTheme.gold : TempleTheme.brightText
            }
        }
    }

    private func refreshPill() {
        guard !types.isEmpty else { return }
        let t = types[selectedIndex]
        pillIcon.text = t.0.icon
        let color = (t.0 == .key && t.1 != nil) ? TempleTheme.gateColor(for: t.1!) : t.0.color
        pillIcon.fontColor = color
        pillBtn.strokeColor = color.withAlphaComponent(0.8)
    }

    // MARK: - Open / Close

    func open() {
        guard !isOpen else { return }
        isOpen = true
        panel.isHidden = false
        panel.alpha    = 0
        let targetX    = sceneW / 2 - panelW / 2 - 14
        panel.position = CGPoint(x: sceneW / 2 + panelW, y: 0)
        panel.run(SKAction.group([
            SKAction.moveTo(x: targetX, duration: 0.22),
            SKAction.fadeIn(withDuration: 0.18)
        ]))
        pillBtn.run(SKAction.colorize(with: TempleTheme.gold.withAlphaComponent(0.3),
                                      colorBlendFactor: 0.5, duration: 0.15))
    }

    func close() {
        guard isOpen else { return }
        isOpen = false
        panel.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveTo(x: sceneW / 2 + panelW, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.14)
            ]),
            SKAction.run { [weak self] in self?.panel.isHidden = true }
        ]))
        pillBtn.run(SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.15))
    }

    // MARK: - Hit testing

    /// Returns true if this touch was consumed (pill tap or drawer interaction).
    func handleTap(at scenePoint: CGPoint) -> Bool {
        // Pill button
        let pillLocal = pillBtn.convert(scenePoint, from: parent ?? self)
        if pillBtn.contains(pillLocal) {
            isOpen ? close() : open()
            return true
        }

        guard isOpen else { return false }

        // Panel background — absorb all taps while open
        let panelLocal = panel.convert(scenePoint, from: parent ?? self)
        if panel.contains(panelLocal) {
            // Check each type button
            for (i, btn) in typeButtons.enumerated() {
                let btnLocal = btn.convert(scenePoint, from: parent ?? self)
                let hitBox = CGRect(x: -(panelW - 24) / 2, y: -26,
                                    width: panelW - 24, height: 52)
                if hitBox.contains(btnLocal) {
                    selectedIndex = i
                    highlightSelected()
                    refreshPill()
                    onSelect?(i)
                    close()
                    return true
                }
            }
            return true  // absorbed even if no button hit
        }

        // Tap outside drawer — close it
        close()
        return true
    }
}
