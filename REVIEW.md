# v3 Design Review — Decision Checklist

## 1. Theme: Dark or Light?

| Option | Pros | Cons |
|---|---|---|
| **Dark (current)** | Energy-efficient OLED, premium feel, Apple's direction | Harder to nail contrast, can feel heavy |
| **Light** | Easier contrast, feels airy/aspirational | Not what Apple's shipping now, less dramatic |

**→ Recommend: Deep dark (#0A0A1A) with high-contrast white text and accent colors.** Apple's own Journal, Notes, Fitness apps use dark backgrounds. Mirror that.

## 2. Cards: Glass vs Solid

| Option | What it looks like |
|---|---|
| `.ultraThinMaterial` | Invisible on dark bg unless bg is bright |
| `Color.white.opacity(0.07)` | Visible, controlled, consistent across all contexts |

**→ Recommend: Solid 7% white.** Glass only works when there's a bright backdrop.

## 3. Text Scale: Do you agree with?

| Level | Size | Weight | Example use |
|---|---|---|---|
| Primary | 100% white | varies | Dream titles, headlines |
| Secondary | 60% white | varies | Labels, body copy |
| Tertiary | 35% white | varies | Dates, hints, captions |

## 4. Feature Priority: What to build first?

| # | Feature | Effort | Impact |
|---|---|---|---|
| 1 | Dreams Canvas + Dial | Already built | Core |
| 2 | Parallel Lives cards | Already built | High differentiation |
| 3 | Dream Detail + Celebration | Already built | Core |
| 4 | Life Calendar + Insights | Already built | Reflection |
| 5 | Home Screen (quotes) | Already built | First impression |
| 6 | Journal | Already built | Reflection |
| 7 | Pro + Settings | Already built | Monetization |

## 5. Open Decisions (need your input)

1. **Tab count:** Stay at 3 (Dreams, Calendar, Journal) or merge Calendar into a sub-section?
2. **Parallel Lives frequency:** New card on every horizon switch, or one daily card?
3. **Free tier limit:** 3 dreams/horizon (15 free) or 2 dreams/horizon (10 free)?
4. **Home screen frequency:** Every launch, or first launch of the day only?
5. **Background animation:** Static gradient (better perf), or slow nebula particles (more atmosphere)?

---

Please review PRD.md and WIREFRAMES.md, then give me your decisions on the 5 open questions above. After that, I rebuild everything to match the v3 spec exactly — no more guessing.
