# DreamTracker — Wireframes v3

All screens rendered in ASCII. Dark theme, 393×852 (iPhone 17 viewport).

---

## Screen 1: Lock Screen (Face ID)

```
┌──────────────────────────────────┐
│                                  │
│         ░░░░░░░░░░░░░░           │  ← subtle gradient
│           ░░░░░░░░░░             │     #0A0A1A → #14142E
│                                  │
│             ◉ ─────              │  ← Face ID icon (hierarchical)
│                                  │
│        What do you want          │
│       your life to look like?    │  ← serif, white, 22pt, centered
│                                  │
│   ┌──────────────────────────┐   │
│   │    ◉  Unlock             │   │  ← pill button, accent #ED4D8C
│   └──────────────────────────┘   │     44pt tall, full width-80px
│                                  │
│      Protected by Face ID        │  ← caption, tertiary text
│                                  │
└──────────────────────────────────┘
```

---

## Screen 2: Home Screen (Post-Unlock)

```
┌──────────────────────────────────┐
│         ·  ·    ·    ·           │  ← sparse stars, slow drift
│    ·        ·       ·   ·        │
│                                  │
│            ✦  DreamTracker       │  ← sparkle + title, white, 28pt
│                                  │     pulsing glow animation
│                                  │
│   ┌──────────────────────────┐   │
│   │                          │   │
│   │  "The future belongs to  │   │  ← rotating quote, serif, 20pt
│   │   those who believe in   │   │     white, italic, centered
│   │   the beauty of their    │   │     crossfade every 8 seconds
│   │   dreams."               │   │
│   │                          │   │
│   │   — Eleanor Roosevelt    │   │  ← attribution, tertiary, 13pt
│   └──────────────────────────┘   │
│                                  │
│          ┌──────────┐            │
│          │ Enter  → │            │  ← pill button, fades in after 2s
│          └──────────┘            │     accent (#ED4D8C) bg, white text
│                                  │
│     Tap anywhere to skip         │  ← tertiary text, 12pt
│                                  │
└──────────────────────────────────┘
```

---

## Screen 3: Dreams Canvas (Main Tab)

```
┌──────────────────────────────────┐
│  ◉ 3/7 dreams achieved    ⚙     │  ← progress ring + settings gear
│                                  │
│           ┌──────────┐           │
│    6M     │  ╭────╮  │   1Y      │  ← OrbitDial (220pt)
│  Ignite ──│  │ 🌍 │──│── Grow    │     rotating ring, fixed labels
│           │  │3Y  │  │           │     current horizon in center
│    5Y     │  ╰────╯  │   10Y     │
│  Master ──│          │── Legacy  │
│           └──────────┘           │
│                                  │
│   ╭────────────────────────╮     │
│   │ ▎ Launch my business   │     │  ← dream card (glass)
│   │ ▎ 3Y · Build           │     │     left accent: #478DD1 (blue)
│   │                    ✓   │     │     title: white, body
│   ╰────────────────────────╯     │     checkmark: tap to complete
│                                  │
│   ╭────────────────────────╮     │
│   │ ▎ Run a marathon       │     │  ← completed dream
│   │ ▎ 6M · Ignite    ✦ ✓  │     │     golden shimmer overlay
│   ╰────────────────────────╯     │     15% gold gradient
│                                  │
│   ┌────────────────────────────┐ │
│   │ "In 6 months, Sushant      │ │  ← Parallel Lives card
│   │  Singh Rajput dropped out  │ │     always visible below dreams
│   │  of DTU and got his first  │ │     orange left border (6M)
│   │  TV role with ₹5,000..."   │ │
│   └────────────────────────────┘ │
│                                  │
│                           [ + ]  │  ← FAB (frosted glass circle)
└──────────────────────────────────┘
```

---

## Screen 4: Dream Detail

```
┌──────────────────────────────────┐
│  ← Back                    Share │  ← toolbar: back + share icons
│                                  │
│                                  │
│     Launch my own business       │  ← serif largeTitle, white, bold
│                                  │
│   ┌──────────────────────────┐   │
│   │ 3Y · Build               │   │  ← horizon badge: #478DD1 bg
│   └──────────────────────────┘   │
│                                  │
│   ╭──────────────────────────╮   │
│   │ Notes                    │   │  ← glass card section
│   │                          │   │
│   │ Build a SaaS product in  │   │     white body text
│   │ the developer tools      │   │
│   │ space. First milestone:  │   │
│   │ 100 paying customers.    │   │
│   │                          │   │
│   ╰──────────────────────────╯   │
│                                  │
│   ┌────────────────────────────┐ │
│   │ ◉ Mark as Complete         │ │  ← toggle: outline when incomplete
│   └────────────────────────────┘ │     filled + sparkle when complete
│                                  │     heavy haptic on toggle
│                                  │
│   Created on 15 June 2026        │  ← tertiary text, 12pt
│                                  │
└──────────────────────────────────┘
```

