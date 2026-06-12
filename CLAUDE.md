# Exercis – Claude Code Context

## Public project
This repo is public. Every commit, every file, every decision documented here should be written as if a senior engineer is reading it. That means:

- Commits are clear and complete — a stranger should understand what changed and why from the message alone
- Code is clean enough to speak for itself — no scaffolding, no leftover experiments, no "will fix later"
- This file and ROADMAP.md stay accurate and up to date — they are part of the portfolio, not internal notes
- No "WIP" or "temp" commits reach main

---

A personal iOS app for logging strength and cardio workouts. Currently one user — the developer.

---

## Tech Stack

- **SwiftUI + SwiftData**, iOS 17+, iPhone only, portrait only
- **iCloud backup** via standard device backup (CloudKit sync not enabled — requires a paid Apple Developer Program account)
- **Authentication**: Face ID via `LAContext .deviceOwnerAuthentication` — automatic fallback to device passcode. No custom password. Auto-triggers on app launch; retry button on failure.
- **Deployment target**: iOS 17 (non-negotiable)
- **Apple Health**: `HKWorkout` saved on every completed strength and cardio session
- `NSFaceIDUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` required in Info.plist (notifications require no usage description key — `UNUserNotificationCenter.requestAuthorization` shows the system dialog without an Info.plist string)

---

## File Structure

All files live flat in the `Exercis/` folder.

**Important:** The project uses implicit Swift file discovery — the `Sources` phase in `project.pbxproj` is empty. All `.swift` files in `Exercis/` are included in the build automatically. New files do **not** need to be added manually in Xcode.

```
ExercisApp.swift          ← @main ExercisApp + RootView + MainTabView (4 tabs)
AuthManager.swift         ← AuthManager (Face ID / passcode)
Models.swift              ← SwiftData models (WorkoutSession, CardioSession, WorkoutProgram, ProgramExercise, ProgramRotation, CardioType)
Theme.swift               ← colors, fonts, button styles, ThinDivider, enableSwipeBack, formatWeight/parseWeight, free business-logic functions
LockView.swift            ← lock screen
TrainingView.swift        ← home tab — selected programs + cardio types, launch a session
StrengthView.swift        ← log a strength session (SetFormData, ExerciseFormData, progression suggestions, PR detection)
ExerciseSection.swift     ← exercise section with sets/reps + WorkoutField enum + INCREASE badge + progression suggestion badge
GifSheet.swift            ← GIF + exercise info (WKWebView, base64 embedding, opened from ExerciseSection)
CardioView.swift          ← log a cardio session (accordion, time tracked automatically, only distance entered manually)
HistoryView.swift         ← history list (interleaved strength and cardio, HistoryEntry enum)
HistoryCard.swift         ← expandable card for strength sessions (exercise names tappable → ExerciseChartSheet)
CardioCard.swift          ← expandable card for cardio sessions (type tappable → CardioChartSheet)
ExerciseChartSheet.swift  ← e1RM progression per exercise (Swift Charts, opened from HistoryCard)
CardioChartSheet.swift    ← duration progression per cardio type (Swift Charts, opened from CardioCard)
EffortChartSheet.swift    ← effort progression for strength (Swift Charts, opened from HistoryCard)
CardioEffortChartSheet.swift ← effort progression for cardio (Swift Charts, opened from CardioCard)
PeriodSummarySheet.swift  ← monthly/yearly summary (Swift Charts, opened from HistoryView)
SessionTimePicker.swift   ← shared sheet for start/end time (changing start drags end along, end adjustable freely)
ProfileView.swift         ← profile photo, name, top stats, streak (14-day dots), last session, personal records (top-8 e1RM), weekly average
SettingsView.swift        ← settings + program management + cardio types + body limitations + training reminders + data export
ProgramEditorView.swift   ← edit program (name, color, constraint, exercises, set count, locked reps per exercise)
ExercisePickerView.swift  ← exercise picker with fuzzy search + filter chips (MUSCLE/EQUIPMENT/MOVEMENT) + dimming
ProgramCard.swift         ← program card (used in TrainingView and SettingsView)
CardioTypeCard.swift      ← cardio type card with accent color header and last duration (used in TrainingView)
OnboardingView.swift      ← onboarding (step 1: programs with pencil editing, step 2: cardio types)
Previews.swift            ← Canvas previews for all main views with mock data (used in Xcode Canvas, excluded from release builds)
HealthKitManager.swift    ← saves HKWorkout to Apple Health
ExerciseLibrary.swift     ← loads exercises_def.json, ExerciseDef struct, ExerciseLibrary singleton + BodyLimitation/ProgramConstraint/MuscleGroup enums
ReminderManager.swift     ← UNUserNotificationCenter wrapper; schedule(weekdays:hour:minute:), cancel(), suggestedTime(from:)
WhatsNewSheet.swift       ← release notes per version (opened from the VERSION row in SettingsView)
RotationCard.swift        ← card for a ProgramRotation shown in TrainingView (next program, A·B breadcrumb)
RotationEditorView.swift  ← create/edit a ProgramRotation (sequence builder, next-up picker)
ExercisActivityAttributes.swift ← ActivityKit attributes for Live Activity (program name, accent color, exercise/set state)
LiveActivityManager.swift ← manages start/update/end of Live Activity during a strength session
WidgetDataStore.swift     ← writes WidgetSnapshot to App Group UserDefaults (group.rubenluthman.Exercis)
WidgetSnapshotBuilder.swift ← builds WidgetSnapshot from SwiftData (streak, last session, next program)
```

