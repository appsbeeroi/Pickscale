import SwiftUI

struct ConfirmOverlayCard: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    var confirmKind: RusticButtonKind = .primary
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ParchmentPanel(padding: 22) {
            VStack(spacing: 16) {
                Text(title)
                    .font(RoostFont.bold(28))
                    .foregroundStyle(RoostPalette.barkDark)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(RoostFont.medium(19))
                    .foregroundStyle(RoostPalette.bark)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    RusticButton(title: confirmTitle, kind: confirmKind, height: 60, fontSize: 22) {
                        onConfirm()
                    }
                    RusticButton(title: cancelTitle, kind: .secondary, height: 56, fontSize: 20) {
                        onCancel()
                    }
                }
            }
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 30)
    }
}

struct MessageOverlayCard: View {
    let title: String
    let message: String
    var imageAsset: String?
    var buttonTitle: String = "OK"
    let onDismiss: () -> Void

    var body: some View {
        ParchmentPanel(padding: 22) {
            VStack(spacing: 16) {
                if let imageAsset {
                    Image(imageAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                }
                Text(title)
                    .font(RoostFont.bold(28))
                    .foregroundStyle(RoostPalette.barkDark)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(RoostFont.medium(19))
                    .foregroundStyle(RoostPalette.bark)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                RusticButton(title: buttonTitle, kind: .primary, height: 58, fontSize: 22) {
                    onDismiss()
                }
            }
        }
        .frame(maxWidth: 340)
        .padding(.horizontal, 30)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        ConfirmOverlayCard(
            title: "Reset notes?",
            message: "This clears only your manual ledger marks.",
            confirmTitle: "Reset",
            cancelTitle: "Keep notes",
            confirmKind: .destructive,
            onConfirm: {},
            onCancel: {}
        )
    }
}
