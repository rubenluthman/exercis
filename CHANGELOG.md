# Changelog

---

## v0.3.0 — 2026-06-04
*Navigation, cardio logging, and the exercise database overhauled.*

**New**
- TrainingView — new home screen (Training tab) shows the user's selected programs and cardio types; tap to start a session directly
- 4-tab navigation: Training · History · Profile · Settings
- Program management in Settings — toggle which programs appear on the Training tab, edit content
- Cardio types in Settings — toggle which types are shown
- Automatic time tracking for cardio — duration measured from when the view opens to DONE; no manual entry
- SessionTimePicker: changing the start time automatically drags the end time along (preserving session length); supports sessions past midnight
- Fuzzy search in the exercise picker via Fuse.swift — finds the right exercise even with typos
- Aliases and descriptions for all 186 exercises in exercises_def.json
- Exercise description shown in GifSheet info view

**Improvements**
- Swipe-back works from both strength and cardio sessions (navigationDestination instead of fullScreenCover/sheet)
- GIF loading via base64 embedding in WKWebView — works around iOS file system restrictions
- Data migration v5: legacy exercise names (Barbell Back Squat, Neutral-Grip Incline Dumbbell Bench Press, Neutral-Grip Lat Pulldown) migrated to correct ExerciseDef names
- Portrait-only and iPhone-only enforced in build settings

**Under the hood**
- `WorkoutProgram` gained `isOnTrainingPage: Bool` field
- `CardioType` implements `Identifiable`
- `CardioField` enum simplified (duration cases removed)
- GIFs added to .gitignore
- ExerciseDef: `aliases` and `description` fields added to JSON schema and Swift loader

---

## v0.2.0 — 2026-06-01
*The big rebuild. The app went from a personal training tool to a generalizable platform.*

**New**
- Workout programs — seven built-in (Full Body, Upper Body, Lower Body, Push, Pull, Legs, Bodyweight) with individual colors from a curated 12-hue OKLCH palette
- Onboarding — new installs choose programs and cardio types before the first session
- TabView replaces HomeView — Strength, Cardio, and History as permanent tabs; settings accessed via gear icon in the nav bar
- Exercise library — 180+ exercises loaded from JSON with muscles, equipment, movement patterns, and GIF animations
- 26 cardio types (machines, outdoor, Nordic, water, other, calisthenics) — user selects their own in onboarding
- Profile view with avatar, name, and lifetime statistics
- Settings — HealthKit toggles, Face ID toggle

**Improvements**
- Strength session accent color follows the active program's color instead of a fixed app color
- Prefill from the most recent session per program (not globally the last session)
- Cardio types filtered to the user's selection from onboarding

**Under the hood**
- `ExerciseDef` moved from a hardcoded struct to a JSON-driven `ExerciseLibrary`
- New `WorkoutProgram` model with `ProgramExercise` junction entity
- CardioType enum extended with 22 new types; raw values migrated from Swedish to language-neutral IDs

---

## v0.1.0 — 2026-05-27
*Initial version. Built for a single, fixed training program.*

The app was originally called "Träning" — renamed to "Exercis" the same evening.

- Five fixed exercises: Barbell Back Squat, Incline Dumbbell Bench Press, Romanian Deadlift, Seated Cable Row, Lat Pulldown
- Three cardio types: Cross Trainer, Bike, Rowing Machine (Hiking added shortly after)
- Log strength sessions with weight and reps per set — prefill from the previous session
- History with month groups, expandable cards, and per-exercise progression (e1RM via the Epley formula)
- Effort score (1–10) per session
- Apple Health integration — saves HKWorkout with calorie estimate via MET × body weight
- Face ID lock on app launch
- Period summary — monthly and yearly view with bar charts
- Draft system — an interrupted session resumes automatically
- Session time editing — adjust start/end after the fact
- OKLCH palette with 12 hues implemented (2026-05-28)

---

*Maintained with Claude Code.*