**Widget folder** (`ExercisWidget/`, separate target):
```
ExercisWidgetBundle.swift   ← WidgetBundle entry for the widget target
ExercisLiveActivity.swift   ← Live Activity layout (Dynamic Island + Lock Screen)
ExercisHomeWidget.swift     ← Home screen widget (small + medium): streak, last session, next program
WidgetShared.swift          ← WidgetSnapshot + WidgetDataStore + ProgramColor (copy for widget target)
ExercisWidget.entitlements  ← App Group: group.rubenluthman.Exercis
```

**App Group** (`group.rubenluthman.Exercis`):
- Must be enabled in Xcode for BOTH targets: Exercis and ExercisWidget (Signing & Capabilities → + → App Groups)
- `WidgetDataStore` reads/writes via `UserDefaults(suiteName: "group.rubenluthman.Exercis")`
- App target includes `WidgetDataStore.swift` + `WidgetSnapshot` + `WidgetSnapshotBuilder.swift`
- Widget target uses `WidgetShared.swift` (copy of WidgetSnapshot + WidgetDataStore + ProgramColor)
- `WidgetShared.swift` must NOT be added to the app target (causes redefinition errors)

---

## App Icon

Adaptive icon via Icon Composer (`Exercis/exercis.icon`). Produces automatic Default/Dark/Tinted variants.

**Layer setup:**
- `foreground` layer (`foreground.png`): white stripes shape on transparent background. **Glass effect intentionally disabled** (`glass: false`) — the stripes looked better without the Liquid Glass treatment applied to the foreground.
- Background layer: solid accent color managed by Icon Composer.

Do not re-enable `glass: true` on the foreground layer without testing visually — the decision to disable it was intentional.

---

## Theme.swift

Single source of truth for colors, fonts, button styles, and shared UI components.

### Colors

All colors are defined in `Assets.xcassets` as named color sets with automatic light/dark variants. `Theme.swift` exposes them as `Color` extensions.

**Structural accent colors** — aliases to palette rows:
```swift
Color.homeAccent    // → paletteIntenseRed  light #B73B3F / dark #F97775
Color.workoutAccent // → paletteGreen       light #23821F / dark #63BD5C
Color.historyAccent // → paletteLightBlue   light #0078B8 / dark #00B3F7
Color.appBackground // Color(.systemBackground)
Color.appDivider    // Color(.separator)
```

**Program color palette** — OKLCH L=0.5325 C=0.160, 16 hues at 15–30° intervals. `paletteGreen` (H=142.4°) is reserved for `workoutAccent` (cardio) and `paletteLightBlue` (H=232.4°) for `historyAccent` — both excluded from the program picker.
```swift
Color.paletteIntenseRed  // H=22.4°   light #B73B3F / dark #F97775
Color.paletteVermillion  // H=37.4°   light #B64019 / dark #F77C57
Color.paletteOrange      // H=52.4°   light #B04900 / dark #F18435
Color.paletteAmber       // H=67.4°   light #A75400 / dark #E58E00
Color.paletteYellow      // H=82.4°   light #995F00 / dark #D59800
Color.paletteLime        // H=112.4°  light #707400 / dark #A7AE00
Color.paletteChartreuse  // H=127.4°  light #527C00 / dark #89B639
Color.paletteSeafoam     // H=157.4°  light #008645 / dark #28C27C
Color.paletteTeal        // H=172.4°  light #008862 / dark #00C49A
Color.paletteCyan        // H=202.4°  light #008494 / dark #00C0D0
Color.paletteIndigo      // H=247.4°  light #0070C3 / dark #40ABFF
Color.paletteDarkBlue    // H=262.4°  light #3767C8 / dark #6DA2FF
Color.palettePurple      // H=292.4°  light #7155BF / dark #A98FFF
Color.paletteViolet      // H=307.4°  light #864DB3 / dark #C087F2
Color.paletteMagenta     // H=322.4°  light #9646A2 / dark #D37FDF
Color.palettePink        // H=352.4°  light #AE3B75 / dark #EE76AE
```
`Color.programPalette: [Color]` — array of all 16, used in the program color picker (excludes paletteGreen and paletteLightBlue).

**WCAG contrast against white (light mode):** all ≥4.5:1 (AA) except teal/cyan (4.4–4.5:1, AA-large — acceptable for buttons/headings, not small body text).

**⚠️ Yellow and lime on white:** `paletteYellow` (H=82.4°) and `paletteLime` (H=112.4°) are perceptually balanced with the rest of the palette in OKLCH, but yellow-green hues tend to look muddy on white backgrounds — a property of human vision, not a contrast failure (both pass AA). Test visually on white before using as program colors. If they don't hold up aesthetically: raise L slightly (e.g. to 0.57) for just these two, or drop them from the program palette.

### Typeface: Jost (only typeface)
```swift
Font.jost(_ weight: Font.Weight, size: CGFloat)
```

