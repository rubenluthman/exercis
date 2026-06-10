# Exercis – Roadmap

Everything planned, decided, and parked in one place. Updated continuously during sessions and app reviews.

**Workflow:** all items here are shared — we discuss and decide together whether something gets built, deferred, or dropped. When something ships, move it to **Done** at the bottom. Don't just strike it where it stands.

---

## Up next / under discussion

- **macOS companion app** — lightweight macOS app for logging sessions retroactively and managing programs from a desktop. Doesn't need to mirror the iOS app fully — focus on program editing and after-the-fact logging. Shares SwiftData models and business logic with the iOS app; CloudKit sync (see below) is a prerequisite for data to move between devices.

- **watchOS app** — quick set/reps logging directly from the wrist during a session. `exercis.icon` already has `watchOS` in `supported-platforms.circles` so the icon is ready. Requires an Apple Developer account and CloudKit sync.

---

## Requires Apple Developer account (TestFlight + App Store)

- **Paid Apple Developer Program** ($99/yr) — prerequisite for everything below
- **CloudKit sync** — without it, users lose all data on device replacement or reinstall; critical from the first TestFlight round since testers often switch devices
- **GIF license** — replace the hasaneyldrm source with a licensed alternative (ExerciseDB Pro) before submission
- **App Group activation** — `group.rubenluthman.Exercis` must be enabled in Xcode Signing & Capabilities for both targets (Exercis + ExercisWidget) for the widget to function
- **Export compliance** — `ITSAppUsesNonExemptEncryption` in Info.plist must be set correctly for App Store Connect upload
- **Privacy policy URL** — required in App Store Connect metadata due to HealthKit data collection
- **Face ID instructions for reviewers** — App Review / TestFlight reviewers need to know how to log in without biometrics
- **Build number management** — establish a process for unique build numbers per upload

---

## Codebase

- **Global exercise editing in StrengthView** — a single place to swap, add, or remove exercises for the whole session, instead of a per-exercise swap button. Could be an edit icon in the header or a long press on the exercise name.

- **Expand alias coverage in `exercises_def.json`** — go through all exercises and add `aliases` for every known alternative name (e.g. "Lateral Raises"/"Lateral Raise" for "Side Raise"). Pair with including `aliases` in `searchStrings` in `ExercisePickerView` — otherwise aliases only help with history migration, not search.

---

## Out of scope

- **Mid-session exercise swap** — swap an exercise mid-session without breaking the structure; save original + replacement in the log
- **Per-exercise rest timer** — default stored in `ProgramExercise.restSeconds` instead of a global AppStorage setting
- **HIIT timer** — unclear use case
- **4-tab layout** — final, not up for debate
- **Siri Shortcuts** — single-user app, low priority
- **TabView restructure** — 3 tabs ruled out; current 4-tab layout with a unified Training tab is correct
- **ExerciseDef → SwiftData `@Model`** — no practical need, prefill works via `programId`
- **HKWorkoutActivity per exercise** — no way to distinguish movement from rest, produces no meaningful data
- **Swift Packages** (`swift-algorithms`, `swift-collections`) — not justified until the app grows
- **`sv_SE` locale hardcoded** — intentional choice for a Swedish single-user app, not a bug

---

## Done

- ~~Onboarding — 3 steps (program grid + cardio checkboxes + Apple Health), standard programs seeded~~
- ~~GIF system — 155 exercises with GIF (accent color + tappable), GifSheet with WKWebView + muscle info~~
- ~~Exercise descriptions — 186 reviewed, 8 factual errors fixed~~
- ~~Constraint filter — body limitations + program constraints in ExercisePickerView~~
- ~~Imperial units (lbs/miles)~~
- ~~TrainingView — Training tab with programs + cardio types~~
- ~~Automatic time tracking for cardio~~
- ~~CSV export~~
- ~~Centralized haptics~~
- ~~Localization — English base language, Swedish via sv.lproj~~
- ~~SwiftData VersionedSchema v1 + ExercisMigrationPlan~~
- ~~`#if DEBUG` OSLog logging on all context.save() calls~~
- ~~XCTest target — Epley, weight formatting, CardioType mapping, WorkoutDraft, ExerciseLibrary, HistoryView grouping, HealthKit calories, PR detection, ProgramSeeder, CSV export, PeriodSummary aggregations, Live Activity colors~~
- ~~`try!` on production ModelContainer replaced with graceful fallback — tries persistent store, falls back to in-memory store on failure and shows an alert ("Couldn't Load Saved Data") instead of crashing~~
- ~~`.foregroundColor` → `.foregroundStyle` — all 125 occurrences migrated, consistently using `.foregroundStyle` throughout~~
- ~~iOS 26 Tab bar — `tabBarMinimizeBehavior(.onScrollDown)`~~
- ~~iOS 26 Buttons — `primaryButtonStyle` adaptive (glass / filled rectangle)~~
- ~~GifSheet accessibilityLabel — "Animation showing [exercise name]"~~
- ~~Volume toggle in ExerciseChartSheet (1RM / VOL)~~
- ~~ProfileView — streak, last session, personal records, weekly average~~
- ~~Progression suggestions — badge below set number (→ X kg × Y reps), +2.5 kg on INCREASE~~
- ~~Training reminders — REMINDERS section in Settings, weekdays + auto-time from history~~
- ~~Home screen widget — small (streak + next program) + medium (+ last session)~~
- ~~WhatsNewSheet — release notes opened from the VERSION row in Settings~~
- ~~WhatsNewSheet localized — headings and release notes translated in sv.lproj/Localizable.strings~~
- ~~CI — GitHub Actions job (.github/workflows/tests.yml) runs xcodebuild test with the Exercis test plan on push/PR to main~~
- ~~Empty `en.lproj` folder removed (Xcode artifact, was not checked into git)~~
- ~~Export bug fixed — race condition in SettingsView~~
- ~~GIF files purged from git history with git-filter-repo~~
- ~~Fix: duplicate exercise Military Press → Seated Military Press~~
- ~~Fix: localization in helper functions~~
- ~~Fix: duplicate-alias crash in migrateExerciseNames~~
- ~~Sheet backgrounds — `.background(Color.appBackground)` replaced with `.regularMaterial` on effort pickers (StrengthView/CardioView) and the onboarding footer for Liquid Glass transparency~~
- ~~CSV export RFC 4180 quoting — new free function `csvField(_:)` in Theme.swift quotes fields containing commas/quotes/newlines~~
- ~~HealthKit authorization consolidated — moved from StrengthView/CardioView `.onAppear` to `MainTabView.onAppear` at app launch~~
- ~~App review 2026-06-06 — localized missing strings, added accessibility labels, updated CLAUDE.md~~
- ~~App icon — adaptive Liquid Glass icon via Icon Composer (`exercis.icon`), Default/Dark/Tinted automatic, `AppIcon.appiconset` removed~~
- ~~App review 2026-06-06 (full, 7 surfaces) — localized 9 additional strings; extracted `ChartEmptyState` from four identical copies into Theme.swift; corrected stale CLAUDE.md sections~~
- ~~Locked reps mode per workout program~~
- ~~Repo renamed to `exercis` (lowercase), made public; all documentation translated to English~~
