import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let sample = LevelRecord(context: viewContext)
        sample.levelKey = "hatchling_run-1"
        sample.isSolved = true
        sample.starsEarned = 3
        sample.bestWeighingsUsed = 2
        sample.lastPlayedAt = Date()
        try? viewContext.save()
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Pickscale")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        loadStores(recoverOnFailure: !inMemory)

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    private func loadStores(recoverOnFailure: Bool) {
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        guard loadError != nil, recoverOnFailure else { return }

        for description in container.persistentStoreDescriptions {
            if let url = description.url {
                try? container.persistentStoreCoordinator.destroyPersistentStore(
                    at: url,
                    ofType: description.type,
                    options: nil
                )
            }
        }

        var retryError: Error?
        container.loadPersistentStores { _, error in
            retryError = error
        }

        if retryError != nil {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            container.loadPersistentStores { _, _ in }
        }
    }
}
