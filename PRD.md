# DreamTracker — Product Requirements Document

**Version:** 3.0  
**Status:** Draft for Review  
**Platform:** iOS 17.0+ (SwiftUI)  
**Target:** App Store  
**Monetization:** Free + One-Time Pro ($2.99)

---

## 1. Product Vision

> *"If you can see your future, you can build it."*

DreamTracker transforms vague ambitions into a visual, motivating roadmap across five time horizons. It combines personal goal tracking with inspiration from legendary achievers — showing users that their dreams are possible because someone they admire did something similar.

**One-liner:** A premium iOS app that helps you define goals across 6 months to 10 years, tracks progress with elegant visuals, and motivates you through the parallel lives of legendary achievers.

---

## 2. Target Audience

### Primary Persona: "Aspiring Builder"
- **Age:** 22–38
- **Location:** India (primary), Global (secondary)
- **Occupation:** Professional, entrepreneur, student
- **Pain points:**
  - Has big dreams but no structured way to track them
  - Existing apps feel like boring todo lists
  - Needs motivation — wants to know what legends did at their age
  - Finds western productivity apps culturally disconnected
- **Device:** iPhone, primarily portrait, dark mode preferred
- **Willing to pay:** Yes — one-time purchase preferred over subscription

### Secondary Persona: "Mid-Career Recalibrator"
- **Age:** 35–50
- **Pain points:** Career plateau, wants to set new 5-10 year goals, needs reflection tools

---

## 3. Core Features

### F1. Dream Canvas (Primary Screen)
**What:** Visual timeline of dreams organized by time horizon.  
**Horizons:** 6 Months, 1 Year, 3 Years, 5 Years, 10 Years  
**Interaction:**
- Smooth rotating dial to switch horizons (physical metaphor: camera lens ring)
- Dreams appear as elegant cards with horizon-colored accents
- Tap card → detail view; long-press → context menu (complete, delete, decompose)
- Pull-to-refresh triggers confetti animation

**Design principle:** One dream card at a time is the focal point. Everything else recedes.

### F2. Parallel Lives (Motivation Engine)
**What:** For each time horizon, show a curated story of a legendary achiever who accomplished something remarkable in that timeframe.  
**Locale-aware:** Indian users see Indian legends first (Sushant Singh Rajput, Virat Kohli, Dr. Kalam, Dhirubhai Ambani). Global users see international figures.  
**Format:** A beautiful card with:
- Legend's name + emoji
- What they achieved in X months/years
- A direct quote
- Visual: subtle gradient accent matching the horizon

**Innovation:** This is NOT an AI-generated generic quote. These are hand-curated, specific, verifiable stories with proper attribution.

### F3. Dream Detail
**What:** Full-screen view for a single dream.  
**Elements:**
- Dream title in serif typography (New York)
- Notes section (freeform text)
- Horizon selector
- Complete/Incomplete toggle with celebration animation
- "Created on..." date
- Share button (exports dream as text)
- Back navigation

### F4. Life Calendar (Reflection)
**What:** GitHub-style heatmap showing dream activity over time.  
**Cells:** Week-sized, colored by activity type (completed=green, created=blue, journal=purple, idle=subtle gray)  
**Summary cards:**
- Most productive horizon
- Longest streak (consecutive weeks with activity)
- Dreams completed this year
- Total journal entries

**Insights section:** Dream Coach analysis — pattern-based observations like "You complete 80% of 6-month goals but 0% of 5-year goals."

### F5. Dream Decomposition
**What:** Break a 5Y or 10Y dream into smaller time-horizon sub-dreams.  
**Flow:** Long-press dream → "Decompose" → cascade view showing parent → children at each level.  
**Auto-suggest:** Pre-fills sensible sub-dreams at each level.

### F6. Dream Pulse (Health Visualization)
**What:** Multi-segment ring showing completion rate per horizon.  
**Visual:** Colored arcs for each horizon proportionally filled. Center: "X/Y dreams achieved."

### F7. Home Screen
**What:** Beautiful animated entry point shown after Face ID unlock.  
**Elements:**
- DreamTracker wordmark with sparkle animation
- Rotating inspirational quote (changes every 8 seconds)
- Cosmic nebula background with drifting particles
- "Enter" button that fades in after 2 seconds
- Tap anywhere to skip

