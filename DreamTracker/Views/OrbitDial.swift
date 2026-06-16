import SwiftUI

// MARK: - Orbit Dial

/// A physical-feeling rotating dial for switching time horizons.
/// Like an iPod click wheel or camera aperture ring — drag to rotate,
/// detents snap at each horizon with haptic feedback.
struct OrbitDial: View {
    @Binding var activeHorizon: TimeHorizon
    let horizons: [TimeHorizon] = TimeHorizon.allCases

    @State private var rotation: Double = 0
    @State private var dragStartAngle: Double = 0
    @State private var lastFeedbackIndex: Int = 1 // Default to 1Y
    @State private var isPulsing: Bool = false

    private let dialSize: CGFloat = 220
    private let segmentAngle: Double = 360.0 / 5.0 // 72° per horizon

    var body: some View {
        ZStack {
            // ── Rotating outer ring & tick marks ──
            Group {
                // Outer ring — frosted glass with angular gradient trim
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: dialSize, height: dialSize)
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)

                // Angular gradient ring using planetaryColor + white accents
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                planetaryColor(activeHorizon).opacity(0.9),
                                .white.opacity(0.7),
                                planetaryColor(activeHorizon).opacity(0.6),
                                .white.opacity(0.7),
                                planetaryColor(activeHorizon).opacity(0.9)
                            ],
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: dialSize - 4, height: dialSize - 4)
                    .blur(radius: 1)

                // Inner accent ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.05), .white.opacity(0.5)],
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: dialSize - 4, height: dialSize - 4)

                // Tick marks — rotate with dial
                ForEach(Array(horizons.enumerated()), id: \.element.id) { index, horizon in
                    let angle = segmentAngle * Double(index) - 90 // Start from top
                    let isActive = horizon == activeHorizon

                    Capsule()
                        .fill(isActive ? .white : .white.opacity(0.3))
                        .frame(width: isActive ? 3 : 1.5, height: isActive ? 18 : 12)
                        .offset(y: -(dialSize / 2 - 28))
                        .rotationEffect(.degrees(angle))
                }
            }
            .rotationEffect(.degrees(rotation))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: rotation)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: activeHorizon)

            // ── Fixed upright labels ──
            ForEach(Array(horizons.enumerated()), id: \.element.id) { index, horizon in
                let angle = segmentAngle * Double(index) - 90
                let rad = Angle.degrees(angle).radians
                let labelRadius = dialSize / 2 - 52
                let x = labelRadius * cos(rad)
                let y = labelRadius * sin(rad)
                let isActive = horizon == activeHorizon

                Text(horizon.shortLabel)
                    .font(.system(size: isActive ? 13 : 10, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? .white : .white.opacity(0.5))
                    .position(x: dialSize / 2 + x, y: dialSize / 2 + y)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: activeHorizon)
            }

            // ── Center display ──
            VStack(spacing: 6) {
                ZStack {
                    // Pulsing glow ring behind icon
                    Circle()
                        .stroke(planetaryColor(activeHorizon).opacity(0.6), lineWidth: 2)
                        .frame(width: 56, height: 56)
                        .scaleEffect(isPulsing ? 1.25 : 1.0)
                        .opacity(isPulsing ? 0.3 : 0.7)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                            value: isPulsing
                        )

                    // Large SF Symbol
                    Image(systemName: planetaryIcon(activeHorizon))
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce, value: activeHorizon)
                }

                Text(planetaryName(activeHorizon))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 120, height: 120)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
        .frame(width: dialSize, height: dialSize)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let center = CGPoint(x: dialSize / 2, y: dialSize / 2)
                    let startVector = CGPoint(x: value.startLocation.x - center.x,
                                               y: value.startLocation.y - center.y)
                    let currentVector = CGPoint(x: value.location.x - center.x,
                                                 y: value.location.y - center.y)

                    let startAngle = atan2(startVector.y, startVector.x) * 180 / .pi
                    let currentAngle = atan2(currentVector.y, currentVector.x) * 180 / .pi

                    var delta = currentAngle - startAngle
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }

                    rotation = delta

                    // Calculate which horizon we're closest to
                    let normalizedRotation = rotation.truncatingRemainder(dividingBy: 360)
                    var index = Int(round(normalizedRotation / segmentAngle))
                    if index < 0 { index += 5 }
                    index = index % 5

                    if index != lastFeedbackIndex {
                        let gen = UIImpactFeedbackGenerator(style: .light)
                        gen.impactOccurred()
                        lastFeedbackIndex = index
                    }
                }
                .onEnded { _ in
                    let normalized = rotation.truncatingRemainder(dividingBy: 360)
                    var index = Int(round(normalized / segmentAngle))
                    if index < 0 { index += 5 }
                    index = index % 5

                    let snapped = segmentAngle * Double(index)

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        rotation = snapped
                        activeHorizon = horizons[index]
                    }

                    let gen = UIImpactFeedbackGenerator(style: .heavy)
                    gen.impactOccurred()
                }
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Planetary theme

func planetaryColor(_ horizon: TimeHorizon) -> Color {
    switch horizon {
    case .sixMonths:  return Color(red: 0.95, green: 0.55, blue: 0.25) // Mercury — warm amber
    case .oneYear:    return Color(red: 0.25, green: 0.75, blue: 0.55) // Venus — teal growth
    case .threeYears: return Color(red: 0.15, green: 0.55, blue: 0.85) // Earth — deep blue
    case .fiveYears:  return Color(red: 0.65, green: 0.30, blue: 0.55) // Mars — ambition
    case .tenYears:   return Color(red: 0.35, green: 0.30, blue: 0.75) // Jupiter — indigo
    }
}

func planetaryIcon(_ horizon: TimeHorizon) -> String {
    switch horizon {
    case .sixMonths:  return "flame"
    case .oneYear:    return "leaf"
    case .threeYears: return "globe.americas"
    case .fiveYears:  return "bolt"
    case .tenYears:   return "star"
    }
}

func planetaryName(_ horizon: TimeHorizon) -> String {
    switch horizon {
    case .sixMonths:  return "Ignite"
    case .oneYear:    return "Grow"
    case .threeYears: return "Build"
    case .fiveYears:  return "Master"
    case .tenYears:   return "Legacy"
    }
}

// For backward compat with existing horizonColor calls
func horizonColor(_ horizon: TimeHorizon) -> Color {
    planetaryColor(horizon)
}

// MARK: - Preview

#Preview {
    @Previewable @State var horizon: TimeHorizon = .oneYear
    return ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        OrbitDial(activeHorizon: $horizon)
    }
}
