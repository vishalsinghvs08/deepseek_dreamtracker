import SwiftUI

// MARK: - Surface Level

/// Three-level luminance stacking system for cosmic dark surfaces.
/// Defines how much white opacity lifts a surface off the cosmic background.
/// Inspired by Linear's surface elevation model (0.02 → 0.04 → 0.06).
public enum SurfaceLevel {
    /// 2% white — sits directly on the cosmic background. Use for page content,
    /// scroll containers, and the default card state.
    case base

    /// 4% white — elevated above base. Use for active/selected cards,
    /// section headers, and hover/pressed feedback.
    case elevated

    /// 6% white — floating above everything. Use for sheets, dialogs, popovers,
    /// and any surface that demands full attention.
    case floating

    /// Custom opacity for special cases (debug, transitions, one-offs).
    /// Prefer the named levels unless you have a specific reason.
    case custom(Double)

    public var opacity: Double {
        switch self {
        case .base:      return 0.02
        case .elevated:  return 0.04
        case .floating:  return 0.06
        case .custom(let v): return v
        }
    }

    /// The border opacity that pairs with this surface level.
    /// Borders follow the same luminance logic as surfaces —
    /// they whisper, never shout.
    public var borderOpacity: Double {
        switch self {
        case .base:      return 0.05
        case .elevated:  return 0.08
        case .floating:  return 0.10
        case .custom:    return 0.08
        }
    }
}

// MARK: - Cosmic Surface Modifier

/// Replaces `.ultraThinMaterial` with a precise luminance-stacking surface.
///
/// Use this on any container that sits above the cosmic background.
/// The surface scales its opacity and border based on the `SurfaceLevel`,
/// creating a clean elevation hierarchy without heavy shadows.
///
/// ```swift
/// // A card resting on the cosmic background
/// myView.cosmicSurface()
///
/// // An active/selected card lifted slightly
/// myView.cosmicSurface(level: .elevated)
///
/// // A sheet or dialog floating above everything
/// myView.cosmicSurface(level: .floating, radius: 20)
/// ```
public struct CosmicSurface: ViewModifier {
    let level: SurfaceLevel
    let radius: CGFloat

    public init(level: SurfaceLevel = .base, radius: CGFloat = 16) {
        self.level = level
        self.radius = radius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity(level.opacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(.white.opacity(level.borderOpacity), lineWidth: 0.5)
            )
    }
}

public extension View {
    /// Apply a cosmic luminance-stacking surface to the view.
    /// - Parameter level: How elevated the surface should be (default: `.base`).
    /// - Parameter radius: Corner radius for the surface (default: `16`).
    func cosmicSurface(level: SurfaceLevel = .base, radius: CGFloat = 16) -> some View {
        modifier(CosmicSurface(level: level, radius: radius))
    }
}

// MARK: - Planetary Colors

/// Returns the accent color for a given time horizon.
/// Refined planetary palette — warm, muted, cohesive.
/// This is the SINGLE source of chromatic color in the app.
public func planetaryColor(_ horizon: TimeHorizon) -> Color {
    switch horizon {
    case .sixMonths:  return Color(red: 0.88, green: 0.52, blue: 0.32) // Warm terracotta
    case .oneYear:    return Color(red: 0.32, green: 0.68, blue: 0.58) // Soft teal
    case .threeYears: return Color(red: 0.28, green: 0.55, blue: 0.82) // Calm blue
    case .fiveYears:  return Color(red: 0.55, green: 0.38, blue: 0.68) // Muted plum
    case .tenYears:   return Color(red: 0.42, green: 0.42, blue: 0.78) // Soft indigo
    }
}

/// Icon name for each horizon's planetary representation.
public func planetaryIcon(_ horizon: TimeHorizon) -> String {
    switch horizon {
    case .sixMonths:  return "flame"
    case .oneYear:    return "leaf"
    case .threeYears: return "globe.americas"
    case .fiveYears:  return "bolt"
    case .tenYears:   return "star"
    }
}

public func planetaryName(_ horizon: TimeHorizon) -> String {
    switch horizon {
    case .sixMonths:  return "Ignite"
    case .oneYear:    return "Grow"
    case .threeYears: return "Build"
    case .fiveYears:  return "Master"
    case .tenYears:   return "Legacy"
    }
}

// MARK: - Cosmic Gradient

/// The deep cosmic background gradient — navy → deep purple → black.
/// Use this as the root background for all dark sections.
public let cosmicGradient = LinearGradient(
    colors: [
        Color(red: 0.04, green: 0.04, blue: 0.18),
        Color(red: 0.08, green: 0.04, blue: 0.22),
        Color(red: 0.03, green: 0.02, blue: 0.12),
        Color.black,
    ],
    startPoint: .top,
    endPoint: .bottom
)

// MARK: - Typography System

/// Semantic font styles for DreamTracker.
/// Every text element in the app should use one of these cases —
/// no raw `.font(.system(...))` scattered through views.
///
/// ```swift
/// Text("Dream Canvas")
///     .dreamFont(.sectionTitle)
/// ```
public enum DreamFont {
    /// 48pt, weight 300 — hero headlines. Stripe-inspired light luxury.
    case displayHero
    /// 32pt, weight 300 — section titles.
    case sectionTitle
    /// 20pt, weight 510 — card titles (Linear's signature between-weight).
    case cardTitle
    /// 16pt, weight 400 — standard reading text.
    case body
    /// 15pt, weight 400 — secondary body text.
    case bodySmall
    /// 13pt, weight 400 — captions, metadata, timestamps.
    case caption
    /// 12pt, weight 510 — button labels, tab bar items.
    case label
    /// Monospaced digits for statistics and counts.
    case tabularNumber
}

public extension View {
    func dreamFont(_ style: DreamFont) -> some View {
        switch style {
        case .displayHero:
            return self.font(.system(size: 48, weight: .light))
        case .sectionTitle:
            return self.font(.system(size: 32, weight: .light))
        case .cardTitle:
            return self.font(.system(size: 20, weight: .medium)) // 510 equivalent
        case .body:
            return self.font(.system(size: 16, weight: .regular))
        case .bodySmall:
            return self.font(.system(size: 15, weight: .regular))
        case .caption:
            return self.font(.system(size: 13, weight: .regular))
        case .label:
            return self.font(.system(size: 12, weight: .medium))
        case .tabularNumber:
            return self.font(.system(size: 16, weight: .regular, design: .monospaced))
        }
    }
}