| Weight       | Used for                                           |
|--------------|----------------------------------------------------|
| Black 900    | "EXERCIS" on LockView                              |
| Bold 700     | Screen headings (17pt, kerning 2)                  |
| SemiBold 600 | Buttons, accent labels, large numbers (34pt)       |
| Medium 500   | Section labels, sub-labels, column headers (11–12pt, kerning 1.5) |
| Regular 400  | Body text, hints, dates (13–14pt)                  |

### Type size hierarchy

| Size    | Category                            | Examples                                                    |
|---------|-------------------------------------|-------------------------------------------------------------|
| 17pt    | Screen headings                     | "SETTINGS", "HISTORY"                                       |
| 14–15pt | Primary row text                    | Program names, cardio names, toggle titles                  |
| 13–14pt | Body / descriptions                 | Toggle descriptions, iCloud info                            |
| 12pt    | Section labels, action rows         | "STRENGTH PROGRAMS", "EXPORT TRAINING DATA", "START/END" in SessionTimePicker |
| 11pt    | Stat captions (below large numbers) | "STREAK", "BEST", "SESSIONS", "EFFORT"                      |
| 9pt     | Badge pills                         | "INCREASE", progression suggestions (pill format, stays 9pt)|
| 10pt    | Chart axis labels                   | Month abbreviations and Y-axis values in charts             |

**Rule:** no UI text below 11pt except badge pills (9pt) and chart axes (10pt).

### Button styles
- `FilledButtonStyle(accent:)` — filled, white text, height 50pt, `clipShape(RoundedRectangle(cornerRadius: 4))`
- `OutlineButtonStyle(accent:)` — accent-colored border, height 50pt

### Dynamic Type
`Font.jost()` uses `Font.custom(_:size:relativeTo:)` with a size-appropriate `TextStyle` as reference — Jost scales automatically with the user's iOS text size setting.

### ChartEmptyState

Shared view in Theme.swift — shows "No logged sessions yet." or "Need at least two sessions to show chart." based on `isEmpty`. Used by all four chart sheets (ExerciseChartSheet, CardioChartSheet, EffortChartSheet, CardioEffortChartSheet) for a consistent empty state when fewer than 2 data points exist — extracted from four identical copies during an app review.

### Scroll edge fade
`View.softScrollEdge()` in Theme.swift — applies a 20pt gradient mask along the top of a ScrollView (clear→black). Works on iOS 17+. Applied to all `ScrollView`s in the app (StrengthView, HistoryView). The mask affects rendering only, not hit-testing.

### Haptic feedback
| Event | Type |
|-------|------|
| Session saved (DONE / SKIP / drag-dismiss) | `.success` notification |
| Session deleted | `.warning` notification |
| Long press INCREASE badge | `.impact(.medium)` |
| NEXT field navigation (strength + cardio) | `.selection` |
| Expand/collapse section or month | `.selection` |

### Navigation bridge
`enableSwipeBack()` — View extension that re-enables `interactivePopGestureRecognizer` via a UIKit bridge (needed because `.toolbar(.hidden, for: .navigationBar)` disables swipe-back in iOS 17).

### Free business-logic functions (unit-testable)

All free functions in Theme.swift are unit-tested and kept free of SwiftUI/SwiftData dependencies.

| Function | Purpose |
|----------|---------|
| `epleyE1RM(weight:reps:)` | Epley formula for estimated 1RM |
| `estimatedCalories(met:bodyMass:seconds:)` | Calorie estimate via MET |
| `computeCurrentStreak(days:)` | Current training streak from `Set<Date>` |
| `computeBestStreak(days:)` | All-time best streak from `Set<Date>` |
| `progressionSuggestion(prevMax:shouldIncrease:bestSetReps:)` | Suggests next weight (+2.5 kg if INCREASE) and reps |
| `csvField(_:)` | RFC 4180-quotes a CSV field (comma/quote/newline) |
| `strengthCSV(_:)` | Generates CSV string for a strength session |
| `cardioCSV(_:)` | Generates CSV string for a cardio session |
| `formatWeight(_:)` | Formats Double → string without trailing zeros |
| `parseWeight(_:)` | Parses string → Double, accepts both period and comma |
| `displayWeight(_:imperial:)` | Converts stored kg → display string (lbs if imperial) |
| `displayDistance(_:imperial:)` | Converts stored km → display string (mi if imperial) |
| `parseWeightInput(_:imperial:)` | Parses displayed weight → kg for storage |
| `parseDistanceInput(_:imperial:)` | Parses displayed distance → km for storage |
| `weightLabel(_:)` | "KG" or "LBS" based on unit preference |
| `distanceLabel(_:)` | "KM" or "MI" based on unit preference |

---

## Design Rules

