import Foundation

enum LedgerRelation: String, Codable, CaseIterable {
    case heavier
    case lighter
    case equal

    var symbol: String {
        switch self {
        case .heavier: return ">"
        case .lighter: return "<"
        case .equal: return "="
        }
    }

    var caption: String {
        switch self {
        case .heavier: return "Heavier"
        case .lighter: return "Lighter"
        case .equal: return "Equal"
        }
    }
}

struct ClueScratchpadState: Codable, Equatable {
    var relations: [String: LedgerRelation] = [:]
    var eliminated: [Int] = []

    static func pairKey(_ a: Int, _ b: Int) -> String {
        let low = min(a, b)
        let high = max(a, b)
        return "\(low)-\(high)"
    }

    func relation(_ a: Int, _ b: Int) -> LedgerRelation? {
        guard a != b else { return nil }
        guard let stored = relations[Self.pairKey(a, b)] else { return nil }
        if a < b { return stored }
        switch stored {
        case .heavier: return .lighter
        case .lighter: return .heavier
        case .equal: return .equal
        }
    }

    mutating func setRelation(_ relation: LedgerRelation?, a: Int, b: Int) {
        guard a != b else { return }
        let key = Self.pairKey(a, b)
        guard let relation else {
            relations.removeValue(forKey: key)
            return
        }
        let normalized: LedgerRelation
        if a < b {
            normalized = relation
        } else {
            switch relation {
            case .heavier: normalized = .lighter
            case .lighter: normalized = .heavier
            case .equal: normalized = .equal
            }
        }
        relations[key] = normalized
    }
}

struct DraftSnapshot: Codable, Equatable {
    var panLeft: [Int]
    var panRight: [Int]
    var history: [FlockComparison]
    var movesRemaining: Int
    var ledger: ClueScratchpadState

    init(movesRemaining: Int) {
        self.panLeft = []
        self.panRight = []
        self.history = []
        self.movesRemaining = movesRemaining
        self.ledger = ClueScratchpadState()
    }
}

enum HenlingDraftVault {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func encodeHistory(_ history: [FlockComparison]) -> Data? {
        try? encoder.encode(history)
    }

    static func decodeHistory(_ data: Data?) -> [FlockComparison] {
        guard let data else { return [] }
        return (try? decoder.decode([FlockComparison].self, from: data)) ?? []
    }

    static func encodeLedger(_ ledger: ClueScratchpadState) -> Data? {
        try? encoder.encode(ledger)
    }

    static func decodeLedger(_ data: Data?) -> ClueScratchpadState {
        guard let data else { return ClueScratchpadState() }
        return (try? decoder.decode(ClueScratchpadState.self, from: data)) ?? ClueScratchpadState()
    }

    static func encodePan(_ pan: [Int]) -> String {
        pan.map(String.init).joined(separator: ",")
    }

    static func decodePan(_ text: String?) -> [Int] {
        guard let text, !text.isEmpty else { return [] }
        return text.split(separator: ",").compactMap { Int($0) }
    }
}
