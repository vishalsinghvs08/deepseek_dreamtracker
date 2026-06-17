import SwiftUI

// MARK: - Cosmic Nebula Background (shared component)

/// A slow, soothing animated space background with drifting nebula clouds and twinkling stars.
/// Drop into any view as the bottom layer with `.ignoresSafeArea()`.
struct CosmicNebula: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince1970

            Canvas { context, size in
                // ── Nebula blobs (slow drifting color clouds) ──
                let blobs: [(x: Double, y: Double, r: Double, color: Color, speed: Double)] = [
                    (0.3, 0.25, 280, Color(red: 0.15, green: 0.08, blue: 0.35), 0.008),
                    (0.7, 0.60, 240, Color(red: 0.08, green: 0.06, blue: 0.28), 0.006),
                    (0.5, 0.40, 320, Color(red: 0.10, green: 0.05, blue: 0.22), 0.007),
                ]

                for blob in blobs {
                    let dx = sin(time * blob.speed + blob.x * 5) * 40
                    let dy = cos(time * blob.speed * 0.7 + blob.y * 5) * 30
                    let cx = blob.x * size.width + dx
                    let cy = blob.y * size.height + dy

                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: cx - blob.r, y: cy - blob.r,
                            width: blob.r * 2, height: blob.r * 2
                        )),
                        with: .radialGradient(
                            Gradient(colors: [blob.color.opacity(0.6), blob.color.opacity(0)]),
                            center: .init(x: cx, y: cy),
                            startRadius: 0, endRadius: blob.r
                        )
                    )
                }

                // ── Twinkling stars ──
                for i in 0..<100 {
                    let seed = Double(i) * 17.3
                    let x = (sin(seed * 1.7 + time * 0.012) * 0.5 + 0.5) * size.width
                    let y = (cos(seed * 2.1 + time * 0.009) * 0.5 + 0.5) * size.height
                    let r = 0.6 + sin(seed + time * 0.7) * 0.3
                    let brightness = 0.15 + sin(time * 0.5 + seed) * 0.12
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                        with: .color(.white.opacity(max(0, brightness)))
                    )
                }
            }
        }
    }
}
