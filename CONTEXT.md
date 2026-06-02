# Exercis — Project Context for Claude.ai

> This file is the single source of truth for Claude.ai Chat sessions about this project.
> It is maintained by Claude Code and updated at every app revision.

---

## What is Exercis?

A private iOS app for logging strength and cardio workouts. Single user (Ruben). Built with SwiftUI + SwiftData, iPhone only, iOS 17+. Not on the App Store.

---

## Tech Stack

- **SwiftUI + SwiftData** — Apple's declarative UI framework and persistence layer
- **HealthKit** — saves workouts to Apple Health
- **Face ID** — authentication via `LAContext`
- **iCloud backup** via standard device backup (no CloudKit sync)
- **Deployment target:** iOS 17 (non-negotiable)

---

## Current App Structure

### Screens & Navigation
```
LockView (Face ID) → HomeView → StrengthView
                              → CardioView
                              → HistoryView
```

Navigation uses `NavigationStack` + `NavigationLink`. Swipe-back enabled on all sub-screens.

### Files (all flat in `Exercis/`)
| File | Purpose |
|------|---------|
| `ExercisApp.swift` | App entry point, RootView, AppScreen enum |
| `AuthManager.swift` | Face ID / passcode authentication |
| `Models.swift` | SwiftData models + CardioType enum + WorkoutDraft |
| `Theme.swift` | Colors, fonts, button styles, shared UI components |
| `HomeView.swift` | Home screen with three buttons |
| `LockView.swift` | Login screen |
| `StrengthView.swift` | Log a strength workout |
| `ExerciseSection.swift` | Exercise section with sets/reps |
| `CardioView.swift` | Log a cardio session |
| `HistoryView.swift` | Mixed history list (strength + cardio) |
| `HistoryCard.swift` | Expandable card for strength sessions |
| `CardioCard.swift` | Expandable card for cardio sessions |
| `ExerciseChartSheet.swift` | e1RM progression chart per exercise |
| `CardioChartSheet.swift` | Duration progression per cardio type |
| `EffortChartSheet.swift` | Effort score progression for strength |
| `CardioEffortChartSheet.swift` | Effort score progression per cardio type |
| `PeriodSummarySheet.swift` | Monthly/yearly summary with charts |
| `SessionTimePicker.swift` | Edit session start/end time |
| `HealthKitManager.swift` | Save/delete HKWorkout to Apple Health |
| `VideoSheet.swift` | Exercise video in SFSafariViewController |

---

## Data Models

```swift
WorkoutSession       // strength session
  └── ExerciseLog[]  // one per exercise
        └── SetLog[] // one per set (weight + reps)

CardioSession        // cardio session (type, duration, distance, effort)
```

All relations use cascade delete. No CloudKit. SwiftData handles persistence.

**CardioType** values: `CROSSTRAINER`, `CYKEL`, `RODDMASKIN`, `VANDRING`

---

## Exercises (exactly these 5, in this order)

| Display Name | Reps | Video |
|---|---|---|
| Barbell Back Squat | 5–8 | YouTube |
| Incline Dumbbell Bench Press | 6–10 | YouTube |
| Romanian Deadlift | 6–8 | YouTube |
| Seated Cable Row | 8–12 | muscleandstrength.com |
| Lat Pulldown | 8–12 | YouTube |

---

## Design System

- **Font:** Jost (only font used, all weights)
- **Colors:** Named color sets in Assets.xcassets, exposed via `Color` extensions in `Theme.swift`
- **Accent colors:** `homeAccent` (red), `workoutAccent` (green), `historyAccent` (blue)
- **Background:** `Color(.systemBackground)` — adapts to dark mode automatically
- **Buttons:** `FilledButtonStyle` (primary) and `OutlineButtonStyle` (secondary)
- **Horizontal padding:** 24pt throughout
- **No emoji**, minimal iconography (SF Symbols only)
- **Animations:** `.easeInOut(duration: 0.22)`

---

## Planned Expansions (decided, not yet built)

### Navigation → TabView
Replace current HomeView with a tab bar:
- **Styrka** tab → program list → StrengthView as fullScreenCover
- **Kondition** tab → cardio type list → CardioView as fullScreenCover
- **Historik** tab → current HistoryView

### Workout Programs
- User-defined programs with custom colors (chosen from a curated palette)
- 7 default programs: Full Body, Överkropp, Underkropp, Push, Pull, Legs, Bodyweight
- `WorkoutProgram` SwiftData model with ordered exercise list

### Onboarding (2 steps)
1. Select workout programs (multi-select grid)
2. Select cardio types (checkboxes)

### Extended Cardio Types
26 types defined in `cardio_types.json` (currently 4 active).

### GIF System
Exercise GIFs stored in `Exercis/Resources/GIFs/`. Mapping in `gif_mapping.md`.

---

## Key Constraints

1. iOS 17 deployment target
2. iPhone only, portrait only
3. Jost is the only font
4. One accent color per screen context
5. English as base language, Swedish via `.strings` files
6. No CloudKit (requires paid Apple Developer account)

---

*Last updated: 2026-06-02*