- System-adaptive background (`Color(.systemBackground)`), primary text (`.primary`) — adapts to dark mode automatically
- The accent color is the **only** color used — applied to headings, exercise names, buttons, and details
- No emoji, no icons beyond SF Symbols (chevron, xmark)
- Uppercase labels with letter spacing
- Thin **0.5pt dividers** via `ThinDivider`
- UI text is localized via the iOS standard localization system. **English is the base language** (all strings defined in English). Swedish is provided via `.strings` files. SwiftUI `Text()` with string literals localizes automatically; other strings use `String(localized:)`.
- Dates formatted with `appLocale()` (Theme.swift) — reads `@AppStorage("dateLocaleIdentifier")`: `""` = system locale, `"sv_SE"` = Swedish, `"en_US"` = English. User-controlled in SettingsView → TRAINING → DATE LANGUAGE.
- DONE button: filled in accent color, pinned to the bottom of the view (in `safeAreaInset`). Hidden when the effort picker is open.
- Back button: "←" only, no text, font regular 22pt, `.frame(width: 90, alignment: .trailing)`
- Horizontal padding: **24pt** consistently on all rows

---

## Data Models (SwiftData)

**Cascade delete on all relationships.**

```swift
@Model class WorkoutSession {
    var id: UUID; var date: Date; var startDate: Date; var healthKitID: UUID?; var effortScore: Int?
    var programId: UUID?      // links session to WorkoutProgram for prefill
    var programName: String?  // denormalized — used in CSV export
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]
}
@Model class ExerciseLog {
    var name: String; var orderIndex: Int; var session: WorkoutSession?
    // exerciseDefId: String? exists in the model but is not used yet
    @Relationship(deleteRule: .cascade) var sets: [SetLog]
}
@Model class SetLog {
    var setNumber: Int; var weight: Double; var reps: Int; var exerciseLog: ExerciseLog?
}
@Model class CardioSession {
    var id: UUID; var date: Date; var startDate: Date; var durationMinutes: Double
    var cardioType: String; var healthKitID: UUID?; var distanceKm: Double?; var effortScore: Int?
}
```

**`WorkoutProgram` / `ProgramExercise`** (SwiftData):
```swift
@Model class WorkoutProgram {
    var id: UUID; var name: String; var colorName: String; var sortIndex: Int
    var isOnTrainingPage: Bool = true   // shown on the Training tab
    var programConstraint: String = ""  // ProgramConstraint.rawValue — dims exercises in ExercisePickerView
    var useFixedReps: Bool = false       // locked reps mode — each exercise uses fixedReps instead of free input
    @Relationship(deleteRule: .cascade) var exercises: [ProgramExercise]
}
@Model class ProgramExercise {
    var exerciseId: String; var exerciseName: String; var sortIndex: Int; var setCount: Int
    var fixedReps: Int = 0              // fixed rep target; 0 = free input (only relevant when useFixedReps is true)
    var program: WorkoutProgram?
}
```

**`ProgramRotation`** (SwiftData):
```swift
@Model class ProgramRotation {
    var id: UUID; var name: String
    var programIds: [String]   // ordered UUID strings of WorkoutPrograms
    var currentIndex: Int      // index of the next-up program (wraps via % count)
    var sortIndex: Int
}
```
- `nextIndex` computed property: `currentIndex % programIds.count`
- Shown in TrainingView above standalone programs; tapping starts the program at `nextIndex`
- After DONE in StrengthView, `currentIndex` advances by 1 (wraps around)
- Supports 2–6 programs (displayed as A/B/C…); drafts work per-slot via the underlying program's ID
- Managed in Settings → ROTATIONS (create, edit, delete)

**`CardioType` enum** (in Models.swift, `Identifiable`):

26 cases with lowercase rawValues — grouped by category:
- **Machines**: `crosstrainer`, `cycling_stationary`, `rowing_machine`, `treadmill_run`, `treadmill_walk`, `stair_climber`, `ski_erg`, `assault_bike`
- **Outdoor**: `running`, `walking`, `hiking`, `road_cycling`, `mountain_biking`, `swimming`
- **Nordic**: `cross_country_skiing`, `ice_skating`
- **Water**: `kayaking`, `canoeing`
- **Other**: `climbing`, `boxing`, `battle_ropes`, `sled`, `rucking`
- **Calisthenics cardio**: `jump_rope`, `burpees`, `mountain_climbers`

Stored as `String` in `CardioSession` to avoid migration issues. Legacy uppercase rawValues are migrated on app launch via `migrateCardioTypes(context:)` in Models.swift.

`var tracksElevation: Bool` — `true` for: `hiking`, `running`, `walking`, `road_cycling`, `mountain_biking`, `cross_country_skiing`, `rucking`, `climbing`. Controls whether `CMAltimeter` is started in CardioView and whether `elevationGain` is sent to HealthKit.

`var met: Double` — MET value (Metabolic Equivalent of Task) per type, used by `estimatedCalories` for calorie calculation to HealthKit.

`var hkActivityType: HKWorkoutActivityType` — mapping to HealthKit activity type.

**`WorkoutDraft`** (Codable, persisted in UserDefaults):
```swift
struct WorkoutDraft: Codable {
    var exercises: [ExerciseDraft]  // ExerciseDraft: name, sets, shouldIncrease, previousMaxWeight
    var startTime: Date
    var collapsedExercises: [Int]   // defaults to [] when decoding older drafts
    var programId: String?          // defaults to nil when decoding older drafts
}
```
- Has a custom `init(from:)` for backwards compatibility — new fields with defaults decode silently from older JSON
- `suggestedWeight`/`suggestedReps` are **not** persisted in the draft — recalculated from history on prefill

