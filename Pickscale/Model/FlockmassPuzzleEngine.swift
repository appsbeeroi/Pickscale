import Foundation

enum WeighVerdict: String, Codable {
    case leftHeavier
    case rightHeavier
    case balanced
}

enum FlockTaskKind: String, Codable, CaseIterable, Identifiable {
    case heaviestHen
    case lightOddbird
    case fullPeckOrder

    var id: String { rawValue }

    var badgeTitle: String {
        switch self {
        case .heaviestHen: return "Heaviest Hen"
        case .lightOddbird: return "Light Oddbird"
        case .fullPeckOrder: return "Full Peck Order"
        }
    }

    var iconAsset: String {
        switch self {
        case .heaviestHen: return "icon_heaviest_hen"
        case .lightOddbird: return "icon_light_oddbird"
        case .fullPeckOrder: return "icon_peck_order"
        }
    }

    var prompt: String {
        switch self {
        case .heaviestHen: return "Find the single heaviest hen in the flock."
        case .lightOddbird: return "One hen is unusually light. Find that oddbird."
        case .fullPeckOrder: return "Order every hen from lightest to heaviest."
        }
    }
}

struct FlockComparison: Identifiable, Codable, Equatable {
    let id: UUID
    let left: [Int]
    let right: [Int]
    let verdict: WeighVerdict

    init(left: [Int], right: [Int], verdict: WeighVerdict) {
        self.id = UUID()
        self.left = left
        self.right = right
        self.verdict = verdict
    }
}

struct FlockLevel: Identifiable, Hashable {
    let key: String
    let packId: String
    let ordinal: Int
    let task: FlockTaskKind
    let birdCount: Int
    let weights: [Int]
    let moveLimit: Int

    var id: String { key }

    static func == (lhs: FlockLevel, rhs: FlockLevel) -> Bool { lhs.key == rhs.key }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
}

enum HenGlyph {
    static func letter(for index: Int) -> String {
        guard index >= 0, index < 26 else { return "?" }
        return String(UnicodeScalar(65 + index) ?? "?")
    }

    static func asset(for index: Int) -> String {
        let letters = "abcdefghi"
        guard index >= 0, index < letters.count else { return "bird_a" }
        let char = Array(letters)[index]
        return "bird_\(char)"
    }
}

struct FlockmassPuzzleEngine {
    let level: FlockLevel

    var birdIndices: [Int] { Array(0..<level.birdCount) }

    func weight(of index: Int) -> Int {
        guard index >= 0, index < level.weights.count else { return 0 }
        return level.weights[index]
    }

    func verdict(left: [Int], right: [Int]) -> WeighVerdict {
        let leftMass = left.reduce(0) { $0 + weight(of: $1) }
        let rightMass = right.reduce(0) { $0 + weight(of: $1) }
        if leftMass > rightMass { return .leftHeavier }
        if rightMass > leftMass { return .rightHeavier }
        return .balanced
    }

    var heaviestIndex: Int {
        birdIndices.max(by: { weight(of: $0) < weight(of: $1) }) ?? 0
    }

    var lightestIndex: Int {
        birdIndices.min(by: { weight(of: $0) < weight(of: $1) }) ?? 0
    }

    var ascendingOrder: [Int] {
        birdIndices.sorted { weight(of: $0) < weight(of: $1) }
    }

    func isHeaviestCorrect(_ index: Int) -> Bool {
        index == heaviestIndex
    }

    func isOddbirdCorrect(_ index: Int) -> Bool {
        index == lightestIndex
    }

    func isOrderCorrect(_ order: [Int]) -> Bool {
        order == ascendingOrder
    }

    func validate(heaviest index: Int?) -> Bool {
        guard let index else { return false }
        return isHeaviestCorrect(index)
    }

    func validate(oddbird index: Int?) -> Bool {
        guard let index else { return false }
        return isOddbirdCorrect(index)
    }

    func validate(order: [Int]) -> Bool {
        guard order.count == level.birdCount else { return false }
        return isOrderCorrect(order)
    }

    func stars(forRemaining remaining: Int) -> Int {
        if remaining >= 2 { return 3 }
        if remaining == 1 { return 2 }
        return 1
    }

    func optimalRoute() -> [FlockComparison] {
        switch level.task {
        case .heaviestHen:
            return extremeRoute(findMax: true)
        case .lightOddbird:
            return extremeRoute(findMax: false)
        case .fullPeckOrder:
            return orderingRoute()
        }
    }

    private func extremeRoute(findMax: Bool) -> [FlockComparison] {
        var route: [FlockComparison] = []
        guard level.birdCount > 1 else { return route }
        var champion = 0
        for challenger in 1..<level.birdCount {
            let verdict = verdict(left: [champion], right: [challenger])
            route.append(FlockComparison(left: [champion], right: [challenger], verdict: verdict))
            let challengerWins: Bool
            switch verdict {
            case .leftHeavier: challengerWins = !findMax
            case .rightHeavier: challengerWins = findMax
            case .balanced: challengerWins = false
            }
            if challengerWins { champion = challenger }
        }
        return route
    }

    private func orderingRoute() -> [FlockComparison] {
        var route: [FlockComparison] = []
        var sorted: [Int] = []
        for index in birdIndices {
            var position = sorted.count
            for slot in 0..<sorted.count {
                let verdict = verdict(left: [index], right: [sorted[slot]])
                route.append(FlockComparison(left: [index], right: [sorted[slot]], verdict: verdict))
                if verdict == .rightHeavier || verdict == .balanced {
                    position = slot
                    break
                }
            }
            sorted.insert(index, at: position)
        }
        return route
    }
}
