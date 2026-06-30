import Foundation
import UIKit

class LevelLoader {

    static let shared = LevelLoader()

    private var handcrafted: [LevelConfig] = []
    private let totalLevels = 200

    private init() { loadJSON() }

    // MARK: - Public

    func config(for number: Int, screenWidth w: CGFloat, screenHeight h: CGFloat) -> LevelConfig {
        let idx = number - 1
        if idx < handcrafted.count {
            return handcrafted[idx]
        }
        return procedural(number: number, w: w, h: h)
    }

    var totalCount: Int { totalLevels }

    // MARK: - JSON Loading

    private func loadJSON() {
        guard let url = Bundle.main.url(forResource: "levels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(LevelsFile.self, from: data) else {
            print("⚠️ levels.json not found or invalid")
            return
        }
        handcrafted = file.levels
    }

    // MARK: - Procedural Generation (levels 31–200)

    private func procedural(number n: Int, w: CGFloat, h: CGFloat) -> LevelConfig {
        // Difficulty tiers
        let tier: Int
        switch n {
        case 31...50:  tier = 1
        case 51...80:  tier = 2
        case 81...120: tier = 3
        case 121...160:tier = 4
        default:       tier = 5
        }

        let ballCount    = max(3, 6 - tier / 2)
        let multiplierPts = 100_000 * tier
        let bucketPts    = scaledBuckets(tier: tier, jackpot: multiplierPts)
        let target       = bucketPts[bucketPts.count / 2] * ballCount / 3
        let patterns     = PegPattern.allCases
        let pattern      = patterns[n % patterns.count]

        var ballTypes    = ["normal"]
        var keyColors:   [String] = []
        var gates:       [GateCfg] = []
        var traps:       [TrapCfg] = []
        var powerUps:    [PowerUpCfg] = []

        if tier >= 1 { ballTypes += ["heavy"] }
        if tier >= 2 { ballTypes += ["bomb", "ghost"] }
        if tier >= 3 { ballTypes += ["key"]; keyColors = pickColors(count: tier) }
        if tier >= 4 { ballTypes += ["key"] }

        // Gates
        let gateCount = min(tier + 1, 4)
        let colors = ["cyan","red","green","purple"]
        for i in 0..<gateCount {
            let isKeyed = tier >= 3 && i < keyColors.count
            let kc = isKeyed ? keyColors[i % keyColors.count] : nil
            if isKeyed { keyColors = Array(Set(keyColors + [kc!])) }
            let interval = isKeyed ? 0.0 : Double.random(in: 0.8...2.2)
            gates.append(GateCfg(
                xFrac:          gateX(index: i, total: gateCount),
                yFrac:          gateY(index: i, total: gateCount),
                widthFrac:      CGFloat.random(in: 0.28...0.45),
                colorKey:       kc,
                toggleInterval: interval,
                startOpen:      i % 2 == 1
            ))
        }
        _ = colors

        // Traps
        if tier >= 2 {
            let trapCount = min(tier - 1, 3)
            let trapXs: [CGFloat] = [-0.32, 0.32, 0.0]
            for i in 0..<min(trapCount, trapXs.count) {
                traps.append(TrapCfg(xFrac: trapXs[i], yFrac: CGFloat.random(in: -0.2...0.0), widthFrac: 0.22))
            }
        }

        // Power-ups
        if tier >= 1 {
            powerUps.append(PowerUpCfg(xFrac: 0, yFrac: 0.1, type: "lightning"))
        }
        if tier >= 2 {
            powerUps.append(PowerUpCfg(xFrac: CGFloat.random(in: -0.3...0.3), yFrac: -0.05, type: "extraBall"))
        }
        if tier >= 3 {
            powerUps.append(PowerUpCfg(xFrac: CGFloat.random(in: -0.3...0.3), yFrac: -0.15, type: "bomb"))
        }

        return LevelConfig(
            number:             n,
            title:              titles(tier: tier, n: n),
            ballCount:          ballCount,
            availableBallTypes: Array(Set(ballTypes)),
            keyColors:          Array(Set(keyColors)),
            bucketPoints:       bucketPts,
            pegPattern:         pattern.rawValue,
            pegRows:            nil,
            pegCols:            nil,
            gates:              gates,
            traps:              traps,
            powerUps:           powerUps,
            targetScore:        target,
            multiplier:         nil
        )
    }

    private func scaledBuckets(tier: Int, jackpot: Int) -> [Int] {
        let s = tier
        return [0, 500 * s, 2000 * s, jackpot, 2000 * s, 500 * s, 0]
    }

    private func pickColors(count: Int) -> [String] {
        let all = ["cyan","red","green","purple"]
        return Array(all.shuffled().prefix(min(count, all.count)))
    }

    private func gateX(index: Int, total: Int) -> CGFloat {
        let positions: [CGFloat] = [-0.22, 0.22, -0.35, 0.35, 0.0]
        return positions[index % positions.count]
    }

    private func gateY(index: Int, total: Int) -> CGFloat {
        let step = 0.15
        return CGFloat(index) * -step
    }

    private func titles(tier: Int, n: Int) -> String {
        let t1 = ["Hall of Echoes","Stone Passage","Rune Gallery","The Inner Sanctum",
                  "Chamber of Echoes","Vault Trial","Ancient Corridor","Pillar Room"]
        let t2 = ["Iron Chamber","The Gauntlet","Deep Crypt","Shadow Hall",
                  "Crystal Vault","Ember Room","Obsidian Hall","Lava Passage"]
        let t3 = ["Chaos Chamber","Rune Storm","Lightning Hall","Inferno Vault",
                  "Tempest Room","The Dark Sanctum","Vortex Chamber","Storm Gate"]
        let t4 = ["Abyss Trial","Soul Forge","Demon Gate","Hellfire Chamber",
                  "Void Passage","Shadow Throne","Cursed Vault","Death Chamber"]
        let t5 = ["Final Trial","Omega Gate","The Eternal Hall","Last Sanctum",
                  "Ultimate Chamber","Apocalypse Vault","Infinity Gate","End of Days"]
        let lists = [t1, t2, t3, t4, t5]
        let list = lists[min(tier - 1, lists.count - 1)]
        return list[n % list.count]
    }
}

extension PegPattern: CaseIterable {
    static var allCases: [PegPattern] {
        [.classic, .diamond, .spiral, .walls, .cross, .wave, .sparse, .ring, .chevron, .fortress]
    }
}
