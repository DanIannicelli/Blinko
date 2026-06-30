import CoreGraphics

enum PegPattern: String, Codable {
    case classic    // staggered rows
    case diamond    // diamond outline
    case spiral     // expanding spiral
    case walls      // parallel walls with gaps
    case cross      // plus sign
    case wave       // sine-wave rows
    case sparse     // few pegs, wide open
    case ring       // concentric rings
    case chevron    // V-shapes pointing down
    case fortress   // outer border with random interior
}

struct PegPosition {
    let x: CGFloat
    let y: CGFloat
    let type: PegType
}

struct PegPatternGenerator {

    static func generate(pattern: PegPattern,
                         screenWidth w: CGFloat,
                         screenHeight h: CGFloat,
                         rows: Int = 8,
                         cols: Int = 7) -> [PegPosition] {
        // Available play area (center-relative coordinates)
        let topY      =  h / 2 - 160
        let bottomY   = -h / 2 + 95
        let leftX     = -w / 2 + 20
        let rightX    =  w / 2 - 20
        let playW     = rightX - leftX
        let playH     = topY - bottomY

        switch pattern {
        case .classic:   return classic(w: playW, h: playH, rows: rows, cols: cols, cx: 0, ty: topY)
        case .diamond:   return diamond(w: playW, h: playH, cx: 0, cy: (topY + bottomY) / 2)
        case .spiral:    return spiral(w: playW, h: playH, cx: 0, cy: (topY + bottomY) / 2)
        case .walls:     return walls(w: playW, h: playH, cx: 0, ty: topY)
        case .cross:     return cross(w: playW, h: playH, cx: 0, cy: (topY + bottomY) / 2)
        case .wave:      return wave(w: playW, h: playH, rows: rows, cols: cols, cx: 0, ty: topY)
        case .sparse:    return sparse(w: playW, h: playH, cx: 0, ty: topY)
        case .ring:      return ring(w: playW, h: playH, cx: 0, cy: (topY + bottomY) / 2)
        case .chevron:   return chevron(w: playW, h: playH, cx: 0, ty: topY)
        case .fortress:  return fortress(w: playW, h: playH, cx: 0, ty: topY)
        }
    }

    // MARK: - Patterns

    private static func classic(w: CGFloat, h: CGFloat, rows: Int, cols: Int,
                                 cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let xSpacing = w / CGFloat(cols + 1)
        let ySpacing = h / CGFloat(rows - 1)

        for row in 0..<rows {
            let count     = (row % 2 == 0) ? cols : cols - 1
            let offsetX   = (row % 2 == 0) ? xSpacing : xSpacing * 1.5
            let y         = ty - CGFloat(row) * ySpacing
            for col in 0..<count {
                let x    = cx - w / 2 + offsetX + CGFloat(col) * xSpacing
                let isMulti = row == rows / 2 && col == count / 2
                pegs.append(PegPosition(x: x, y: y, type: isMulti ? .multiplier : .normal))
            }
        }
        return pegs
    }

    private static func diamond(w: CGFloat, h: CGFloat,
                                 cx: CGFloat, cy: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let spacing: CGFloat = 40
        let layers = 5
        for layer in 0...layers {
            let count = layer * 2 + 1
            let yTop  = cy + CGFloat(layers - layer) * spacing * 0.75
            for i in 0..<count {
                let x = cx - CGFloat(layer) * spacing * 0.5 + CGFloat(i) * spacing * 0.5
                pegs.append(PegPosition(x: x, y: yTop, type: layer == 0 ? .multiplier : .normal))
            }
        }
        // Mirror bottom half
        for layer in (0..<layers).reversed() {
            let count = layer * 2 + 1
            let yBot  = cy - CGFloat(layers - layer) * spacing * 0.75
            for i in 0..<count {
                let x = cx - CGFloat(layer) * spacing * 0.5 + CGFloat(i) * spacing * 0.5
                pegs.append(PegPosition(x: x, y: yBot, type: .normal))
            }
        }
        return pegs
    }

    private static func spiral(w: CGFloat, h: CGFloat,
                                cx: CGFloat, cy: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let total = 36
        for i in 0..<total {
            let t      = CGFloat(i) / CGFloat(total)
            let angle  = t * .pi * 4
            let radius = t * min(w, h) * 0.42
            let x = cx + cos(angle) * radius
            let y = cy + sin(angle) * radius
            pegs.append(PegPosition(x: x, y: y, type: i % 8 == 0 ? .multiplier : .normal))
        }
        return pegs
    }

    private static func walls(w: CGFloat, h: CGFloat,
                               cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let walls = 3
        let gaps  = 2
        let _ = gaps
        let wallH = h / CGFloat(walls + 1)
        for wall in 0..<walls {
            let y = ty - CGFloat(wall + 1) * wallH
            var xs: [CGFloat] = []
            // Fill wall with pegs leaving 2 random gaps
            let totalCols = 9
            let gapAt = Set([Int.random(in: 1..<totalCols-1), Int.random(in: 1..<totalCols-1)])
            for col in 0..<totalCols {
                if !gapAt.contains(col) {
                    let x = cx - w / 2 + w / CGFloat(totalCols) * (CGFloat(col) + 0.5)
                    xs.append(x)
                }
            }
            for x in xs {
                pegs.append(PegPosition(x: x, y: y, type: .normal))
            }
        }
        return pegs
    }