**`ExerciseFormData`** (in-memory, not Codable):
```swift
struct ExerciseFormData {
    let def: ExerciseDef
    var sets: [SetFormData]
    var shouldIncrease: Bool
    var previousMaxWeight: Double
    var suggestedWeight: String  // "+2.5 kg if INCREASE, otherwise same" — shown as badge in ExerciseSection
    var suggestedReps: String
}
```

**Weight input**: accepts both period and comma as decimal separator (`parseWeight`).
**Weight display**: formatted with `formatWeight` (NumberFormatter, locale: .current).

**ModelContainer** registers `[WorkoutSession.self, CardioSession.self, WorkoutProgram.self]` — related models (ExerciseLog, SetLog, ProgramExercise) are included automatically via `@Relationship`. `ProgramRotation` is registered separately in `ExercisSchemaV1.models`.

---

## Exercises

Loaded from `Resources/exercises_def.json` via `ExerciseLibrary` (singleton). ~185 exercises with `status == "include"` are active.

**Exercise names are in English** — intentional. They are not localized via `.strings` and display in English regardless of device language. Stored in English in history (`ExerciseLog.name`) and CSV export.

`ExerciseDef` fields: `id` (stable key, used in `ProgramExercise.exerciseId`), `name` (shown in UI and stored in `ExerciseLog.name`), `aliases` (old names, migrated on launch; also searched in ExercisePickerView), `repRange`, `setRange`, `primaryMuscles`, `equipment`, `movement`, `contraindications`, `gifFile/gifSource`, `description`.

