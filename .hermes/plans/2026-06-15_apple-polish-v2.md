# DreamTracker — App Store Readiness & Premium Apple Polish

> **For Hermes:** Execute in order. Build + verify after each phase. No phase touches code the next depends on until the prior is green.

**Goal:** Transform the current functional prototype into a deployment-ready iOS app with genuine Apple-level interaction design, App Store security compliance, and a simple monetization model. The app must feel *crafted*, not generic.

**Target:** iOS 17.0+ (unlocks TipKit, PhaseAnimator, SymbolEffect, scrollTransition, widget)

**Monetization:** Free app → single $2.99 one-time "DreamTracker Pro" purchase (iCloud sync + unlimited dreams + widgets). Free tier: 3 dreams per horizon (15 total). No subscription.

---

## Phase 0 — App Store Foundation (these MUST ship before anything else)

### Task 0.1: Privacy Manifest
**File:** `DreamTracker/Configuration/PrivacyInfo.xcprivacy`

Apple requires this for all new apps. Declare:
- `NSPrivacyAccessedAPICategoryFileTimestamp` — we access file creation dates on dream entries
- `NSPrivacyAccessedAPICategoryUserDefaults` — we store Face ID preference
- `NSPrivacyAccessedAPICategorySystemBootTime` — not used → omit
- `NSPrivacyCollectedDataTypes` — we collect NO data. No analytics, no tracking, no identifiers.

### Task 0.2: Entitlements file
**File:** Create `DreamTracker/DreamTracker.entitlements`

```xml
<key>com.apple.developer.icloud-services</key>
<string>CloudKit</string>
<key>com.apple.security.application-groups</key>
<string>group.com.dreamtracker.app</string>
```

For iCloud sync (Pro feature) and widget communication.

### Task 0.3: App Transport Security hardening
**File:** `DreamTracker/Configuration/Info.plist`

Add:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

Block all non-HTTPS traffic. The app currently has no network calls, but this guarantees future safety.

### Task 0.4: Bump deployment target to iOS 17
**File:** `DreamTracker.xcodeproj/project.pbxproj`

Change `IPHONEOS_DEPLOYMENT_TARGET` from `16.0` to `17.0` in both Debug and Release configs (lines 523 and 574). This unlocks iOS 17 APIs.

---

## Phase 1 — Truly Apple Interaction Design

### Task 1.1: matchedGeometryEffect — dream list → detail transition
**Files:** `DreamsView.swift`, New `DreamDetailView.swift`

When tapping a dream row, the title text, checkmark, and horizon badge should smoothly *morph* from their list position into their detail view position. This is the iconic Apple shared-element transition.

Implementation:
- Add `@Namespace var animationNamespace` to DreamsView
- DreamRow gets `.matchedGeometryEffect(id: dream.id, in: animationNamespace)`
- DreamDetailView gets matching `.matchedGeometryEffect` on the title, status icon, and horizon badge
- The NavigationLink uses `isDetailLink(true)` and the detail is a full push

### Task 1.2: SymbolEffect — completion celebration
**Files:** `DreamDetailView.swift`

When a dream is marked complete, instead of a static checkmark:
1. The circle icon uses `.symbolEffect(.bounce, value: dream.isCompleted)` — bounces once
2. A burst of 3 sparkle SF Symbols (`.symbolEffect(.variableColor.iterative)`) radiates outward from the toggle and fades
3. The background briefly flashes a subtle green gradient using `PhaseAnimator`

```swift
// PhaseAnimator for completion glow
PhaseAnimator([0, 1, 0]) { value in
    RoundedRectangle(cornerRadius: 14)
        .fill(Color.green.opacity(value * 0.08))
} animation: { _ in .spring(response: 0.3) }
```

### Task 1.3: scrollTransition — parallax horizon pills
**Files:** `DreamsView.swift`