### F8. Journal
**What:** Distraction-free writing space for reflections.  
**Interaction:** Tap anywhere on empty space to start writing. Past entries fade to 20% opacity.

### F9. Security
- Face ID / Touch ID on launch
- AES-256-GCM encryption with device-specific key
- Jailbreak detection (refuses to run)
- App Transport Security enforced

### F10. Pro Features ($2.99 One-Time)
- Free: 3 dreams per horizon (15 total)
- Pro: Unlimited dreams, iCloud sync, widget support
- No subscription, no ads, no data collection

---

## 4. Design System

### Color Palette

| Token | Hex | Use |
|---|---|---|
| Background | `#0A0A1A` | Root view backgrounds |
| Surface | `rgba(255,255,255,0.07)` | Card backgrounds |
| Surface Border | `rgba(255,255,255,0.08)` | Card strokes |
| Text Primary | `#FFFFFF` | Headlines, body |
| Text Secondary | `rgba(255,255,255,0.60)` | Labels, metadata |
| Text Tertiary | `rgba(255,255,255,0.35)` | Captions, timestamps |
| Accent (6M) | `#E08550` | Terracotta |
| Accent (1Y) | `#52AD94` | Teal |
| Accent (3Y) | `#478DD1` | Blue |
| Accent (5Y) | `#8C61AE` | Plum |
| Accent (10Y) | `#6B6BC7` | Indigo |
| Success | `#33C78C` | Completed states |

### Typography
- **UI Text:** SF Pro (system default) — clean, readable
- **Dream Titles:** New York (serif) — aspirational, warm
- **Scale:** largeTitle → title → title2 → title3 → headline → body → callout → caption → caption2

### Spacing
- 8pt grid system (4, 8, 12, 16, 20, 24, 32, 48)

### Motion
- Spring animations (response: 0.5–0.6, damping: 0.65–0.7)
- Haptic feedback on significant interactions
- PhaseAnimator for celebrations
- Respects Reduce Motion accessibility setting

---

## 5. Screen Flow

```
Launch → Face ID → Home Screen (quotes) → Tab Bar
                                              ├── Dreams (Canvas + Dial + Parallel Lives)
                                              ├── Calendar (Heatmap + Insights)
                                              └── Journal (Writing)
                                  
Dreams → tap dream → Dream Detail → back
Dreams → long press → Context Menu → Decompose → Decompose Sheet
Dreams → + button → Add Dream Sheet
Dreams → gear → Settings Sheet → Pro Upgrade Sheet
```

---

## 6. Architectural Decisions

| Decision | Choice | Reason |
|---|---|---|
| State management | `@MainActor` AppViewModel + `@EnvironmentObject` | Single source of truth, no prop drilling |
| Persistence | JSON files + AES-GCM encryption | Simple, secure, no database dependency |
| StoreKit | StoreKit 2 (`Product.products`, `Transaction.currentEntitlements`) | Modern API, async/await native |
| Background | `LinearGradient` (no timeline-based animation) | Static gradient avoids GPU overhead on scroll |
| Cards | `Color.white.opacity(0.07)` (not `.ultraThinMaterial`) | Material requires light backdrop for glass effect |
| Navigation | `NavigationStack` + `.sheet` modals | Standard iOS patterns |

---

## 7. Non-Goals (v3)

- Social sharing / community features
- AI-generated dream suggestions
- Apple Watch companion
- Android version
- Cloud backup (beyond iCloud sync for Pro)
- Habit tracking (staying focused on long-term dreams only)

---

## 8. Success Metrics

1. **Day-7 retention:** >40% of users open the app at least once in week 2
2. **Dream creation:** Average 5+ dreams per user within first 3 days
3. **Pro conversion:** >5% of active users purchase Pro
4. **App Store rating:** ≥4.5 stars
5. **Parallel Lives engagement:** >60% of sessions view at least one legend card

---

## 9. Open Questions for Review

1. **Tab count:** 3 tabs (Dreams, Calendar, Journal) or 2 (merge Calendar into Journal as a sub-view)?
2. **Parallel Lives refresh:** Show a new legend card every time the user switches horizons, or daily rotation?
3. **Pro gating:** Is 3 free dreams per horizon the right limit? Should it be 2 per horizon (10 total)?
4. **Home screen:** Should it appear every launch, or only once per day?
