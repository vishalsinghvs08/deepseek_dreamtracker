# DreamTracker — Apple Design Polish Plan

> **For Hermes:** Implement this plan task-by-task. Build and verify after each phase.

**Goal:** Elevate the current functional DreamTracker from "works" to "feels like a native Apple app" — adding dark mode support, haptics, dream detail views, context menus, progress rings, and refined typography/animation throughout.

**Architecture:** Pure SwiftUI on iOS 16+. Two-tab layout (Dreams + Journal). All additions are additive to the existing clean `Dream` model and `AppViewModel`. No new data model fields needed — polish is purely UI/UX.

**Tech Stack:** Swift 5, SwiftUI, UIKit interop (for haptics only), LocalAuthentication (existing).

---

## Phase 1: Dark Mode + System Color Adaptation

### Task 1.1: Make the app adapt to system appearance
**Files:** `DreamTrackerApp.swift`

Replace hardcoded colors (`.systemGroupedBackground`, `.systemGray6`, explicit `.white`/`.primary`) with a design token system that auto-adapts. The app should look good in both light and dark mode without any manual color selection.

- Add a `Theme` struct with static adaptive colors
- Replace `Color(.systemGroupedBackground)` → `Theme.background`
- Replace `Color(.systemGray6)` → `Theme.surfaceSecondary`
- Ensure the LockView, DreamsView, JournalView all use these tokens

### Task 1.2: Verify dark mode in every view
**Files:** `LockView.swift`, `DreamsView.swift`, `JournalView.swift`

Check every hardcoded color and ensure it works in dark mode. The FAB button, capsule backgrounds, text colors, and dividers must all adapt.

---

## Phase 2: Dream Detail View (NavigationLink)

### Task 2.1: Create `DreamDetailView.swift`
**Files:** Create `DreamTracker/Views/DreamDetailView.swift`

Tapping a dream row pushes a detail view (via `NavigationLink`):

- **Header:** The dream title (editable inline with tap-to-edit)
- **Description field:** A notes/description text area for more detail
- **Horizon badge:** Shows the time horizon, tappable to change (picker)
- **Created date:** Subtle secondary text
- **Completed toggle:** Large toggle at top
- **Delete button:** At bottom in a destructive section
- **Share button:** Toolbar item using `UIActivityViewController`

The detail view uses a `Form` or grouped `List` layout with `.insetGrouped` style.

### Task 2.2: Wire detail view into DreamsView
**Files:** `DreamsView.swift`

Wrap each `DreamRow` in a `NavigationLink(destination: DreamDetailView(dream:))`. Remove the inline completion toggle from the row (move to detail view), keeping just the checkmark indicator in the list.

### Task 2.3: Add `updateDream` to AppViewModel
**Files:** `DreamTrackerApp.swift`

Add `func updateDream(id: UUID, title: String, notes: String, horizon: TimeHorizon)` to `AppViewModel`. Add a `notes` field to the `Dream` model in `DreamModels.swift`.

---

## Phase 3: Context Menus + Haptics

### Task 3.1: Add context menu to dream rows
**Files:** `DreamsView.swift`

Add `.contextMenu` to each dream row with:
- "Mark Complete" / "Mark Incomplete"
- "Edit" (opens detail)
- "Move to 6M / 1Y / 3Y / 5Y / 10Y" (submenu)
- "Delete" (destructive)

### Task 3.2: Add haptic feedback
**Files:** `DreamsView.swift`, `DreamTrackerApp.swift`

Use `UIImpactFeedbackGenerator`:
- `.medium` when switching horizon pills
- `.heavy` when completing a dream
- `.light` when adding a dream
- `.rigid` when deleting

---

## Phase 4: Progress & Visual Polish

### Task 4.1: Add overall progress ring to DreamsView header
**Files:** `DreamsView.swift`

Add a circular progress ring next to the "Dreams" navigation title showing (total completed / total dreams across all horizons). Use a `ZStack` with two `Circle` strokes — background gray track, foreground blue progress arc.

### Task 4.2: Refine horizon pill design
**Files:** `DreamsView.swift`

Current pills are functional but plain. Upgrade:
- Selected pill: filled blue with subtle inner shadow
- Unselected: light gray fill with 0.5pt border
- Add a tiny progress dot inside each pill (green if all dreams done, blue if in progress, gray if empty)
- Smoother spring animation: `spring(response: 0.4, dampingFraction: 0.75)`

### Task 4.3: Add completion celebration
**Files:** `DreamDetailView.swift`

When a dream is toggled to completed, show a brief confetti-like animation using SF Symbols (sparkle, star) that burst from the toggle and fade out. Simple overlay using `@State` and `withAnimation`.

---

## Phase 5: Journal Polish

### Task 5.1: Add search to Journal
**Files:** `JournalView.swift`

Add `.searchable(text: $searchText)` modifier. Filter entries by content matching search text.

### Task 5.2: Add swipe-to-delete on journal entries
**Files:** `JournalView.swift`

Add `.swipeActions(edge: .trailing)` with a delete button calling `viewModel.deleteJournalEntry(id:)`. Add this method to `AppViewModel` and `DreamStore`.

### Task 5.3: Better journal entry design
**Files:** `JournalView.swift`

Current entries are plain text. Improve:
- Date header in `.caption` weight, secondary color
- Content in `.body` with proper line spacing (1.4x)
- Add a subtle left border accent (2pt blue line) on each entry
- Empty state: better SF Symbol (`book.pages`) and warmer copy

---

## Phase 6: Typography & Spacing Refinement

### Task 6.1: Standardize font hierarchy
**Files:** All view files

Define a consistent font scale:
- `.largeTitle` — dream title in detail view
- `.title2` — navigation titles
- `.headline` — section headers
- `.body` — dream text, journal content
- `.callout` — horizon pill labels
- `.caption` — dates, secondary info

Remove all raw `.system(size:weight:design:)` in favor of semantic text styles where possible.

### Task 6.2: Standardize spacing
**Files:** All view files

Use 8pt grid for all padding/spacing:
- Standard horizontal padding: 16pt
- Section spacing: 24pt
- Row spacing: 12pt
- Card corner radius: 12pt

---

## Phase 7: Lock Screen Refinement

### Task 7.1: Polish LockView for both light and dark
**Files:** `LockView.swift`

- Add a subtle gradient background (light: white→light gray, dark: black→dark gray)
- Larger sparkles icon with `symbolRenderingMode(.hierarchical)`
- "Unlock" button should use `.borderedProminent` style or custom with matched geometry
- Add "Protected by Face ID" footer text in `.caption`

---

## Build & Verify after each phase

```bash
cd "/Users/vishalsingh/Desktop/DeepSeek Projects/dream_tracker"
xcodebuild -project DreamTracker.xcodeproj -scheme DreamTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Test in both light and dark mode: In the simulator, press `Cmd+Shift+A` to toggle appearance.
