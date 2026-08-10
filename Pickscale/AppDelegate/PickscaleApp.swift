import SwiftUI
import CoreData

@main
struct PickscaleApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var vault: ProgressVault
    @StateObject private var prefs = RoostPreferences()
    @StateObject private var router = NestRouter()
    @StateObject private var overlay = OverlayOrchestrator()
    @StateObject private var stage = AppStageController()
    init() {
        let context = PersistenceController.shared.container.viewContext
        _vault = StateObject(wrappedValue: ProgressVault(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootStageView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(vault)
                .environmentObject(prefs)
                .environmentObject(router)
                .environmentObject(overlay)
                .environmentObject(stage)
                .statusBarHidden()
                .preferredColorScheme(.dark)
        }
    }
}
