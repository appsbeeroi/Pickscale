import SwiftUI
import Combine

@MainActor
final class PeckOrderAnswerMatrix: ObservableObject {
    let level: FlockLevel

    @Published var heaviestSelection: Int?
    @Published var oddbirdSelection: Int?
    @Published var orderedLine: [Int]
    @Published var pool: [Int]

    init(level: FlockLevel) {
        self.level = level
        self.heaviestSelection = nil
        self.oddbirdSelection = nil
        self.orderedLine = []
        self.pool = Array(0..<level.birdCount)
    }

    func selectHeaviest(_ index: Int) {
        heaviestSelection = index
    }

    func selectOddbird(_ index: Int) {
        oddbirdSelection = index
    }

    func placeIntoLine(_ index: Int) {
        guard let poolIndex = pool.firstIndex(of: index) else { return }
        pool.remove(at: poolIndex)
        orderedLine.append(index)
    }

    func removeFromLine(_ index: Int) {
        guard let lineIndex = orderedLine.firstIndex(of: index) else { return }
        orderedLine.remove(at: lineIndex)
        pool.append(index)
        pool.sort()
    }

    func moveInLine(from source: IndexSet, to destination: Int) {
        orderedLine.move(fromOffsets: source, toOffset: destination)
    }

    var isSubmittable: Bool {
        switch level.task {
        case .heaviestHen:
            return heaviestSelection != nil
        case .lightOddbird:
            return oddbirdSelection != nil
        case .fullPeckOrder:
            return orderedLine.count == level.birdCount
        }
    }

    func evaluate(with engine: FlockmassPuzzleEngine) -> Bool {
        switch level.task {
        case .heaviestHen:
            return engine.validate(heaviest: heaviestSelection)
        case .lightOddbird:
            return engine.validate(oddbird: oddbirdSelection)
        case .fullPeckOrder:
            return engine.validate(order: orderedLine)
        }
    }
}
