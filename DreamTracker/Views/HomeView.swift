import SwiftUI

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var quoteIndex = 0
    @State private var quoteOpacity: Double = 0
    @State private var showEnter = false
    @State private var titleGlow = false
    @Namespace private var transition

    private let quotes: [(text: String, author: String)] = [
        ("The future belongs to those who believe in the beauty of their dreams.", "Eleanor Roosevelt"),
        ("Dream big and dare to fail.", "Norman Vaughan"),
        ("All our dreams can come true, if we have the courage to pursue them.", "Walt Disney"),
        ("It does not matter how slowly you go as long as you do not stop.", "Confucius"),
        ("The only limit to our realization of tomorrow is our doubts of today.", "Franklin D. Roosevelt"),
        ("What you get by achieving your goals is not as important as what you become.", "Henry David Thoreau"),
        ("Your time is limited, so don't waste it living someone else's life.", "Steve Jobs"),
        ("The best way to predict the future is to create it.", "Peter Drucker"),
        ("Don't watch the clock; do what it does. Keep going.", "Sam Levenson"),
        ("Small daily improvements over time lead to stunning results.", "Robin Sharma"),
    ]

    var body: some View {
        ZStack {
            // Cosmic background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.02, blue: 0.20),
                    Color(red: 0.08, green: 0.04, blue: 0.30),
                    Color(red: 0.02, green: 0.01, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated starfield
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let time = timeline.date.timeIntervalSince1970
                    for i in 0..<60 {
                        let seed = Double(i) * 7.3
                        let x = (sin(seed * 1.7 + time * 0.03) * 0.5 + 0.5) * size.width
                        let y = (cos(seed * 2.3 + time * 0.02) * 0.5 + 0.5) * size.height
                        let r = 1.0 + sin(seed + time * 0.8) * 0.5
                        let opacity = 0.3 + sin(time * 0.6 + seed) * 0.3
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                            with: .color(.white.opacity(opacity))
                        )
                    }
                }
            }
            .opacity(0.6)

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(Color.white)
                        .symbolRenderingMode(.hierarchical)
                        .scaleEffect(titleGlow ? 1.15 : 1.0)
                        .shadow(color: .white.opacity(titleGlow ? 0.4 : 0.1), radius: 20)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: titleGlow)

                    Text("DreamTracker")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .foregroundColor(Color.white)
                        .shadow(color: .white.opacity(0.3), radius: 10)
                }
                .padding(.bottom, 60)

                // Quote
                VStack(spacing: 16) {
                    Text("\"\(quotes[quoteIndex].text)\"")
                        .font(.system(.title2, design: .serif, weight: .light))
                        .foregroundColor(Color.white)
                        .italic()
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 32)
                        .opacity(quoteOpacity)
                        .shadow(color: .white.opacity(0.2), radius: 8)

                    Text("— \(quotes[quoteIndex].author)")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.60))
                        .opacity(quoteOpacity)
                }
                .matchedGeometryEffect(id: "quote", in: transition)

                Spacer()

                // Enter button
                if showEnter {
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            viewModel.showHomeScreen = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Enter")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.07))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            animateQuote()
            titleGlow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showEnter = true
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.5)) {
                viewModel.showHomeScreen = false
            }
        }
    }

    private func animateQuote() {
        withAnimation(.easeIn(duration: 0.8)) {
            quoteOpacity = 1.0
        }

        // Cycle quotes
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.4)) {
                quoteOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                quoteIndex = (quoteIndex + 1) % quotes.count
                withAnimation(.easeIn(duration: 0.8)) {
                    quoteOpacity = 1.0
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
        .preferredColorScheme(.dark)
}
