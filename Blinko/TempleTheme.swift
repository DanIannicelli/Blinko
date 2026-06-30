import UIKit
import SpriteKit

struct TempleTheme {

    // MARK: - Backgrounds
    static let background   = UIColor(red: 0.07, green: 0.05, blue: 0.03, alpha: 1)
    static let hudBG        = UIColor(red: 0.05, green: 0.04, blue: 0.02, alpha: 0.93)
    static let overlayBG    = UIColor(red: 0.06, green: 0.04, blue: 0.02, alpha: 0.95)

    // MARK: - Pegs
    static let pegNormal       = UIColor(red: 0.48, green: 0.42, blue: 0.32, alpha: 1)
    static let pegNormalStroke = UIColor(red: 0.32, green: 0.27, blue: 0.19, alpha: 1)
    static let pegRune         = UIColor(red: 0.28, green: 0.82, blue: 0.58, alpha: 1)
    static let pegRuneStroke   = UIColor(red: 0.18, green: 0.60, blue: 0.40, alpha: 1)

    // MARK: - Balls
    static let ballNormal = UIColor(red: 0.93, green: 0.68, blue: 0.16, alpha: 1)  // gold
    static let ballBomb   = UIColor(red: 0.88, green: 0.20, blue: 0.12, alpha: 1)  // red
    static let ballHeavy  = UIColor(red: 0.52, green: 0.42, blue: 0.62, alpha: 1)  // purple
    static let ballGhost  = UIColor(red: 0.78, green: 0.93, blue: 1.00, alpha: 0.72)

    // MARK: - Gate / key colors
    static let colorRed    = UIColor(red: 0.85, green: 0.18, blue: 0.12, alpha: 1)
    static let colorCyan   = UIColor(red: 0.14, green: 0.72, blue: 0.92, alpha: 1)
    static let colorGreen  = UIColor(red: 0.15, green: 0.75, blue: 0.28, alpha: 1)
    static let colorPurple = UIColor(red: 0.62, green: 0.20, blue: 0.82, alpha: 1)

    static func gateColor(for key: String) -> UIColor {
        switch key {
        case "red":    return colorRed
        case "cyan":   return colorCyan
        case "green":  return colorGreen
        case "purple": return colorPurple
        default:       return colorRed
        }
    }

    // MARK: - Power-ups
    static let powerLightning = UIColor(red: 1.00, green: 0.92, blue: 0.20, alpha: 1)
    static let powerExtraBall = UIColor(red: 0.20, green: 0.85, blue: 0.40, alpha: 1)
    static let powerBomb      = UIColor(red: 0.90, green: 0.35, blue: 0.10, alpha: 1)

    // MARK: - Buckets
    static func bucketColor(for points: Int) -> UIColor {
        switch points {
        case 0:           return UIColor(red: 0.16, green: 0.13, blue: 0.09, alpha: 1)
        case 1..<200:     return UIColor(red: 0.22, green: 0.48, blue: 0.22, alpha: 1)
        case 200..<1000:  return UIColor(red: 0.18, green: 0.33, blue: 0.68, alpha: 1)
        case 1000..<5000: return UIColor(red: 0.62, green: 0.44, blue: 0.08, alpha: 1)
        default:          return UIColor(red: 0.68, green: 0.14, blue: 0.58, alpha: 1)
        }
    }

    // MARK: - UI
    static let gold      = UIColor(red: 0.92, green: 0.76, blue: 0.22, alpha: 1)
    static let dimText   = UIColor(red: 0.62, green: 0.55, blue: 0.42, alpha: 1)
    static let brightText = UIColor(red: 0.96, green: 0.90, blue: 0.74, alpha: 1)
    static let torchOrange = UIColor(red: 0.95, green: 0.48, blue: 0.08, alpha: 1)

    static let titleFont = "AvenirNext-Bold"
    static let bodyFont  = "AvenirNext-DemiBold"
    static let smallFont = "AvenirNext-Regular"
}
