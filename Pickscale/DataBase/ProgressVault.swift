import CoreData
import SwiftUI
import Combine

@MainActor
final class ProgressVault: ObservableObject {
    private let context: NSManagedObjectContext
    private let lastPlayedKeyDefaults = "pickscale.lastPlayedLevelKey"

    @Published private(set) var revision: Int = 0

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    private func bumpRevision() {
        revision &+= 1
    }

    private func persist() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func fetchRecord(_ key: String) -> LevelRecord? {
        let request = NSFetchRequest<LevelRecord>(entityName: "LevelRecord")
        request.predicate = NSPredicate(format: "levelKey == %@", key)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func allRecords() -> [LevelRecord] {
        let request = NSFetchRequest<LevelRecord>(entityName: "LevelRecord")
        return (try? context.fetch(request)) ?? []
    }

    func record(forKey key: String) -> (isSolved: Bool, stars: Int, bestWeighings: Int, lastPlayed: Date?) {
        guard let record = fetchRecord(key) else {
            return (false, 0, 0, nil)
        }
        return (record.isSolved, Int(record.starsEarned), Int(record.bestWeighingsUsed), record.lastPlayedAt)
    }

    func stars(forKey key: String) -> Int {
        Int(fetchRecord(key)?.starsEarned ?? 0)
    }

    func isSolved(_ key: String) -> Bool {
        fetchRecord(key)?.isSolved ?? false
    }

    var totalStars: Int {
        allRecords().reduce(0) { $0 + Int($1.starsEarned) }
    }

    var solvedCount: Int {
        allRecords().filter { $0.isSolved }.count
    }

    func solvedCount(inPack packId: String) -> Int {
        let keys = Set(OddbirdDeductionRulebook.levels(in: packId).map { $0.key })
        return allRecords().filter { record in
            guard let key = record.levelKey else { return false }
            return record.isSolved && keys.contains(key)
        }.count
    }

    func stars(inPack packId: String) -> Int {
        let keys = Set(OddbirdDeductionRulebook.levels(in: packId).map { $0.key })
        return allRecords().reduce(0) { partial, record in
            guard let key = record.levelKey, keys.contains(key) else { return partial }
            return partial + Int(record.starsEarned)
        }
    }

    func isPackUnlocked(_ packId: String) -> Bool {
        guard let pack = OddbirdDeductionRulebook.pack(for: packId) else { return false }
        if pack.order == 0 { return true }
        guard let previous = OddbirdDeductionRulebook.packs.first(where: { $0.order == pack.order - 1 }) else {
            return false
        }
        return solvedCount(inPack: previous.id) >= OddbirdDeductionRulebook.unlockThreshold
    }

    @discardableResult
    func registerSolve(level: FlockLevel, weighingsUsed: Int, stars: Int) -> Bool {
        let record = fetchRecord(level.key) ?? LevelRecord(context: context)
        if record.levelKey == nil {
            record.levelKey = level.key
        }
        var improvedBest = false
        let previousBest = Int(record.bestWeighingsUsed)
        if !record.isSolved || weighingsUsed < previousBest || previousBest == 0 {
            if !record.isSolved || weighingsUsed < previousBest {
                improvedBest = record.isSolved
            }
            record.bestWeighingsUsed = Int16(weighingsUsed)
        }
        if stars > Int(record.starsEarned) {
            record.starsEarned = Int16(stars)
        }
        record.isSolved = true
        record.lastPlayedAt = Date()
        persist()
        bumpRevision()
        return improvedBest
    }

    func touchLastPlayed(_ level: FlockLevel) {
        let record = fetchRecord(level.key) ?? LevelRecord(context: context)
        if record.levelKey == nil { record.levelKey = level.key }
        record.lastPlayedAt = Date()
        persist()
        lastPlayedLevelKey = level.key
        bumpRevision()
    }

    var lastPlayedLevelKey: String? {
        get { UserDefaults.standard.string(forKey: lastPlayedKeyDefaults) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: lastPlayedKeyDefaults)
            } else {
                UserDefaults.standard.removeObject(forKey: lastPlayedKeyDefaults)
            }
        }
    }

    var lastSolvedLevel: FlockLevel? {
        let solved = allRecords()
            .filter { $0.isSolved && $0.lastPlayedAt != nil }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        for record in solved {
            if let key = record.levelKey, let level = OddbirdDeductionRulebook.level(forKey: key) {
                return level
            }
        }
        return nil
    }

    private func fetchDraft(_ key: String) -> LevelDraft? {
        let request = NSFetchRequest<LevelDraft>(entityName: "LevelDraft")
        request.predicate = NSPredicate(format: "levelKey == %@", key)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    func loadDraft(forKey key: String) -> DraftSnapshot? {
        guard let draft = fetchDraft(key) else { return nil }
        var snapshot = DraftSnapshot(movesRemaining: Int(draft.movesRemaining))
        snapshot.panLeft = HenlingDraftVault.decodePan(draft.panLeft)
        snapshot.panRight = HenlingDraftVault.decodePan(draft.panRight)
        snapshot.history = HenlingDraftVault.decodeHistory(draft.weighHistoryBlob)
        snapshot.ledger = HenlingDraftVault.decodeLedger(draft.ledgerBlob)
        return snapshot
    }

    func saveDraft(_ snapshot: DraftSnapshot, forKey key: String) {
        let draft = fetchDraft(key) ?? LevelDraft(context: context)
        if draft.levelKey == nil { draft.levelKey = key }
        draft.panLeft = HenlingDraftVault.encodePan(snapshot.panLeft)
        draft.panRight = HenlingDraftVault.encodePan(snapshot.panRight)
        draft.weighHistoryBlob = HenlingDraftVault.encodeHistory(snapshot.history)
        draft.ledgerBlob = HenlingDraftVault.encodeLedger(snapshot.ledger)
        draft.movesRemaining = Int16(snapshot.movesRemaining)
        draft.updatedAt = Date()
        persist()
    }

    func discardDraft(forKey key: String) {
        guard let draft = fetchDraft(key) else { return }
        context.delete(draft)
        persist()
    }

    func hasDraft(forKey key: String) -> Bool {
        fetchDraft(key) != nil
    }

    func resetEverything() {
        for record in allRecords() { context.delete(record) }
        let draftRequest = NSFetchRequest<LevelDraft>(entityName: "LevelDraft")
        if let drafts = try? context.fetch(draftRequest) {
            for draft in drafts { context.delete(draft) }
        }
        persist()
        lastPlayedLevelKey = nil
        bumpRevision()
    }
}
