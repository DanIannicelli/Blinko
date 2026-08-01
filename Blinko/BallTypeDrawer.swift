import SpriteKit

class BallTypeDrawer: SKNode {

    // MARK: - Public
    private(set) var isOpen = false
    private(set) var selectedIndex = 0
    var onSelect: ((Int) -> Void)?

    // MARK: - Private
    private var types: [(BallType, String?)] = []
    private var pillBtn:     SKShapeNode!
    private var pillIcon:    SKLabelNode!
    private var panel:       SKShapeNode!
    private var typeButtons: [SKNode] = []

    private let pillW:   CGFloat = 70
    private let pillH:   CGFloat = 50
    private let panelW:  CGFloat = 170
    private var panelH:  CGFloat = 0
    private var sceneH:  CGFloat = 0
    private var sceneW:  CGFloat = 0

    // MARK: - Init

    init(sceneSize: CGSize) {
        sceneW = sceneSize.width
        sceneH = sceneSize.height
        super.init()
        buildPill()
        buildPanel()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build pill

    private func buildPill() {
        pillBtn = SKShapeNode(rectOf: CGSize(width: pillW, height: pillH), cornerRadius: 12)
        pillBtn.fillColor   = UIColor(red: 0.20, green: 0.14, blue: 0.08, alpha: 0.95)
        pillBtn.strokeColor = TempleTheme.gold
        pillBtn.lineWidth   = 2
        pillBtn.zPosition   = 200
        pillBtn.name        = "drawerPill"
        // Top-right, just below HUD
        pillBtn.position = CGPoint(x: sceneW / 2 - pillW / 2 - 8,
                                   y: sceneH / 2 - 140)
        addChild(pillBtn)

        pillIcon = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        pillIcon.fontSize = 18
        pillIcon.fontColor = TempleTheme.gold
        pillIcon.verticalAlignmentMode = .center
        pillIcon.position = CGPoint(x: -6, y: 7)
        pillIcon.name = "drawerPill"
        pillBtn.addChild(pillIcon)

        let tag = SKLabelNode(fontNamed: TempleTheme.smallFont)
        tag.text = "BALL ❮"; tag.fontSize = 10
        tag.fontColor = TempleTheme.gold.withAlphaComponent(0.8)
        tag.verticalAlignmentMode = .center
        tag.position = CGPoint(x: 0, y: -10)
        tag.name = "drawerPill"
        pillBtn.addChild(tag)
    }

    // MARK: - Build panel

    private func buildPanel() {
        panel = SKShapeNode()
        panel.fillColor   = UIColor(red: 0.09, green: 0.07, blue: 0.04, alpha: 0.97)
        panel.strokeColor = TempleTheme.gold.withAlphaComponent(0.5)
        panel.lineWidth   = 1.5
        panel.zPosition   = 190
        panel.alpha       = 0
        panel.isHidden    = true
        panel.name        = "drawerPanel"
        panel.position    = CGPoint(x: sceneW, y: 0)   // parked off-screen
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

        let btnH: CGFloat    = 56
        let padding: CGFloat = 10
        panelH = CGFloat(types.count) * (btnH + padding) + padding + 38

        let rect = CGRect(x: -panelW / 2, y: -panelH / 2, width: panelW, height: panelH)
        panel.path = CGPath(roundedRect: rect, cornerWidth: 14, cornerHeight: 14, transform: nil)

        // Invisible hit-capture background (same size, name "drawerPanel")
        let hit = SKShapeNode(path: panel.path!)
        hit.fillColor   = .clear
        hit.strokeColor = .clear
        hit.name        = "drawerPanel"
        panel.addChild(hit)

        let title = SKLabelNode(fontNamed: TempleTheme.smallFont)
        title.text = "SELECT BALL TYPE"
        title.fontSize = 10
        title.fontColor = TempleTheme.gold.withAlphaComponent(0.6)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: panelH / 2 - 18)
        panel.addChild(title)

        let startY = panelH / 2 - 44
        for (i, (type, keyColor)) in types.enumerated() {
            let btn = makeTypeBtn(type: type, keyColor: keyColor, index: i,
                                  w: panelW - 20, h: btnH)
            btn.position = CGPoint(x: 0, y: startY - CGFloat(i) * (btnH + padding))
            panel.addChild(btn)
            typeButtons.append(btn)
        }
        highlightSelected()
    }

