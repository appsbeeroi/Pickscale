import SwiftUI

private struct OnboardingChapter {
    let title: String
    let illustration: String
    let body: String
    let cta: String
}

struct FledglingOnboardingView: View {
    let onComplete: () -> Void

    @State private var pageIndex = 0

    private let chapters: [OnboardingChapter] = [
        OnboardingChapter(
            title: "Read the Scales",
            illustration: "onboarding_scales",
            body: "Place hens on the left or right pan, then weigh. The scale only tells you which side is heavier or if both sides match.",
            cta: "Continue"
        ),
        OnboardingChapter(
            title: "Build Your Case",
            illustration: "onboarding_clue_board",
            body: "Use the Clue Ledger to mark what you know and rule out what cannot be true. Plan each weighing before you spend a move.",
            cta: "Continue"
        ),
        OnboardingChapter(
            title: "Solve and Earn Stars",
            illustration: "onboarding_tasks",
            body: "Each puzzle has a move limit. Submit your answer on the Answer Board when your deductions are ready. Fewer weighings mean more stars.",
            cta: "Get Started"
        )
    ]

    var body: some View {
        ZStack {
            YardBackdrop()

            VStack(spacing: 18) {
                topBar

                let chapter = chapters[pageIndex]

                ScreenTitle(text: chapter.title, size: 38)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                Image(chapter.illustration)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320, maxHeight: 320)
                    .shadow(color: RoostPalette.dusk.opacity(0.4), radius: 8, x: 0, y: 4)
                    .id(chapter.illustration)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))

                ParchmentPanel {
                    Text(chapter.body)
                        .font(RoostFont.medium(21))
                        .foregroundStyle(RoostPalette.barkDark)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)

                Spacer(minLength: 0)

                Text("\(pageIndex + 1) of \(chapters.count)")
                    .font(RoostFont.semibold(20))
                    .foregroundStyle(RoostPalette.cream)
                    .shadow(color: RoostPalette.dusk.opacity(0.7), radius: 1, x: 0, y: 1)

                pageDots

                RusticButton(title: chapter.cta) {
                    advance()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
            .padding()
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: pageIndex)
        }
    }

    private var topBar: some View {
        HStack {
            if pageIndex > 0 {
                NestBackButton { retreat() }
            } else {
                Color.clear.frame(width: 48, height: 48)
            }
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<chapters.count, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? RoostPalette.sunAmber : RoostPalette.cream.opacity(0.5))
                    .frame(width: index == pageIndex ? 26 : 10, height: 10)
            }
        }
    }

    private func advance() {
        if pageIndex < chapters.count - 1 {
            withAnimation { pageIndex += 1 }
        } else {
            onComplete()
        }
    }

    private func retreat() {
        guard pageIndex > 0 else { return }
        withAnimation { pageIndex -= 1 }
    }
}

#Preview {
    FledglingOnboardingView {}
}