The horizon pill row at the top uses `.scrollTransition(.interactive)` so as the dream list scrolls beneath it, the pills slightly compress and blur, then restore when scrolling back. This adds physical depth.

### Task 1.4: Context menu with rich preview
**Files:** `DreamsView.swift`

Long-press on a dream row shows:
- A **preview** of the dream detail (using `.contextMenu(menuItems:preview:)` with a small DreamDetailView snapshot)
- Menu actions: "Mark Complete", "Edit", "Move To…" (submenu of 5 horizons), "Delete"

### Task 1.5: Drag-to-reorder dreams
**Files:** `DreamsView.swift`

Add an `order: Int` field to `Dream` model. Within a horizon, rows can be reordered via `.onMove(perform:)` on the ForEach. Show a drag handle (six horizontal lines SF Symbol) on the trailing edge of each row. AppViewModel gets `func moveDream(from: IndexSet, to: Int, horizon: TimeHorizon)`.

### Task 1.6: TipKit onboarding
**Files:** `DreamsView.swift`

On first launch after unlock, show a TipKit popover pointing to the horizon pills: "Switch between timeframes to see your 6-month, 1-year, 3-year, 5-year, and 10-year dreams." Uses `Tip` struct with a simple rule that shows once and never again.

---

## Phase 2 — Refined Visual Language (not generic)

### Task 2.1: Material-based depth system
**Files:** All views

