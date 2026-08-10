import SwiftUI

struct YardBackdrop: View {
    var body: some View {
        Image("bg_main_menu")
            .resizable()
            .ignoresSafeArea()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.black.opacity(0.28)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

enum RusticButtonKind {
    case primary
    case secondary
    case destructive

    var asset: String {
        switch self {
        case .primary: return "button_primary"
        case .secondary: return "button_secondary"
        case .destructive: return "button_destructive"
        }
    }

    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return RoostPalette.barkDark
        case .destructive: return RoostPalette.cream
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary: return RoostPalette.barkDark
        case .secondary: return RoostPalette.parchment.opacity(0.7)
        case .destructive: return RoostPalette.dusk
        }
    }
}

struct RusticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct RusticButton: View {
    let title: String
    var kind: RusticButtonKind = .primary
    var systemIcon: String?
    var height: CGFloat = 68
    var fontSize: CGFloat = 27
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            action()
        } label: {
            ZStack {
                Image(kind.asset)
                    .resizable(
                        capInsets: EdgeInsets(top: 0, leading: 56, bottom: 0, trailing: 56),
                        resizingMode: .stretch
                    )
                    .frame(height: height)
                HStack(spacing: 10) {
                    if let systemIcon {
                        Image(systemName: systemIcon)
                            .font(.system(size: fontSize * 0.7, weight: .bold))
                    }
                    Text(title)
                        .font(RoostFont.bold(fontSize))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .foregroundStyle(kind.textColor)
                .shadow(color: kind.shadowColor.opacity(0.6), radius: 1, x: 0, y: 1)
                .padding(.horizontal, 42)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .opacity(enabled ? 1.0 : 0.55)
        }
        .buttonStyle(RusticButtonStyle())
        .disabled(!enabled)
    }
}

struct NestBackButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            HapticPulse.tap()
            AppAudioConductor.shared.play(.tap)
            action()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(RoostPalette.cream)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(RoostPalette.bark)
                        .overlay(Circle().stroke(RoostPalette.barkDark, lineWidth: 3))
                        .shadow(color: RoostPalette.dusk.opacity(0.5), radius: 3, x: 0, y: 2)
                )
        }
        .buttonStyle(RusticButtonStyle())
        .accessibilityLabel("Back")
    }
}

struct StarStrip: View {
    let filled: Int
    var total: Int = 3
    var size: CGFloat = 26

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Image(index < filled ? "star_filled" : "star_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
    }
}

struct ParchmentPanel<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(RoostPalette.cream.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(RoostPalette.bark, lineWidth: 4)
                    )
                    .shadow(color: RoostPalette.dusk.opacity(0.35), radius: 8, x: 0, y: 4)
            )
    }
}

struct ScreenTitle: View {
    let text: String
    var size: CGFloat = 40

    var body: some View {
        Text(text)
            .font(RoostFont.bold(size))
            .foregroundStyle(RoostPalette.cream)
            .shadow(color: RoostPalette.dusk.opacity(0.8), radius: 2, x: 0, y: 2)
    }
}

struct HenPortrait: View {
    let index: Int
    var size: CGFloat = 64
    var showsLetter: Bool = true

    var body: some View {
        Image(HenGlyph.asset(for: index))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        YardBackdrop()
        VStack(spacing: 16) {
            ScreenTitle(text: "Pickscale")
            RusticButton(title: "Play Campaign") {}
            RusticButton(title: "Settings", kind: .secondary) {}
            RusticButton(title: "Reset", kind: .destructive) {}
            StarStrip(filled: 2)
            ParchmentPanel { Text("Parchment").font(RoostFont.medium(22)) }
            HenPortrait(index: 0)
        }
        .padding()
    }
}
