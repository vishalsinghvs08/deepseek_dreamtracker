# DreamTracker

> *Write down what you want to achieve in 6 months, 1 year, 3 years, 5 years, and 10 years — then track every step until it's done.*

[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org)
[![Platform](https://img.shields.io/badge/iOS-17.0+-blue)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Build](https://img.shields.io/badge/build-passing-brightgreen)]()

**DreamTracker** is a premium iOS app that helps you define, track, and achieve long-term goals across five time horizons. Built with SwiftUI and designed with Apple's Human Interface Guidelines, it combines a unique Orbit Dial navigation system with glassmorphism aesthetics and planetary theming.

<p align="center">
  <img src="https://img.shields.io/badge/%F0%9F%94%A5-6M-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/%F0%9F%8D%83-1Y-teal?style=for-the-badge" />
  <img src="https://img.shields.io/badge/%F0%9F%8C%8D-3Y-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/%E2%9A%A1-5Y-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/%E2%AD%90-10Y-indigo?style=for-the-badge" />
</p>

---

## ✨ Features

### 🎛️ Orbit Dial Navigation
A physical-feeling rotating dial for switching between time horizons. Flick to spin with velocity-based inertia, spring-snap to detents, and haptic feedback at every tick. Labels stay upright while the ring rotates — no nauseating spinning text.

### 🌌 Cosmic Glassmorphism
Every surface uses Apple's `UltraThinMaterial` frosted glass effect floating over a deep-space nebula background. Three slowly drifting nebula clouds and 100 twinkling stars rendered on the GPU via Canvas. Zero performance cost.

### 🔀 Dream Decomposition
Long-term 5Y and 10Y dreams can be decomposed into cascading sub-dreams at shorter horizons. The cascade view shows parent → child relationships with branching lines and progressive indentation. AI-suggested sub-dreams at each level.

### 📅 Life Calendar Heatmap
A GitHub-style contribution graph showing your dream activity across weeks. Each cell is colored by dream horizon (terracotta, teal, blue, plum, indigo). Monthly timeline cards show which dreams were active each month with glassmorphism styling.

### ✍️ Dream Detail
New York serif typography for aspirational content. PhaseAnimator three-phase completion celebration with sparkle burst and heavy haptic feedback. Full edit mode with notes, horizon picker, and share-to-anywhere.

### 🏠 Animated Home Screen
Rotating inspirational quotes from Roosevelt, Jobs, Disney, and others. Cosmic nebula background with synchronized star animation. Tap anywhere or press "Enter" to proceed.

### 🧩 Widget
Home Screen widget showing your current focus dream and overall progress. Lock Screen circular widget with a progress ring.

### 🔒 Security-First
- **Face ID / Touch ID** required on launch with device passcode fallback
- **AES-256-GCM encryption** — all data encrypted with a device-specific key stored in the Keychain
- **Jailbreak detection** — app refuses to run on compromised devices
- **App Transport Security** — HTTPS enforced, HTTP blocked
- **App Attest** ready for server-side integrity verification
- **Privacy manifest** included — zero tracking, zero data collection

### 💰 Pro ($2.99 One-Time)
Free tier: 3 dreams per horizon (15 total). Pro unlocks unlimited dreams, iCloud sync, and widgets. No subscription. No ads. One purchase, forever.

---

## 🏗 Architecture

```
DreamTracker/
├── DreamTrackerApp.swift          — @MainActor app entry, jailbreak gate, RootView
├── Configuration/
│   ├── Info.plist                 — ATS hardened, Face ID description
│   ├── PrivacyInfo.xcprivacy      — Zero data collection manifest
│   ├── LaunchScreen.storyboard    — Branded launch screen
│   └── Secrets.swift              — Backend URL config
├── Model/
│   ├── DreamModels.swift          — Dream, JournalEntry, TimeHorizon (Codable)
│   └── DreamStore.swift           — AES-256-GCM encrypted persistence + App Group widget mirror
├── Store/
│   └── StoreManager.swift         — StoreKit 2, single $2.99 non-consumable product
├── Security/
│   ├── BiometricAuthenticator.swift — LocalAuthentication wrapper
│   ├── DeviceKeychain.swift       — 256-bit key generation + Keychain storage
│   ├── JailbreakDetector.swift    — File system integrity checks
│   ├── KeychainManager.swift      — Secure credential storage
│   └── SecurityError.swift        — Typed security error enum
├── Views/
│   ├── DreamsView.swift           — Main canvas with OrbitDial + glass cards
│   ├── OrbitDial.swift            — Velocity-based rotating dial component
│   ├── CosmicNebula.swift         — Shared GPU-rendered nebula background
│   ├── DreamDetailView.swift      — Serif typography, PhaseAnimator celebration
│   ├── DecomposeView.swift        — Cascade decomposition for 5Y/10Y dreams
│   ├── CalendarView.swift         — GitHub-style heatmap + monthly timeline
│   ├── HomeView.swift             — Animated quote rotation home screen
│   ├── JournalView.swift          — Distraction-free writing
│   └── LockView.swift             — Face ID unlock screen
└── Assets.xcassets/               — App icon (1024px gradient sparkle)

DreamTrackerWidget/
└── DreamTrackerWidget.swift       — Home Screen + Lock Screen widgets (App Group)
```

| Metric | Value |
|---|---|
| Swift files | 20 |
| Lines of code | ~3,900 |
| Minimum iOS | 17.0 |
| Dependencies | Zero (pure SwiftUI + StoreKit + CryptoKit) |
| Build time | ~15 seconds (M-series) |

---

## 🚀 Getting Started

```bash
# Clone
git clone https://github.com/vishalsinghvs08/deepseek_dreamtracker.git
cd deepseek_dreamtracker

# Open in Xcode
open DreamTracker.xcodeproj

# Build
xcodebuild -project DreamTracker.xcodeproj \
  -scheme DreamTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Press `Cmd+R` to run in simulator.

### Pro Features (StoreKit)
To test the Pro purchase flow:
1. Xcode → Scheme → Edit Scheme → Run → Options → StoreKit Configuration
2. Create a `.storekit` configuration file with product ID `com.dreamtracker.pro`
3. Set price to $2.99 (non-consumable)

---

## 📱 App Store Submission Checklist

- [x] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [x] App Transport Security (HTTPS only)
- [x] Entitlements (iCloud + App Groups)
- [x] Face ID usage description in Info.plist
- [x] Launch screen storyboard
- [x] App icon (1024px)
- [x] No private API usage
- [x] Localization foundation (`Localizable.strings` — 60+ strings)
- [x] Accessibility labels on key interactive elements
- [ ] App Store Connect listing (title, description, keywords)
- [ ] Screenshots (6.7" and 6.1")
- [ ] Create `com.dreamtracker.pro` IAP in App Store Connect
- [ ] Privacy policy URL (replace placeholder in rateApp())

---

## 🎨 Design System

| Element | Value |
|---|---|
| Background | Deep navy → purple → black gradient + nebula particles |
| Surface | `.ultraThinMaterial` frosted glass |
| Typography | SF Pro (UI) + New York serif (dream titles) |
| Color system | Planetary palette — terracotta, teal, blue, plum, indigo |
| Animations | Spring physics (response: 0.5-0.6, damping: 0.65-0.7) |
| Symbols | SF Symbols 5 with hierarchical rendering |

---

## 📄 License

MIT License — see [LICENSE](LICENSE) file.

---

<p align="center">
  <sub>Built with ❤️ for dreamers who build.</sub>
</p>
