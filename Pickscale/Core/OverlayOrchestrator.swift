import SwiftUI
import Combine

struct OverlayCard: Identifiable {
    let id = UUID()
    let dismissOnBackdrop: Bool
    let content: AnyView
}

@MainActor
final class OverlayOrchestrator: ObservableObject {
    @Published private(set) var active: OverlayCard?

    func present<Content: View>(dismissOnBackdrop: Bool = true, @ViewBuilder content: () -> Content) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            active = OverlayCard(dismissOnBackdrop: dismissOnBackdrop, content: AnyView(content()))
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            active = nil
        }
    }
}

struct OverlayHostLayer: View {
    @ObservedObject var orchestrator: OverlayOrchestrator

    var body: some View {
        ZStack {
            if let card = orchestrator.active {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        if card.dismissOnBackdrop { orchestrator.dismiss() }
                    }

                card.content
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .id(card.id)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: orchestrator.active?.id)
    }
}
