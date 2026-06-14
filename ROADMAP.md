# Exercis – Roadmap

Everything planned, decided, and parked in one place. Updated continuously during sessions and app reviews.

**Workflow:** all items here are shared — we discuss and decide together whether something gets built, deferred, or dropped. When something ships, move it to **Done** at the bottom. Don't just strike it where it stands.

---

## Up next / under discussion

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
- **macOS companion app** — lightweight macOS app for logging sessions retroactively and managing programs from a desktop. Shares SwiftData models and business logic with the iOS app; CloudKit sync is a prerequisite for data to move between devices.
- **watchOS app** — quick set/reps logging directly from the wrist during a session. `exercis.icon` already has `watchOS` in `supported-platforms.circles` so the icon is ready. Requires CloudKit sync.

---

## Considering

- **Exercise variant metadata** — add a `variant` field to `ExerciseDef` (e.g. `"seated"` / `"standing"` / `"both"`) and display it as a discrete chip in GifSheet. Background: GIFs can show one variant (e.g. standing) for exercises that are equally valid seated — a chip is structured data that can be searched and filtered, unlike a freeform caption. Not a priority for single-user use.

---

## Codebase

- **31 exercises without GIFs** — active exercises with no `gifFile` entry. App handles it gracefully (no animation shown). Source is hasaneyldrm/exercises-dataset; these exercises simply weren't in that library. Full list: Axe Hold, Bent High Pulls, Body Squats, Butterfly Narrow Grip, Cable External Rotation, Cable Woodchoppers, Car Push, Close-Grip Bench Press, Deadhang, Depth Jumps, Duck Walks, French Press (Skullcrusher) Sz-Bar, Full Sit Outs, Hand Grip, Hercules Pillars, High Knee Jumps, High Pull, Hollow Hold, Incline Plank With Alternate Floor Touch, Leg Raises Standing, Mgm Machine, Shotgun Row, Side Raises, Smith Machine Close-Grip Bench Press, Straight-Arm Pulldown (Bar Attachment), Triceps Bench Press One Barbell, Trunk Rotation With Cable, Upper External Oblique, Wall Push-Up, Yolk Walks, Z Curls.

---

## Multi-user prerequisites

The app is intentionally single-user. This section documents every change required before multi-user can be introduced — not a priority, just a complete record so nothing is missed when the time comes.

**Data model (SwiftData migration required for each):**
- Add `owner: String` (or a `User` model) to `WorkoutSession`, `CardioSession`, `WorkoutProgram` — the three root models; child models (ExerciseLog, SetLog, ProgramExercise) inherit via relationship
- Scope all `@Query` and `FetchDescriptor` calls with a user predicate — 12+ call sites across the app
- `seedDefaultProgramsIfNeeded` and `migrateExerciseNames`/`migrateCardioTypes` use global UserDefaults flags — must be keyed per user

**Authentication:**
- `AuthManager` only knows Face ID on/off for the device owner — needs user identity (login, account switching, or at minimum a user ID passed through the app)

**UserDefaults / AppStorage (19+ keys):**
- All keys are device-global today — preferences like `restTimerSeconds`, `useImperialUnits`, `dateLocaleIdentifier`, `selectedCardioTypes`, `reminderEnabled`, and all draft/effort/INCREASE keys must be namespaced per user ID

**Profile:**
- `profileName` stored as a single global AppStorage key
- Profile image saved as `profile.jpg` — hardcoded filename; would be overwritten by a second user

**CSV export:**
- Exports all sessions without user filter
- Filenames are hardcoded — should include a user identifier

**HealthKit:**
- `fetchBodyMass()` reads "the" user's weight with no user context — fine for single user, ambiguous in a shared-device scenario

**Widget + Live Activity:**
- `WidgetDataStore` uses a single key `"widgetSnapshot"` — no user namespace
- `LiveActivityManager` manages one global activity instance

---

## Out of scope

- **Mid-session exercise swap** — swap an exercise mid-session without breaking the structure; save original + replacement in the log
- **Per-exercise rest timer** — default stored in `ProgramExercise.restSeconds` instead of a global AppStorage setting
- **ExerciseDef → SwiftData `@Model`** — no practical need, prefill works via `programId`
- **HKWorkoutActivity per exercise** — no way to distinguish movement from rest, produces no meaningful data

---

## Long-term

- **Siri integration via App Intents** — trigger common actions (start a session, log cardio) via Siri or the Shortcuts app. `AppIntents` is the only integration path as of iOS 27 — SiriKit is formally deprecated with a ~2–3 year support window (approx. iOS 29 / fall 2028). The new Gemini-powered Siri routes exclusively through App Intents; apps without it are invisible to Siri.
- **HIIT** — structured HIIT as its own program type, distinct from strength and cardio; timer-driven with configurable intervals and rounds

---

## Done

- ~~App icon redesign — three bold diagonal stripes in brand colors (#23821F green, #B73B3F red, #0078B8 blue), scaled to 65% in Icon Composer~~
- ~~Program rotations — A/B/C rotation support with ProgramRotation SwiftData model; RotationCard and RotationEditorView; rotation auto-advances on session save~~
- ~~Expand alias coverage in `exercises_def.json` — 1 261 alternative names added across all exercises via three pipeline passes (ChatGPT, Gemini, Claude Opus); aliases included in ExercisePickerView search~~
- ~~User-controlled date language — SYSTEM / SV / EN in SettingsView, `appLocale()` replaces hardcoded `sv_SE` everywhere~~
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
- ~~App review 2026-06-10 — fixed hardcoded Swedish "ÖVNINGAR" in SettingsView; added 10 missing sv.lproj keys (REMINDERS, TRAINING REMINDERS, DATE LANGUAGE, AVG/WEEK, THIS WEEK, BEST WEEK, sessions, session); translated Swedish comment in Theme.swift~~
- ~~Locked reps mode per workout program~~
- ~~Repo renamed to `exercis` (lowercase), made public; all documentation translated to English~~
- ~~Global exercise editing in StrengthView — pencil icon in session header opens a sheet with reorder, delete, and add exercise~~