**Traceability fields** — kept for source tracking, never read by app code:
- `wgerId` / `wgerBaseId` — IDs in the [wger](https://wger.de) open exercise database the data was originally imported from
- `gifId` — numeric ID in the hasaneyldrm GIF source; matches the prefix of `gifFile` (e.g. `gifId: "0031"` → `gifFile: "0031-25GPyDY.gif"`). Useful if sourcing replacement media from the same repo.

**GIF assets are not committed** (`Exercis/Resources/GIFs/` is in `.gitignore`). On a new machine, restore them by cloning the source repo and running the copy script:
```bash
git clone --depth 1 https://github.com/hasaneyldrm/exercises-dataset.git .tmp/exercises-dataset
python3 -c "
import json, shutil, os
src = '.tmp/exercises-dataset/videos'
dst = 'Exercis/Resources/GIFs'
os.makedirs(dst, exist_ok=True)
with open('Exercis/Resources/exercises_def.json') as f:
    data = json.load(f)
for ex in data:
    if ex.get('gifFile') and ex.get('status') == 'include':
        s = os.path.join(src, ex['gifFile'])
        if os.path.exists(s):
            shutil.copy2(s, os.path.join(dst, ex['gifFile']))
"
rm -rf .tmp
```
- `rejectReason` — present on `status: reject` entries; documents why the exercise was excluded (`not_english`, `insufficient_data`, `not_gym_relevant`). Rejected entries are kept in the file to prevent re-importing them in future updates.

**`status` values:**
- `include` — active, shown in the exercise picker
- `retired` — replaced by another exercise; kept so history entries with the old name still resolve correctly. `ExerciseDef.find(name:)` searches active + retired.
- `reject` — excluded from the app; kept for import traceability. Never loaded by `ExerciseLibrary`.

**Key is `id`** in programs (`ProgramExercise.exerciseId`) but **`name`** in logged history (`ExerciseLog.name`) — important distinction. Never change `id` or `name` without adding the old value to `aliases` and bumping `migrationVersion` (current: 6).

**Retiring an exercise** — when an exercise is replaced and old data must be preserved in history:
- Set `status` to `"retired"` in the JSON — no migration, no deletion

**Hard deletion** requires an explicit delete step in `migrateExerciseNames`.

Exercise names in StrengthView are **tappable headings** that open the GIF/info via `GifSheet`. In HistoryView, names are tappable and open `ExerciseChartSheet` (e1RM progression via the Epley formula).

---

## Screens & Navigation

```
LockView → (Face ID) → MainTabView
                         ├── TrainingView (Training) → StrengthView (navigationDestination)
                         │                           → CardioView (navigationDestination)
                         ├── HistoryView (History)
                         ├── ProfileView (Profile)
                         └── SettingsView (Settings) → ProgramEditorView (sheet)
```

- 4 tabs: **Training · History · Profile · Settings**
- `navigationDestination(item:)` for StrengthView and CardioView — swipe-back via `enableSwipeBack()`
- **DONE** saves and returns via dismiss; **←** (swipe-back) saves a draft via `onDisappear`

### LockView (no accent color)
- "EXERCIS" Jost Black 900, centered vertically
- `faceid` SF Symbol (~40pt) as retry button, `.secondary` color — shown only if Face ID failed
- `auth.authenticate()` triggered in `.onAppear` and via the retry icon

### TrainingView (Training tab, accent color per program / workoutAccent)
- Shows selected strength programs (filter: `isOnTrainingPage == true`) under STRENGTH
- Shows selected cardio types (from `selectedCardioTypes` AppStorage) under CARDIO
- Tap program → navigates to StrengthView; tap cardio type → navigates to CardioView with `initialType`
- Draft indicator: pencil icon on programs with an active draft; "CONTINUE" text on cardio types with an active draft
- Empty state if nothing is configured

### StrengthView — Strength training (accent color: homeAccent / program color)
- Header: "STRENGTH TRAINING" 17pt bold, kerning 2 + abbreviated date 13pt
- Form **auto-prefills** per program from the most recent session with the same `programId`
- Set count per exercise defined in the program (1–6, default 3)
- Column headers: **SET, KG, REPS** — layout: SET=maxWidth leading, KG=80pt leading, REPS=120pt trailing
- **Collapsible sections**, **INCREASE badge** (long press 500ms), **rest timer** (triggered after the last reps field — configured globally in SettingsView: 0/30/60/90/120s, `@AppStorage("restTimerSeconds")`, default 90s)
- **PR detection**: compares e1RM against history, shows a PR indicator on DONE
- **Progression suggestions**: badge below the set number (`→ X kg × Y reps`) in accent color; disappears once you start typing. Suggestion = best set from the previous session; +2.5 kg if INCREASE is active
- **Keyboard toolbar**: NEXT + DONE in homeAccent
- **Draft**: saved to UserDefaults (WorkoutDraft including collapse state and programId)
- **Live Activity**: started on session begin via `LiveActivityManager.shared` — shows current exercise, set number, and progress on Dynamic Island / Lock Screen. Updated per set, ended on DONE or dismiss.
- Date tappable → `SessionTimePicker`

### CardioView — Cardio training (accent color: workoutAccent)
- Opened with `initialType: CardioType?` — scrolls to the correct accordion directly
- **Accordion of selected cardio types** — separated by ThinDivider
- **Time tracked automatically**: start = when CardioView opens, end = DONE. No manual time entry.
- Only manual input: **distance** (for types that track distance)
- **Keyboard toolbar**: DONE only (one field = no NEXT)
- **Draft**: saves active type + optional distance to UserDefaults
- Date tappable → `SessionTimePicker` (changing start drags end along, end adjustable freely — supports sessions past midnight)
- DONE → effort picker → saves `CardioSession`, logs to HealthKit

### HistoryView (accent color: historyAccent)
- Header: "HISTORY" 17pt bold + "←" 90pt trailing
- `HistoryEntry` enum (`.workout` / `.cardio`) interleaved, sorted newest first
- **Month groups** (`MonthGroup`): entries grouped by year/month, heading in historyAccent with strength/cardio counts. Collapsible — most recent month open, others closed on first load. Year heading (`HistoryRow.year`) shown only if data spans multiple years — tappable, opens yearly summary.
- Each row expandable (HistoryCard / CardioCard) — most recent entry opens automatically
- Delete via × button or context menu — shows `.alert("Delete session?")` with a destructive action
- Delete also removes the HealthKit entry via `HealthKitManager.deleteWorkout(uuid:)`
- Strength exercises shown in historyAccent; cardio type shown in **historyAccent** (not workoutAccent — everything in the history context is blue)
- **Tappable names**: exercise names in HistoryCard open `ExerciseChartSheet`; cardio type in CardioCard opens `CardioChartSheet`

### ExerciseChartSheet / CardioChartSheet / EffortChartSheet (accent color: historyAccent)
- Presented as `.sheet` with `.presentationDetents([.medium, .large])` from HistoryCard/CardioCard
- Fetches all data via `@Query` (inherits modelContainer from the environment)
- Line chart (Swift Charts) with point markers in accent color
- X-axis shows month abbreviations; if data spans multiple years, a two-digit year is appended (e.g. "JAN\n25")
- Swedish month abbreviations — periods in abbreviations are stripped
- Stats row per sheet:
  - ExerciseChartSheet: BEST · LATEST · SESSIONS (unit: kg); toggle **1RM / VOL** in the header — VOL = sets × reps × kg per session
  - CardioChartSheet: LONGEST · LATEST · SESSIONS (unit: min/km); toggle TIME/DISTANCE if distance data exists
  - EffortChartSheet: EASIEST · LATEST · HARDEST (unit: /10, shown in gray 14pt); opened from the effort row in HistoryCard (strength sessions)
  - CardioEffortChartSheet: EASIEST · LATEST · HARDEST per cardio type; opened from the effort row in CardioCard
  - PeriodSummarySheet: STRENGTH · VOLUME · CARDIO · TIME + **monthly view**: dot row (one circle per day, red=strength, green=cardio, gradient=both, gray=none); **yearly view**: bar chart per month. Opened from the month heading (detent `.height(280)`) and year heading (detent `.medium`) in HistoryView. Volume shown in kg (<1000) or tonnes (≥1000). Zero values shown as `—`.
- Empty state if fewer than 2 data points

### ProfileView (no accent color)
- Profile photo (PhotosPicker) + editable name
- **Top stats**: STRENGTH · CARDIO · VOLUME · CARDIO TIME in four columns
- **Streak**: current streak as 72pt black number + BEST, 14-day dot row (blue=active, gray=rest, today has an outline)
- **Last session**: title (program name or cardio type), subtitle (exercises/minutes), relative time + calendar date
- **Personal records**: top-8 e1RM per exercise, ranked 1–8, e1RM in historyAccent
- **Weekly average**: AVG/WEEK · THIS WEEK · BEST WEEK

### SettingsView (no accent color)
- Sections: STRENGTH PROGRAMS · CARDIO TYPES · LIMITATIONS · TRAINING · HEALTH · PRIVACY · REMINDERS · DATA · ABOUT
- **REMINDERS**: toggle, weekday buttons (Mon–Sun), time picker (auto-set from last session start, fallback 17:00)
- **DATA**: iCloud Backup explanation (what is and isn't backed up), CSV export via `UIActivityViewController`
- **ABOUT → VERSION**: opens `WhatsNewSheet` with release notes

**`WhatsNewSheet.swift` — maintenance rule:** the `entries` array is hardcoded and does **not** update automatically. Before every commit, ask: did this change anything a user would notice? If yes:
1. Add a `WhatsNewEntry` (icon, color, title, body) at the top of `entries` in the same commit — not as an afterthought.
2. Assess the version bump using SemVer (`MAJOR.MINOR.PATCH`): bug fix → PATCH, new user-visible feature → MINOR, breaking change → MAJOR. Update `MARKETING_VERSION` in `project.pbxproj` accordingly.

Do not skip this because the change "feels small" — that judgment belongs here, not silently.
- `#if DEBUG` section: RESET ONBOARDING

---

## Apple Health

`HealthKitManager` (singleton `struct`) saves an `HKWorkoutBuilder` to Apple Health:

| Session | ActivityType | Time |
|---------|-------------|------|
| Strength training | `.traditionalStrengthTraining` | start = when StrengthView opens, end = DONE |
| crosstrainer | `.elliptical` | end = now, start = now − minutes |
| cycling_stationary, road_cycling, mountain_biking, assault_bike | `.cycling` | end = now, start = now − minutes |
| rowing_machine, ski_erg, kayaking, canoeing | `.rowing` | end = now, start = now − minutes |
| hiking, rucking, crosstrainer, stair_climber | `.hiking` | end = now, start = now − minutes |
| running, treadmill_run | `.running` | end = now, start = now − minutes |
| walking, treadmill_walk | `.walking` | end = now, start = now − minutes |
| sled | `.functionalStrengthTraining` | end = now, start = now − minutes |

- Authorization requested on every StrengthView/CardioView open (`requestAuthorization()`) — iOS handles "already granted" silently
- All calls guarded with `HKHealthStore.isHealthDataAvailable()` — no-op on simulator
- `healthKitID: UUID?` saved on the session object to enable deletion
- Calories calculated via `estimatedCalories(met:bodyMass:seconds:)` — MET from `CardioType.met`, body weight read from HealthKit (fallback 75 kg)
- **iOS 18+**: effort score saved as `HKQuantityType(.workoutEffortScore)` via `store.relateWorkoutEffortSample(_:with:activity:)` — applies to both strength and cardio sessions

---

## UserDefaults Keys

| Key | Type | Owner | Purpose |
|-----|------|-------|---------|
| `hasDraft` | Bool (@AppStorage) | TrainingView/StrengthView | Whether a strength draft exists |
| `hasCardioDraft` | Bool (@AppStorage) | TrainingView/CardioView | Whether a cardio draft exists |
| `workoutDraft` | Data | UserDefaults | WorkoutDraft (JSON) including collapse state |
| `cardioDraftType` | String | UserDefaults | Type of the active cardio draft |
| `cardioDraftStartTime_{TYPE}` | Double | UserDefaults | Start time (timeIntervalSince1970) for a paused cardio session |
| `cardioDraftDistance_{TYPE}` | String | UserDefaults | Distance (km) for a paused cardio session |
| `cardioSavedDuration_{TYPE}` | String | UserDefaults | Last saved duration per cardio type (calculated from time) |
| `cardioSavedDistance_{TYPE}` | String | UserDefaults | Last saved distance per cardio type |
| `cardioEffortScore_{TYPE}` | Int | UserDefaults | Last saved effort per cardio type (initial value in picker) |
| `workoutEffortScore` | Int | UserDefaults | Last saved effort for strength sessions (initial value in picker) |
| `increaseExercises` | [String] | UserDefaults | Exercise names with an active INCREASE badge |
| `increaseCardioTypes` | [String] | UserDefaults | Cardio types with an active INCREASE badge |
| `exerciseNameMigrationVersion` | Int | UserDefaults | Version of the last-run name migration (bump on exercise changes) |
| `bodyLimitations` | String (@AppStorage) | SettingsView/ExercisePickerView | Comma-separated BodyLimitation.rawValues — dims exercises that load the selected joints |
| `reminderEnabled` | Bool (@AppStorage) | SettingsView | Whether training reminders are enabled |
| `reminderWeekdays` | String (@AppStorage) | SettingsView | Comma-separated weekdays (1=Sun, 2=Mon…7=Sat) |
| `reminderHour` | Int (@AppStorage) | SettingsView | Reminder hour (24h), auto-set from last session start |
| `reminderMinute` | Int (@AppStorage) | SettingsView | Reminder minute |
| `onboardingCompleted` | Bool (@AppStorage) | ExercisApp/OnboardingView/SettingsView | Whether onboarding has been completed (DEBUG: can be reset in SettingsView) |
| `lockEnabled` | Bool (@AppStorage) | ExercisApp/SettingsView | Whether Face ID lock is enabled |
| `profileName` | String (@AppStorage) | ProfileView | User's display name |
| `restTimerSeconds` | Int (@AppStorage) | StrengthView/SettingsView | Global rest timer duration (0/30/60/90/120s, default 90) |
| `selectedCardioTypes` | String (@AppStorage) | OnboardingView/TrainingView/SettingsView | **Ordered** comma-separated `CardioType.rawValue`s shown on the Training tab — order is preserved (not a Set). Toggle on appends to end; toggling off removes from position. Reorder in SettingsView updates this directly. Reset to `allCases` order on onboarding completion. |
| `useImperialUnits` | Bool (@AppStorage) | SettingsView + all views/cards showing weight/distance | Unit preference: KG/KM (false) or LBS/MI (true) — converted at presentation via `displayWeight`/`displayDistance` |
| `dateLocaleIdentifier` | String (@AppStorage) | SettingsView / appLocale() in Theme.swift | Date formatting locale: `""` = system, `"sv_SE"` = Swedish, `"en_US"` = English |
| `healthKitSyncEnabled` | Bool (@AppStorage) | SettingsView | Whether sessions are saved to Apple Health |
| `healthKitWeightEnabled` | Bool (@AppStorage) | SettingsView | Whether body weight is read from Apple Health for calorie calculation |

---

## Exercise Picker Constraint System

The exercise picker has two independent signals that dim exercises (opacity 0.4) and move them under "NOT RECOMMENDED" at the bottom of the list:

**Body limitations** (global, `@AppStorage("bodyLimitations")`):
- Set in SettingsView → LIMITATIONS with toggles per joint
- `BodyLimitation` enum in ExerciseLibrary.swift: KNEE / SHOULDER / BACK / ELBOW / WRIST / HIP
- Each joint maps to specific `contraindications` tags in exercises_def.json

**Program constraints** (per program, `WorkoutProgram.programConstraint`):
- Set in ProgramEditorView → Constraint with a chip picker
- `ProgramConstraint` enum: NONE / PUSH / PULL / LEGS / UPPER BODY / BODYWEIGHT
- Seeded programs get the right constraint (e.g. Push → "push", Bodyweight → "bodyweight")
- Passed into ExercisePickerView as a parameter

**Filter chips** (session-scoped, reset on dismiss):
- MUSCLE → `MuscleGroup` enum (6 groups → primaryMuscles mapping)
- EQUIPMENT → equipment raw values
- MOVEMENT → movement raw values
- Opens FilterSheet (`.sheet`, `.medium`/`.large` detents) with checkboxes

All three systems are additive — an exercise is dimmed if any signal matches.

---

## AuthManager.swift

- `ObservableObject` + `@Published var isAuthenticated: Bool`, used as `@StateObject` in RootView
- Completion handler calls back on `DispatchQueue.main.async` — LAContext calls back on a background thread

---

## SwiftData Notes

- `ModelContainer` configured in `ExercisApp.swift` (CloudKit not enabled)
- All relationships have `deleteRule: .cascade`
- HistoryView sort order: newest first
- Schema versioning in place: `ExercisSchemaV1` (`VersionedSchema`, version 1.0.0) + `ExercisMigrationPlan` (`SchemaMigrationPlan`, empty `stages` array) in Models.swift — `ModelContainer` created via `Schema(ExercisSchemaV1.models)` and `migrationPlan: ExercisMigrationPlan.self` in ExercisApp.swift. For future field renames/removals: add `ExercisSchemaV2` + a `MigrationStage` to the plan, bump `versionIdentifier`
- `try? context.save()` used throughout — errors are not logged (acceptable at current scale)

---

## Unit Flexibility

Imperial support is **implemented** via `useImperialUnits` (@AppStorage, toggled in SettingsView → UNITS: "KG / KM" / "LBS / MI"):
- Conversion happens at presentation, not in storage — `displayWeight(_:imperial:)` / `displayDistance(_:imperial:)` (kg→lbs ×2.20462, km→mi ×0.621371)
- Input is converted back to metric on parse — `parseWeightInput(_:imperial:)` / `parseDistanceInput(_:imperial:)`
- Labels via `weightLabel(_:)` / `distanceLabel(_:)`
- All free functions live in Theme.swift, are unit-tested, and have no SwiftUI/SwiftData dependencies

Time is still stored as raw minutes (`Double`, `durationMinutes`) with no unit switching — only KG/KM ↔ LBS/MI is supported today.

---

## Planned Features

See [ARCHITECTURE.md](ARCHITECTURE.md) for design decisions and architectural rationale.

See [ROADMAP.md](ROADMAP.md) for all planned features, decided design choices, and parked proposals.

---

## Hard Rules

1. Deployment target **iOS 17**
2. **iPhone only** (iPad not supported)
3. **Portrait only**
4. `NSFaceIDUsageDescription` in Info.plist
5. `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` in Info.plist
6. CloudKit not enabled (requires a paid Apple Developer account)
7. Jost is the **only** typeface — no system fonts
8. Accent color is the **only** color beyond system colors (`.primary`, `.secondary`, `Color(.systemBackground)`)
9. Weight always stored as `Double`
10. UI text is localized — English as base language, Swedish via `.strings`
