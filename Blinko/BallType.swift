import UIKit

enum BallType: String, CaseIterable, Codable {
    case normal  // standard gold stone ball
    case key     // unlocks a color-matched gate
    case bomb    // explodes on landing, destroys nearby pegs
    case heavy   // high mass, punches through, low bounce
    case ghost   // passes through pegs, only walls/buckets block it

    var color: UIColor {
        switch self {
        case .normal: return TempleTheme.ballNormal
        case .key:    return TempleTheme.colorCyan  // default; overridden per-ball by keyColor
        case .bomb:   return TempleTheme.ballBomb
        case .heavy:  return TempleTheme.ballHeavy
        case .ghost:  return TempleTheme.ballGhost
        }
    }

    var displayName: String {
        switch self {
        case .normal: return "Stone"
        case .key:    return "Key"
        case .bomb:   return "Bomb"
        case .heavy:  return "Iron"
        case .ghost:  return "Spirit"
        }
    }

    var icon: String {
        switch self {
        case .normal: return "●"
        case .key:    return "◆"
        case .bomb:   return "✦"
        case .heavy:  return "⬤"
        case .ghost:  return "◎"
        }
    }
}
