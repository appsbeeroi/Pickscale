import Foundation

struct NestPack: Identifiable, Hashable {
    let id: String
    let title: String
    let coverAsset: String
    let order: Int
    let subtitle: String
}

private struct BarnyardRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func nextUInt() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func nextInt(upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(nextUInt() % UInt64(upperBound))
    }

    mutating func shuffled(_ input: [Int]) -> [Int] {
        var array = input
        guard array.count > 1 else { return array }
        for i in stride(from: array.count - 1, to: 0, by: -1) {
            let j = nextInt(upperBound: i + 1)
            array.swapAt(i, j)
        }
        return array
    }
}

private func stableSeed(_ text: String) -> UInt64 {
    var hash: UInt64 = 0xCBF29CE484222325
    for byte in text.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 0x100000001B3
    }
    return hash
}

enum OddbirdDeductionRulebook {
    static let packs: [NestPack] = [
        NestPack(id: "hatchling_run", title: "Hatchling Run", coverAsset: "nest_pack_hatchling_run", order: 0, subtitle: "First steps in the yard"),
        NestPack(id: "roost_riddle", title: "Roost Riddle", coverAsset: "nest_pack_roost_riddle", order: 1, subtitle: "Trickier roosts await"),
        NestPack(id: "barn_balance", title: "Barn Balance", coverAsset: "nest_pack_barn_balance", order: 2, subtitle: "Balance the whole barn"),
        NestPack(id: "flock_finale", title: "Flock Finale", coverAsset: "nest_pack_flock_finale", order: 3, subtitle: "The grand flock challenge")
    ]

    static let levelsPerPack = 9
    static let unlockThreshold = 6

    static let allLevels: [FlockLevel] = buildCatalog()

    static let tutorialLevel: FlockLevel = {
        let weights = [7, 11, 5]
        return FlockLevel(
            key: "tutorial",
            packId: "tutorial",
            ordinal: 1,
            task: .heaviestHen,
            birdCount: 3,
            weights: weights,
            moveLimit: 4
        )
    }()

    static func pack(for id: String) -> NestPack? {
        packs.first { $0.id == id }
    }

    static func levels(in packId: String) -> [FlockLevel] {
        allLevels.filter { $0.packId == packId }.sorted { $0.ordinal < $1.ordinal }
    }

    static func level(forKey key: String) -> FlockLevel? {
        if key == tutorialLevel.key { return tutorialLevel }
        return allLevels.first { $0.key == key }
    }

    static func nextLevel(after level: FlockLevel) -> FlockLevel? {
        let siblings = levels(in: level.packId)
        if let idx = siblings.firstIndex(where: { $0.key == level.key }), idx + 1 < siblings.count {
            return siblings[idx + 1]
        }
        return nil
    }

    static func nextPack(after packId: String) -> NestPack? {
        guard let current = pack(for: packId) else { return nil }
        return packs.first { $0.order == current.order + 1 }
    }

    private static func birdCount(pack: Int, ordinal: Int) -> Int {
        let base = 3 + pack
        let bump = (ordinal - 1) / 3
        return min(9, base + bump)
    }

    private static func task(pack: Int, ordinal: Int) -> FlockTaskKind {
        switch (ordinal + pack) % 3 {
        case 0: return .heaviestHen
        case 1: return .lightOddbird
        default: return .fullPeckOrder
        }
    }

    private static func buildCatalog() -> [FlockLevel] {
        var result: [FlockLevel] = []
        for (packIndex, pack) in packs.enumerated() {
            for ordinal in 1...levelsPerPack {
                let count = birdCount(pack: packIndex, ordinal: ordinal)
                let kind = task(pack: packIndex, ordinal: ordinal)
                let key = "\(pack.id)-\(ordinal)"
                var rng = BarnyardRandom(seed: stableSeed(key))
                let weights = weightSet(kind: kind, count: count, rng: &rng)
                let limit = count + (kind == .fullPeckOrder ? 2 : 1)
                result.append(
                    FlockLevel(
                        key: key,
                        packId: pack.id,
                        ordinal: ordinal,
                        task: kind,
                        birdCount: count,
                        weights: weights,
                        moveLimit: limit
                    )
                )
            }
        }
        return result
    }

    private static func weightSet(kind: FlockTaskKind, count: Int, rng: inout BarnyardRandom) -> [Int] {
        switch kind {
        case .lightOddbird:
            var weights = Array(repeating: 12, count: count)
            let oddIndex = rng.nextInt(upperBound: count)
            weights[oddIndex] = 7
            return weights
        case .heaviestHen, .fullPeckOrder:
            let distinct = (0..<count).map { 5 + $0 * 3 }
            return rng.shuffled(distinct)
        }
    }
}