---

## Screen 5: Decomposition Sheet

```
┌──────────────────────────────────┐
│  Cancel          Decompose  Save │  ← toolbar
│                                  │
│   ╭──────────────────────────╮   │
│   │ Build a lasting legacy   │   │  ← parent dream card
│   │ 10Y · Legacy      ★      │   │     indigo border, star icon
│   ╰──────────────────┬───────╯   │
│                      │           │  ← connecting line
│               ┌──────┴──────┐    │
│               │ 5Y · Master │    │  ← auto-suggested sub-dream
│               │ First book   │    │     plum border
│               │ published    │    │
│               └──────┬───────┘    │
│                      │           │
│               ┌──────┴──────┐    │
│               │ 3Y · Build  │    │
│               │ Write 50% of │    │  ← blue border
│               │ manuscript   │    │
│               └──────┬───────┘    │
│                      │           │
│               ┌──────┴──────┐    │
│               │ 1Y · Grow   │    │
│               │ Write daily  │    │  ← teal border
│               │ 500 words    │    │
│               └──────────────┘    │
│                                  │
│   ┌──────────────────────────┐   │
│   │  Save All (4 dreams)     │   │  ← sticky bottom CTA
│   └──────────────────────────┘   │
└──────────────────────────────────┘
```

---

## Screen 6: Life Calendar (Tab 2)

```
┌──────────────────────────────────┐
│  Life Calendar                   │  ← navigation title
│                                  │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│   │3Y  │ │12w │ │  8 │ │ 14 │   │  ← summary stat cards (2×2 grid)
│   │Top │ │Streak│ │Done│ │Entr│   │     glass background, white text
│   └────┘ └────┘ └────┘ └────┘   │
│                                  │
│   ╭──────────────────────────╮   │
│   │ 💡 You're great at 1Y    │   │  ← Dream Coach insight
│   │ goals (80%) but your 5Y  │   │
│   │ dreams need attention.   │   │
│   ╰──────────────────────────╯   │
│                                  │
│   ╭──────────────────────────╮   │
│   │ 🔮 At your pace, all     │   │  ← Life Simulator
│   │ dreams complete by 2031. │   │
│   ╰──────────────────────────╯   │
│                                  │
│   Mon Tue Wed Thu Fri Sat Sun    │  ← day headers
│   ░░ ░░ ░░ ▓▓ ▓▓ ▓▓ ░░ ░░      │  ← heatmap grid
│   ▓▓ ▓▓ ██ ██ ██ ▓▓ ░░ ░░      │     ░░ = idle (7% white)
│   ░░ ░░ ▓▓ ▓▓ ▓▓ ██ ██ ░░      │     ▓▓ = active (horizon color 55%)
│   ...                            │     ██ = completed (green 85%)
│                                  │
│   ● Completed · Created · Journal│  ← legend
│                                  │
│   ── June 2026 ──                │  ← month header
│   ╭──────────────────────────╮   │
│   │ ▎ Launch business · 3Y   │   │  ← month timeline card
│   │ ▎ Read 12 books · 1Y  ✓  │   │     glass, left accent
│   ╰──────────────────────────╯   │
└──────────────────────────────────┘
```

---

## Screen 7: Journal (Tab 3)

```
┌──────────────────────────────────┐
│  Journal                         │  ← navigation title
│                                  │
│   Capture thoughts about your    │
│   progress, setbacks, and        │  ← empty state (when no entries)
│   wins along the way.            │     tertiary text, centered
│                                  │
│        ┌────────────────┐        │
│        │ New Entry      │        │  ← CTA button (accent)
│        └────────────────┘        │
│                                  │
│  ────────────────────────────    │
│                                  │
│   June 15, 2026                  │  ← date header
│   ╭──────────────────────────╮   │
│   │ ▎ Finished the first     │   │  ← entry card
│   │ ▎ draft of my business   │   │     blue left accent (3Y context)
│   │ ▎ plan. Feeling excited  │   │
│   │ ▎ but nervous.           │   │
│   ╰──────────────────────────╯   │
│                                  │
│   June 10, 2026                  │
│   ╭──────────────────────────╮   │
│   │ ▎ Had a breakthrough     │   │
│   │ ▎ on pricing model...    │   │
│   ╰──────────────────────────╯   │
│                                  │
│   Tap empty space to write       │  ← hint text
│                                  │
└──────────────────────────────────┘
```

