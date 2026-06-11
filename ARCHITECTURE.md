# Architecture

## Overview

Exercis is a personal workout logger for iPhone. It records strength and cardio
sessions, tracks progression over time, and surfaces personal records and
streaks. It currently has one user — the developer.

The app is offline-first. All data lives on device in SwiftData. There is no
server, no account system, and no sync infrastructure beyond standard iCloud
device backup.

## Stack

| Layer          | Technology                        | Notes                                              |
|----------------|-----------------------------------|----------------------------------------------------|
| UI framework   | SwiftUI                           | Entire UI; no UIKit views                          |
| Data layer     | SwiftData                         | On-device persistence; no CloudKit sync            |
| Health         | HealthKit                         | Workouts written on session completion             |
| Authentication | LocalAuthentication               | Face ID → passcode fallback; no custom credentials |
| Notifications  | UserNotificationCenter            | Training reminders only                            |
| Live Activity  | ActivityKit                       | Dynamic Island + Lock Screen during strength sets  |
| Widgets        | WidgetKit                         | Home screen widget via App Group shared data       |
| Charts         | Swift Charts                      | Progression charts; no third-party chart library   |
| Target OS      | iOS 17+, iPhone only, portrait    | iPad and landscape explicitly out of scope         |

## Data model

SwiftData with three registered root models: `WorkoutSession`, `CardioSession`,
`WorkoutProgram`. Related models (`ExerciseLog`, `SetLog`, `ProgramExercise`)
are reachable via `@Relationship` and do not need to be listed in the
`ModelContainer` schema.

All relationships use `deleteRule: .cascade`. Deleting a session removes all
its exercise logs and sets.

### Storage units

Weight is always stored in kilograms (`Double`), distance always in kilometers
(`Double`). Unit conversion (kg↔lbs, km↔mi) happens at presentation time only,
via `displayWeight` / `displayDistance` in Theme.swift. SwiftData fields never
change on a unit switch — no migration is needed when the user toggles imperial.

### HealthKit IDs

Every saved session stores a `healthKitID: UUID?`. This enables deleting the
corresponding HealthKit entry when a session is deleted from history. Without
this, HealthKit entries would accumulate independently of app data.

### Cardio type storage

`CardioType` is stored as a `String` rawValue in `CardioSession`, not as an
enum. This avoids SwiftData migration when new cardio types are added. Legacy
uppercase rawValues are migrated to lowercase on app launch via
`migrateCardioTypes(context:)`.

## Exercise library

Exercises are defined in `exercises_def.json` — a static file bundled with the
app. The library is loaded once at launch via `ExerciseLibrary` (singleton).

Exercise names are in English and are not localized. This is intentional: names
are stored verbatim in `ExerciseLog.name` and appear in CSV exports. Localizing
them would break history lookups and exports for anyone who switches device
language.

### Name stability

`ExerciseLog.name` stores the display name as a plain string, not an ID. This
means renaming an exercise in the JSON is a breaking change for history. The
migration system (`migrateExerciseNames`, `exerciseNameMigrationVersion`) exists
specifically to handle this: old names are listed in `aliases`, and history
entries are rewritten on launch when the version counter is bumped.

The `id` field is used only in programs (`ProgramExercise.exerciseId`) for
prefilling sessions — it does not appear in logged history.

## Authentication

Face ID via `LAContext` with `.deviceOwnerAuthentication` — the policy that
automatically falls back to the device passcode. There is no custom password,
no session token, and no server-side auth. The lock screen is a local UI gate,
not a security boundary in the cryptographic sense.

## Sync and backup

iCloud backup is enabled via standard device backup — the SwiftData store is
included automatically. CloudKit sync is explicitly disabled. Enabling it
requires a paid Apple Developer Program account and introduces significant
complexity (conflict resolution, schema versioning constraints, multi-device
state). For a single-user app, backup is the right tradeoff.

## Widget data flow

The home screen widget cannot access SwiftData directly (separate process).
Data is passed via `UserDefaults` in a shared App Group
(`group.rubenluthman.Exercis`). `WidgetSnapshotBuilder` reads from SwiftData
and writes a `WidgetSnapshot` struct; the widget reads the same struct from the
shared defaults. `WidgetShared.swift` (in the widget target) is a copy of the
shared types — it must not be added to the app target to avoid redefinition
errors.

## GIF assets

Exercise GIFs are sourced from
[hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
and are not committed to this repo (binary files, `.gitignore`). See CLAUDE.md
for the restore script.

## Scope

Exercis is a personal training log. It is not:

- A coaching or programming app (it does not prescribe workouts)
- A social or multi-user app
- A synced or cloud-first app
- An App Store product (built for personal use; no analytics, no IAP, no
  review prompts)

Every absent feature is a deliberate decision, not an oversight.
