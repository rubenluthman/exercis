# Exercis – Roadmap

Allt planerat, beslutat och parkerat på ett ställe. Uppdateras löpande under sessioner och vid apprevision.

**Arbetsflöde:** när något är klart — flytta det till **Klart**-sektionen längst ner. Stryk inte bara över det där det står. Håll två kategorier isär: Rubens explicita beslut och Claudes rekommendationer — det ska aldrig vara oklart vilken kategori något tillhör.

---

## Rubens beslut (ej byggt)

---

## Claudes rekommendationer

### Kodbas

- **`try!` på produktionens ModelContainer** ([ExercisApp.swift:27](Exercis/ExercisApp.swift#L27)) — om SwiftData-containern misslyckas initiera (skadad store, misslyckad migration, fullt lagringsutrymme) kraschar appen direkt vid uppstart utan återhämtning eller felmeddelande. Värt att fånga felet och visa ett enkelt felmeddelande (eller falla tillbaka på en in-memory-store) istället för hård krasch — särskilt eftersom `ExercisMigrationPlan` nu existerar och framtida schemaändringar ökar risken
- **`.foregroundColor` vs `.foregroundStyle`-blandning** — 125 förekomster av det sedan iOS 15 föråldrade `.foregroundColor(_:)` mot 103 av `.foregroundStyle(_:)`, spritt över i princip alla vyer (CardioCard, HistoryCard, ProfileView, StrengthView, chart sheets m.fl.). Mekanisk migrering är oftast en 1:1-ersättning för rena `Color`-värden, men bör göras i en samlad insats för att undvika att nya filer fortsätter blanda mönster

### Inför App Store (kräver Developer-konto)

- **CloudKit-sync** — utan det förlorar användaren all data vid telefonbyte utan aktiv backup; första prioritet när betalt konto finns
- **GIF-licens** — byt hasaneyldrm-källa mot licensierad (ExerciseDB Pro) innan submission
- **App Group aktivering** — `group.rubenluthman.Exercis` måste aktiveras i Xcode Signing & Capabilities för båda targets (Exercis + ExercisWidget) för att widgeten ska fungera

---

## Parkerat (avskrivet)

**Rubens beslut:**
- **Övningsbyte intra-pass** — byt övning mitt i ett pass utan att förstöra strukturen; spara original + ersättning i loggen
- **Rest-timer per övning** — default lagrad i `ProgramExercise.restSeconds` istället för global AppStorage-inställning
- **HIIT-timer** — oklart use case
- **4-tab-layout** — final, förhandlas inte
- **Apple Watch-app** — Ruben har ingen klocka
- **Siri Shortcuts** — single-user-app, låg prioritet

**Claudes förslag (avskrivna):**
- **TabView-omstrukturering** — 3 tabbar avskrivet; nuvarande 4-tabbar med samlad Träning-tab är rätt
- **ExerciseDef → SwiftData `@Model`** — inget praktiskt behov, prefill fungerar via `programId`
- **HKWorkoutActivity per övning** — rörelse/vila går inte att särskilja, ger ingen meningsfull data
- **Swift Packages** (`swift-algorithms`, `swift-collections`) — inte motiverat förrän appen växer
- **`sv_SE` hårdkodat** — avsiktligt val för svensk single-user-app, inget att åtgärda

---

## Klart

- [x] Onboarding — 3 steg (program-grid + konditionscheckboxar + Apple Health), standardprogram seedas
- [x] GIF-system — 155 övningar med GIF (accentfärg + tryckbar), GifSheet med WKWebView + muskelinfo
- [x] Övningsbeskrivningar — 186 granskade, 8 faktafel åtgärdade
- [x] Begränsningsfilter — kroppsbegränsningar + programbegränsningar i ExercisePickerView
- [x] Enhetssystem lbs/miles
- [x] TrainingView — Träning-tab med program + konditionsformer
- [x] Automatisk tidsloggning för kondition
- [x] CSV-export
- [x] Haptics centraliserade
- [x] Lokalisering — engelska basspråk, svenska via sv.lproj
- [x] SwiftData VersionedSchema v1 + ExercisMigrationPlan
- [x] `#if DEBUG` OSLog-loggning på alla context.save()
- [x] XCTest-target — Epley, viktsformatering, CardioType-mappning, WorkoutDraft, ExerciseLibrary, HistoryView-gruppering, HealthKit-kalorier, PR-detektion, ProgramSeeder, CSV-export, PeriodSummary-aggregationer, LiveActivity-färger
- [x] iOS 26 Tab bar — `tabBarMinimizeBehavior(.onScrollDown)`
- [x] iOS 26 Knappar — `primaryButtonStyle` adaptiv (glass / fylld rektangel)
- [x] GifSheet accessibilityLabel — "Animation showing [övningsnamn]"
- [x] Volymtoggle i ExerciseChartSheet (1RM / VOL)
- [x] ProfileView — streak, senaste pass, personliga rekord, veckosnitt
- [x] Progressionsförslag — badge under set-numret (→ X kg × Y reps), +2.5 kg vid ÖKA
- [x] Träningspåminnelser — REMINDERS-sektion i Settings, veckodagar + autotid från historik
- [x] Hemskärmswidget — small (streak + nästa program) + medium (+ senaste pass)
- [x] WhatsNewSheet — releasenoter öppnas från VERSION-raden i Settings
- [x] WhatsNewSheet lokaliserad — rubrik och releasenotes översatta i sv.lproj/Localizable.strings (LocalizedStringKey)
- [x] CI — GitHub Actions-jobb (.github/workflows/tests.yml) kör xcodebuild test med Exercis-testplanen på push/PR mot main
- [x] Tom `en.lproj`-mapp borttagen (Xcode-restprodukt, var inte incheckad i git)
- [x] Export-bugg åtgärdad — race condition i SettingsView
- [x] GIF-filer rensade ur git-historik med git-filter-repo
- [x] Fix: duplikat övning Military Press → Seated Military Press
- [x] Fix: lokalisering i hjälpfunktioner
- [x] Fix: duplikat-alias-krasch i migrateExerciseNames
- [x] Sheet-bakgrunder — `.background(Color.appBackground)` ersatt med `.regularMaterial` på effort-pickers (StrengthView/CardioView) och onboarding-footern för Liquid Glass-genomskinlighet
- [x] CSV-export RFC 4180-citering — ny fri funktion `csvField(_:)` i Theme.swift kvoterar fält med komma/citattecken/radbrytning (program-, övnings- och kardiotyp-namn)
- [x] HealthKit-behörighetsbegäran konsoliderad — flyttad från StrengthView/CardioView `.onAppear` till `MainTabView.onAppear` vid app-start
- [x] Apprevision 2026-06-06 — lokaliserade saknade strängar (OnboardingView: programval/kardioval/Apple Health-steg, SettingsView: backup-förklaring), lade till `accessibilityLabel("Cancel rest timer")` på vilotimerns avbryt-knapp (StrengthView), uppdaterade CLAUDE.md: 6 nya fria funktioner för imperial-enheter (`displayWeight`/`displayDistance`/`parseWeightInput`/`parseDistanceInput`/`weightLabel`/`distanceLabel`), 8 saknade UserDefaults-nycklar, samt skrev om "Enhetflexibilitet" från framtidsplan till faktisk implementation
- [x] Apprevision 2026-06-06 (full, 7 ytor) — lokaliserade ytterligare 9 strängar (ProfileView: STREAK/LAST SESSION/PERSONAL RECORDS m.fl., SettingsView: "Based on your last session start", accessibility-nycklar "Edit program"/"Animation showing %@"); extraherade `ChartEmptyState` ur fyra identiska kopior i chart sheets till Theme.swift; rättade CLAUDE.md: schema-migrationsstatus var stale (`ExercisSchemaV1`/`ExercisMigrationPlan` finns redan, beskrevs som "ej definierat"), tog bort felaktigt krav på `NSUserNotificationsUsageDescription` (existerar inte som Info.plist-nyckel — notiser kräver ingen usage description), la till saknade widget-filer (WidgetDataStore/WidgetSnapshotBuilder) i filstrukturlistan