    private static func cross(w: CGFloat, h: CGFloat,
                               cx: CGFloat, cy: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let spacing: CGFloat = 38
        let armLen = 4
        // Horizontal arm
        for i in -armLen...armLen {
            pegs.append(PegPosition(x: cx + CGFloat(i) * spacing, y: cy,
                                     type: i == 0 ? .multiplier : .normal))
        }
        // Vertical arm (skip center already added)
        for i in -armLen...armLen where i != 0 {
            pegs.append(PegPosition(x: cx, y: cy + CGFloat(i) * spacing * 0.85, type: .normal))
        }
        return pegs
    }

    private static func wave(w: CGFloat, h: CGFloat, rows: Int, cols: Int,
                              cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let xSpacing = w / CGFloat(cols + 1)
        let ySpacing = h / CGFloat(rows - 1)
        let amp: CGFloat = 18

        for row in 0..<rows {
            let count  = cols
            let baseY  = ty - CGFloat(row) * ySpacing
            for col in 0..<count {
                let x = cx - w / 2 + xSpacing * (CGFloat(col) + 1)
                let y = baseY + sin(CGFloat(col) * .pi / 2 + CGFloat(row) * .pi / 3) * amp
                pegs.append(PegPosition(x: x, y: y, type: .normal))
            }
        }
        return pegs
    }

    private static func sparse(w: CGFloat, h: CGFloat,
                                cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let spacing: CGFloat = 65
        let cols = Int(w / spacing)
        let rows = 5
        for row in 0..<rows {
            let count  = (row % 2 == 0) ? cols : cols - 1
            let offset = (row % 2 == 0) ? spacing : spacing * 1.5
            let y      = ty - CGFloat(row) * spacing
            for col in 0..<count {
                let x = cx - w / 2 + offset + CGFloat(col) * spacing
                pegs.append(PegPosition(x: x, y: y, type: row == 2 && col == count/2 ? .multiplier : .normal))
            }
        }
        return pegs
    }

    private static func ring(w: CGFloat, h: CGFloat,
                              cx: CGFloat, cy: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let radii: [CGFloat] = [min(w, h) * 0.15, min(w, h) * 0.28, min(w, h) * 0.42]
        let counts = [8, 14, 20]
        for (r, count) in zip(radii, counts) {
            for i in 0..<count {
                let angle = CGFloat(i) / CGFloat(count) * .pi * 2
                let x = cx + cos(angle) * r
                let y = cy + sin(angle) * r
                pegs.append(PegPosition(x: x, y: y, type: r == radii[0] ? .multiplier : .normal))
            }
        }
        return pegs
    }

    private static func chevron(w: CGFloat, h: CGFloat,
                                 cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let chevrons = 4
        let spacing: CGFloat = 38
        let yStep = h / CGFloat(chevrons + 1)

        for c in 0..<chevrons {
            let cy = ty - CGFloat(c + 1) * yStep
            let arms = 4
            for a in 0...arms {
                let x   = cx + CGFloat(a) * spacing
                let y   = cy - CGFloat(a) * spacing * 0.5
                pegs.append(PegPosition(x:  x, y: y, type: .normal))
                if a > 0 {
                    pegs.append(PegPosition(x: -x, y: y, type: .normal))
                }
            }
        }
        return pegs
    }

    private static func fortress(w: CGFloat, h: CGFloat,
                                  cx: CGFloat, ty: CGFloat) -> [PegPosition] {
        var pegs: [PegPosition] = []
        let left  = cx - w / 2 + 20
        let right = cx + w / 2 - 20
        let top   = ty
        let bot   = ty - h
        let spacing: CGFloat = 35

        // Border
        var x = left
        while x <= right { pegs.append(PegPosition(x: x, y: top,  type: .normal)); x += spacing }
        x = left
        while x <= right { pegs.append(PegPosition(x: x, y: bot,  type: .normal)); x += spacing }
        var y = bot + spacing
        while y < top {
            pegs.append(PegPosition(x: left,  y: y, type: .normal))
            pegs.append(PegPosition(x: right, y: y, type: .normal))
            y += spacing
        }
        // Random interior
        let interior = 12
        for _ in 0..<interior {
            let ix = CGFloat.random(in: left + spacing ... right - spacing)
            let iy = CGFloat.random(in: bot + spacing  ... top - spacing)
            pegs.append(PegPosition(x: ix, y: iy, type: .fragile))
        }
        // Center multiplier
        pegs.append(PegPosition(x: cx, y: (top + bot) / 2, type: .multiplier))
        return pegs
    }
}
