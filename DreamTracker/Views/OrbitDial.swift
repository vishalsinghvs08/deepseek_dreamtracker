import SwiftUI

// MARK: - Orbit Dial (velocity-based, smooth physics)

struct OrbitDial: View {
    @Binding var activeHorizon: TimeHorizon
    let horizons: [TimeHorizon] = TimeHorizon.allCases

    // Continuous accumulated rotation — never resets
    @State private var accumulatedRotation: Double = 0
    @State private var dragVelocity: Double = 0
    @State private var lastDragAngle: Double = 0
    @State private var lastDragTime: Date = .now
    @State private var isDragging = false
    @State private var lastSnapIndex: Int = 1
    @State private var isPulsing = false

    private let dialSize: CGFloat = 220
    private let segmentAngle: Double = 360.0 / 5.0

    /// Current rotation including any active spring animation
    private var displayRotation: Double { accumulatedRotation }

    var body: some View {
        ZStack {
            // ── Rotating ring + ticks ──
            Group {
                Circle()
                    .cosmicSurface(level: .floating, radius: dialSize / 2)
                    .frame(width: dialSize, height: dialSize)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.05), .white.opacity(0.4)],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .frame(width: dialSize - 4, height: dialSize - 4)

                // Tick marks
                ForEach(Array(horizons.enumerated()), id: \.element.id) { index, horizon in
                    let angle = segmentAngle * Double(index) - 90
                    let isActive = horizon == activeHorizon
                    Capsule()
                        .fill(isActive ? planetaryColor(activeHorizon) : .white.opacity(0.25))
                        .frame(width: isActive ? 2.5 : 1.2, height: isActive ? 16 : 10)
                        .offset(y: -(dialSize / 2 - 26))
                        .rotationEffect(.degrees(angle))
                }
            }
            .rotationEffect(.degrees(displayRotation))
            .animation(isDragging ? nil : .spring(response: 0.6, dampingFraction: 0.65), value: accumulatedRotation)

            // ── Fixed upright labels ──
            ForEach(Array(horizons.enumerated()), id: \.element.id) { index, horizon in
                let angle = segmentAngle * Double(index) - 90
                let rad = Angle.degrees(angle).radians
                let r = dialSize / 2 - 50
                let isActive = horizon == activeHorizon

                Text(horizon.shortLabel)
                    .font(.system(size: isActive ? 13 : 10, weight: isActive ? .bold : .medium))
                    .foregroundColor(isActive ? planetaryColor(horizon) : .white.opacity(0.45))
                    .position(x: dialSize / 2 + r * cos(rad), y: dialSize / 2 + r * sin(rad))
            }

            // ── Center display ──
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(planetaryColor(activeHorizon).opacity(0.5), lineWidth: 2)
                        .frame(width: 52, height: 52)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.2 : 0.6)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)

                    Image(systemName: planetaryIcon(activeHorizon))
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(planetaryColor(activeHorizon))
                        .symbolRenderingMode(.hierarchical)
                }
                Text(planetaryName(activeHorizon))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.white)
            }
            .frame(width: 110, height: 110)
            .cosmicSurface(level: .elevated, radius: 55)
        }
        .frame(width: dialSize, height: dialSize)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        lastDragAngle = 0
                        lastDragTime = .now
                    }

                    let center = CGPoint(x: dialSize / 2, y: dialSize / 2)
                    let v = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
                    let angle = atan2(v.y, v.x) * 180 / .pi

                    if lastDragAngle != 0 {
                        var delta = angle - lastDragAngle
                        if delta > 180 { delta -= 360 }
                        if delta < -180 { delta += 360 }
                        accumulatedRotation += delta

                        // Track velocity
                        let now = Date()
                        let dt = now.timeIntervalSince(lastDragTime)
                        if dt > 0.001 {
                            dragVelocity = delta / dt
                        }
                        lastDragTime = now
                    }

                    lastDragAngle = angle

                    // Haptic detent
                    let norm = accumulatedRotation.truncatingRemainder(dividingBy: 360)
                    var idx = Int(round(norm / segmentAngle))
                    if idx < 0 { idx += 5 }
                    idx = idx % 5
                    if idx != lastSnapIndex {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    lastSnapIndex = idx
                }
                .onEnded { _ in
                    isDragging = false

                    // Apply inertia — rotate with velocity, then snap
                    let inertiaAngle = dragVelocity * 0.15
                    let target = accumulatedRotation + inertiaAngle

                    let norm = target.truncatingRemainder(dividingBy: 360)
                    var idx = Int(round(norm / segmentAngle))
                    if idx < 0 { idx += 5 }
                    idx = idx % 5
                    let snapped = accumulatedRotation - norm + segmentAngle * Double(idx)
                    // Ensure we snap to closest, not just any
                    var bestSnap = snapped
                    for offset in [-5, 0, 5] {
                        let candidate = accumulatedRotation - norm + segmentAngle * Double(idx + offset)
                        if abs(candidate - target) < abs(bestSnap - target) {
                            bestSnap = candidate
                        }
                    }

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                        accumulatedRotation = bestSnap
                    }
                    activeHorizon = horizons[idx]
                    dragVelocity = 0
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
        )
        .onAppear {
            isPulsing = true
            // Set initial rotation to match activeHorizon
            if let idx = horizons.firstIndex(of: activeHorizon) {
                accumulatedRotation = segmentAngle * Double(idx)
                lastSnapIndex = idx
            }
        }
    }
}

#Preview {
    @Previewable @State var horizon: TimeHorizon = .oneYear
    return ZStack {
        Color(red: 0.05, green: 0.02, blue: 0.18).ignoresSafeArea()
        OrbitDial(activeHorizon: $horizon)
    }
}