---

## Screen 8: Add Dream Sheet

```
┌──────────────────────────────────┐
│  Cancel               Save Dream │  ← toolbar
│                                  │
│   ┌──────────────────────────┐   │
│   │ What do you want to      │   │  ← text field, placeholder
│   │ achieve?                 │   │     "Your dream..."
│   └──────────────────────────┘   │
│                                  │
│   ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│   │ 6M │ │ 1Y │ │ 3Y │ │ 5Y │   │  ← horizontal horizon pills
│   │  ✓ │ │    │ │    │ │    │   │     active = filled accent
│   └────┘ └────┘ └────┘ └────┘   │     inactive = border only
│   ┌────┐                        │
│   │10Y │                        │
│   └────┘                        │
│                                  │
│   ⚠ Free limit: 2/3 dreams      │  ← pro limit indicator (if needed)
│      used in this horizon        │
│                                  │
│   ┌──────────────────────────┐   │
│   │     Save Dream           │   │  ← primary CTA
│   └──────────────────────────┘   │
└──────────────────────────────────┘
```

---

## Screen 9: Settings Sheet

```
┌──────────────────────────────────┐
│  Settings                   Done │
│                                  │
│   ┌──────────────────────────┐   │
│   │ DreamTracker Pro          │   │
│   │ Active ✓                 │   │  ← or "Get Pro — $2.99"
│   └──────────────────────────┘   │
│                                  │
│   ┌──────────────────────────┐   │
│   │ Data & Privacy           │   │
│   │   Export Dreams      →   │   │
│   │   Delete All Data    →   │   │  ← destructive, red
│   └──────────────────────────┘   │
│                                  │
│   ┌──────────────────────────┐   │
│   │ About                    │   │
│   │   Rate DreamTracker  →   │   │
│   │   Privacy Policy     →   │   │
│   │   Version 1.0            │   │
│   └──────────────────────────┘   │
│                                  │
│   DreamTracker · Made with love  │  ← footer
└──────────────────────────────────┘
```

---

## Screen 10: Pro Upgrade Sheet

```
┌──────────────────────────────────┐
│                           Close  │
│                                  │
│              ✦                   │
│        DreamTracker Pro          │  ← title, white, bold
│                                  │
│   ╭──────────────────────────╮   │
│   │ ✓ Unlimited dreams       │   │
│   │ ✓ iCloud sync            │   │  ← feature list, checkmarks
│   │ ✓ Home & Lock widgets    │   │     green accent
│   │ ✓ No ads. No tracking.   │   │
│   ╰──────────────────────────╯   │
│                                  │
│          ┌──────────┐            │
│          │ $2.99    │            │  ← price, large, bold
│          │ One-time │            │     "One-time purchase. Forever."
│          └──────────┘            │
│                                  │
│   ┌──────────────────────────┐   │
│   │     Get Pro — $2.99      │   │  ← primary CTA, accent bg
│   └──────────────────────────┘   │
│                                  │
│        Restore Purchases         │  ← link-style, tertiary
│                                  │
└──────────────────────────────────┘
```

---

## Navigation Flow Diagram

```
                    ┌─────────┐
                    │  Launch  │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │ Face ID   │
                    └────┬─────┘
                         │
                    ┌────▼─────┐
                    │  Home     │◄──── quote rotation (auto)
                    │ (Quotes)  │────► tap anywhere or "Enter"
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
         ┌────▼───┐ ┌───▼────┐ ┌───▼────┐
         │ Dreams │ │Calendar│ │Journal │  ← Tab Bar
         │  Tab   │ │  Tab   │ │  Tab   │
         └───┬────┘ └────────┘ └────────┘
             │
     ┌───────┼────────┬──────────┐
     │       │        │          │
┌────▼──┐ ┌─▼──┐ ┌───▼────┐ ┌──▼──────┐
│Dream  │ │Add │ │Long-   │ │Settings │
│Detail │ │Dream│ │Press → │ │Sheet    │
│       │ │Sheet│ │Menu    │ │         │
└───────┘ └────┘ └───┬────┘ └──┬──────┘
                     │          │
                ┌────▼─────┐ ┌─▼────────┐
                │Decompose │ │Pro Upgrade│
                │Sheet     │ │Sheet      │
                └──────────┘ └──────────┘
```