    private func makeTypeBtn(type: BallType, keyColor: String?,
                              index: Int, w: CGFloat, h: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "drawerType_\(index)"

        let bg = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 9)
        bg.name        = "drawerType_\(index)"
        bg.fillColor   = UIColor(red: 0.16, green: 0.12, blue: 0.07, alpha: 1)
        bg.strokeColor = TempleTheme.dimText.withAlphaComponent(0.3)
        bg.lineWidth   = 1
        node.addChild(bg)

        let color = (type == .key && keyColor != nil)
            ? TempleTheme.gateColor(for: keyColor!) : type.color

        let iconLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        iconLbl.text = type.icon; iconLbl.fontSize = 22
        iconLbl.fontColor = color
        iconLbl.verticalAlignmentMode = .center
        iconLbl.position = CGPoint(x: -w / 2 + 22, y: 6)
        iconLbl.name = "drawerType_\(index)"
        node.addChild(iconLbl)

        let nameLbl = SKLabelNode(fontNamed: TempleTheme.bodyFont)
        nameLbl.text = type.displayName; nameLbl.fontSize = 14
        nameLbl.fontColor = TempleTheme.brightText
        nameLbl.horizontalAlignmentMode = .left
        nameLbl.verticalAlignmentMode   = .center
        nameLbl.position = CGPoint(x: -w / 2 + 44, y: 6)
        nameLbl.name = "drawerType_\(index)"
        node.addChild(nameLbl)

        let descLbl = SKLabelNode(fontNamed: TempleTheme.smallFont)
        descLbl.text = type.descriptionText; descLbl.fontSize = 9
        descLbl.fontColor = TempleTheme.dimText
        descLbl.horizontalAlignmentMode = .left
        descLbl.verticalAlignmentMode   = .center
        descLbl.position = CGPoint(x: -w / 2 + 44, y: -10)
        descLbl.name = "drawerType_\(index)"
        node.addChild(descLbl)

        return node
    }

    private func highlightSelected() {
        for (i, btn) in typeButtons.enumerated() {
            let sel = i == selectedIndex
            if let bg = btn.childNode(withName: "drawerType_\(i)") as? SKShapeNode {
                bg.strokeColor = sel ? TempleTheme.gold : TempleTheme.dimText.withAlphaComponent(0.3)
                bg.lineWidth   = sel ? 2 : 1
                bg.fillColor   = sel
                    ? UIColor(red: 0.24, green: 0.18, blue: 0.08, alpha: 1)
                    : UIColor(red: 0.16, green: 0.12, blue: 0.07, alpha: 1)
            }
        }
    }

    private func refreshPill() {
        guard !types.isEmpty else { return }
        let t = types[selectedIndex]
        pillIcon.text = t.0.icon
        let color = (t.0 == .key && t.1 != nil) ? TempleTheme.gateColor(for: t.1!) : t.0.color
        pillIcon.fontColor  = color
        pillBtn.strokeColor = TempleTheme.gold
    }

    // MARK: - Open / Close

    func open() {
        guard !isOpen else { return }
        isOpen = true
        panel.removeAllActions()
        panel.isHidden = false
        panel.alpha    = 0
        let tx = sceneW / 2 - panelW / 2 - 8
        let ty = pillBtn.position.y - panelH / 2 + pillH / 2
        panel.position = CGPoint(x: sceneW / 2 + panelW, y: ty)
        panel.run(SKAction.group([
            SKAction.moveTo(x: tx, duration: 0.20),
            SKAction.fadeIn(withDuration: 0.16)
        ]))
    }

    func close() {
        guard isOpen else { return }
        isOpen = false
        panel.removeAllActions()
        panel.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveTo(x: sceneW / 2 + panelW, duration: 0.16),
                SKAction.fadeOut(withDuration: 0.12)
            ]),
            SKAction.run { [weak self] in self?.panel.isHidden = true }
        ]))
    }

    // MARK: - Hit testing via SpriteKit node names

    /// Pass in `scene.nodes(at: touchLocation)`. Returns true if consumed.
    func handleNodes(_ hitNodes: [SKNode]) -> Bool {
        let names = hitNodes.compactMap { $0.name }

        // Pill tapped
        if names.contains("drawerPill") {
            isOpen ? close() : open()
            return true
        }

        guard isOpen else { return false }

        // Type button tapped
        for name in names where name.hasPrefix("drawerType_") {
            if let idx = Int(name.dropFirst("drawerType_".count)) {
                selectedIndex = idx
                highlightSelected()
                refreshPill()
                onSelect?(idx)
                close()
                return true
            }
        }

        // Panel background — absorb tap
        if names.contains("drawerPanel") { return true }

        // Outside panel — close
        close()
        return true
    }
}