Replace flat backgrounds with Apple's material system:
- **Dream list background:** `.regularMaterial` over a subtle blue-yellow gradient (like iOS Weather app's sky gradient)
- **FAB button:** `.thinMaterial` background instead of solid blue, with blue SF Symbol
- **Sheets:** `.presentationBackground(.regularMaterial)` for the add dream sheet
- **Dream rows:** `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))` for subtle glass cards

### Task 2.2: Variable color SF Symbols
**Files:** `DreamsView.swift`, `DreamDetailView.swift`

Use `.symbolRenderingMode(.hierarchical)` or `.palette` on key symbols:
- Horizon pills use `.symbolRenderingMode(.hierarchical)` — the foreground layer gets the blue tint, background layer gets 30% opacity
- Completed dreams: checkmark circle uses `.symbolRenderingMode(.palette)` with green foreground + gray secondary
- Tab bar icons: use `.symbolVariant(.fill)` for selected state (already done, verify)

### Task 2.3: Typographic refinement — New York for dreams
**Files:** `DreamsView.swift`, `DreamDetailView.swift`

Apple uses New York (serif) for reading-focused content (Books, News). Dream titles in the detail view should use the New York font at `.largeTitle` weight. Body text uses SF Pro. This creates a meaningful visual distinction: "this is your aspiration" vs "this is UI."

```swift
.font(.system(.largeTitle, design: .serif, weight: .bold))
```

### Task 2.4: Dynamic Type support
**Files:** All views

Verify every Text element uses semantic font styles (`.body`, `.headline`, `.caption`, etc.) rather than hardcoded sizes. This ensures the app works with accessibility text sizes. Test with largest Dynamic Type setting.

---

## Phase 3 — Pro Features & Monetization

### Task 3.1: StoreKit integration
**Files:** New `DreamTracker/Store/StoreManager.swift`

Create a simple `StoreManager` using StoreKit 2:
- Single non-consumable product: `"com.dreamtracker.pro"` ($2.99)
- `@Published var isPro: Bool = false`
- `func purchase()` — presents StoreKit purchase sheet
- `func restorePurchases()` — standard App Store requirement
- On app launch, check `Transaction.currentEntitlements` for the pro product

### Task 3.2: Pro-gated features
**Files:** `DreamsView.swift`

- Free tier: 3 dreams per horizon (15 total). Adding a 4th shows a gentle "DreamTracker Pro" sheet with the $2.99 purchase option and a "Not now" dismiss.
- Pro: Unlimited dreams, iCloud sync enabled, widgets available
- Settings shows: "DreamTracker Pro — Active" or "Get Pro — $2.99"

### Task 3.3: Settings sheet upgrade
**Files:** `DreamsView.swift` settings section

Current settings is bare. Upgrade:
```
Section "DreamTracker Pro"
  - Status badge (Free / Pro)
  - "Get Pro — $2.99" button (if free)
  - "Restore Purchases" button

Section "Data"
  - "iCloud Sync" toggle (Pro only, disabled if free)
  - "Export Dreams as Text" (share sheet)
  - "Delete All Data" (destructive, with confirmation)

Section "About"
  - Version 2.0
  - "Rate DreamTracker" (deep link to App Store)
  - "Privacy Policy" (link)
```

---

## Phase 4 — Security Hardening

### Task 4.1: App Attest integration (existing, verify)
**Files:** `DreamTracker/Network/AppAttestManager.swift`

The project already has AppAttestManager. Ensure it's wired up properly — even though the app is local-first, App Attest protects against tampered builds if we ever add server-side features.

### Task 4.2: Keychain data protection audit
**Files:** `DreamTracker/Model/DreamStore.swift`

Verify all file writes use `.completeFileProtection` (already done). Add an additional layer: encrypt the JSON data with a device-specific key from the Keychain before writing to disk. Even if someone extracts the file, it's unreadable without the device.

### Task 4.3: Jailbreak detection
**Files:** New `DreamTracker/Security/JailbreakDetector.swift`

Simple jailbreak detection:
- Check for common jailbreak file paths (`/Applications/Cydia.app`, etc.)
- Check if app can write outside its sandbox
- If detected, show a warning and optionally lock sensitive data
- This is NOT a hard block (Apple doesn't require it) but a defense-in-depth measure

---

## Phase 5 — Widget

### Task 5.1: Widget extension target
**Files:** New `DreamTrackerWidget/` directory with `DreamTrackerWidget.swift`

A small widget (`.systemSmall` and `.accessoryCircular`):
- Shows: "6M: [next incomplete dream]" or "Today's focus"
- Taps open the app
- Uses App Group shared container to read dream data
- Timeline provider refreshes daily

---

## Phase 6 — Polish Pass

### Task 6.1: App icon
Add a proper app icon: a sparkle/star symbol on a deep blue-to-purple gradient background. Use Xcode asset catalog.

### Task 6.2: Launch screen
Rename or replace `LaunchScreen.storyboard` — show the app icon centered on the brand gradient, fading into the main UI.

### Task 6.3: Accessibility labels
**Files:** All views

Add `.accessibilityLabel()` to every interactive element:
- Dream rows: "Dream: [title], [completed/not completed]"
- Horizon pills: "Filter by [6 months], [count] dreams"
- FAB: "Add new dream"
- Checkmark toggle: "Mark [title] as completed"

### Task 6.4: Localization foundation
Add `Localizable.strings` with English base. The app doesn't need full translation yet, but the infrastructure should exist so adding languages later is trivial.

---

## Verification Plan

After each phase:
```bash
cd "/Users/vishalsingh/Desktop/DeepSeek Projects/dream_tracker"
xcodebuild -project DreamTracker.xcodeproj -scheme DreamTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Critical App Store checklist before submission:**
- [ ] PrivacyInfo.xcprivacy present and accurate
- [ ] No private API usage (`xcodebuild -checkPrivateAPI`)
- [ ] App Transport Security blocks HTTP
- [ ] Entitlements match capabilities
- [ ] App icon at all required sizes (1024x1024 + smaller)
- [ ] Launch screen displays correctly on all device sizes
- [ ] Screenshots: 6.7" (iPhone 17), 6.1" (iPhone 15), 5.5" (iPhone 8 Plus back-compat)
- [ ] Privacy policy URL live
- [ ] Age rating set
- [ ] StoreKit testing passes (sandbox purchase, restore)
