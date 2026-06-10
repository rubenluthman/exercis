# Exercis – Claude Code Context

Privat iOS-app för att logga styrketräning och konditionsträning. En användare.

---

---

## Tech Stack

- **SwiftUI + SwiftData**, iOS 17+, iPhone only, portrait only
- **iCloud-backup** via standard enhetssäkerhetskopiering (CloudKit-sync ej aktiverat – kräver betalt Apple Developer Program-konto)
- **Autentisering**: Face ID via `LAContext .deviceOwnerAuthentication` – automatisk fallback till enhetens lösenkod. Inget eget lösenord. Auto-triggas vid app-launch; retry-knapp om det misslyckas.
- **Deployment target**: iOS 17 (icke förhandlingsbart)
- **Apple Health**: HKWorkout sparas vid varje avslutat styrke- och konditionspass
- `NSFaceIDUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` krävs i Info.plist (notifikationer kräver ingen usage description-nyckel — `UNUserNotificationCenter.requestAuthorization` visar systemets standarddialog utan Info.plist-sträng)

---

## Filstruktur

Alla filer ligger platt i `Exercis/`-mappen.

**Viktigt:** Projektet använder implicit Swift file discovery — `Sources`-fasen i `project.pbxproj` är tom. Alla `.swift`-filer i `Exercis/`-mappen inkluderas automatiskt i bygget. Nya filer behöver **inte** läggas till manuellt i Xcode.

```
ExercisApp.swift          ← @main ExercisApp + RootView + MainTabView (4 tabbar)
AuthManager.swift         ← AuthManager (Face ID/lösenkod)
Models.swift              ← SwiftData-modeller (WorkoutSession, CardioSession, WorkoutProgram, ProgramExercise, CardioType)
Theme.swift               ← färger, typsnitt, knappstillar, ThinDivider, enableSwipeBack, formatWeight/parseWeight, fria funktioner för affärslogik
LockView.swift            ← inloggningsskärm
TrainingView.swift        ← startsida (Träning-tab) — valda program + konditionsformer, bara starta pass
StrengthView.swift        ← logga styrketräningspass (SetFormData, ExerciseFormData, progressionsförslag, PR-detektion)
ExerciseSection.swift     ← övningssektion med sets/reps + WorkoutField-enum + ÖKA-badge + progressionsförslag-badge
GifSheet.swift            ← GIF + övningsinformation (WKWebView, base64-inbäddning, öppnas från ExerciseSection)
CardioView.swift          ← logga konditionspass (accordion, tid mäts automatiskt, bara KM matas in)
HistoryView.swift         ← historiklista (blandar styrka och kondition, HistoryEntry-enum)
HistoryCard.swift         ← expanderbart kort för styrkepass (övningsnamn klickbara → ExerciseChartSheet)
CardioCard.swift          ← expanderbart kort för konditionspass (typ klickbar → CardioChartSheet)
ExerciseChartSheet.swift  ← e1RM-progression per övning (Swift Charts, öppnas från HistoryCard)
CardioChartSheet.swift    ← durationsprogression per kardioform (Swift Charts, öppnas från CardioCard)
EffortChartSheet.swift    ← ansträngningsprogression styrka (Swift Charts, öppnas från HistoryCard)
CardioEffortChartSheet.swift ← ansträngningsprogression kondition (Swift Charts, öppnas från CardioCard)
PeriodSummarySheet.swift  ← periodsammanfattning månads/årsvy (Swift Charts, öppnas från HistoryView)
SessionTimePicker.swift   ← delad sheet för start/slut-tid (startändring drar med slut, slut fritt)
ProfileView.swift         ← profilbild, namn, toppstatistik, streak (14-dagars dots), senaste pass, personliga rekord (top-8 e1RM), veckosnitt
SettingsView.swift        ← inställningar + programhantering + konditionsformer + kroppsbegränsningar + träningspåminnelser + dataexport
ProgramEditorView.swift   ← redigera program (namn, färg, begränsning, övningar, set-antal)
ExercisePickerView.swift  ← övningsväljare med fuzzy search + filterchips (MUSKEL/REDSKAP/RÖRELSE) + dimning
ProgramCard.swift         ← programkort (används i TrainingView och SettingsView)
CardioTypeCard.swift      ← konditionsformkort med accentfärgstopp och senaste duration (används i TrainingView)
OnboardingView.swift      ← onboarding (steg 1: program med pencil-redigering, steg 2: konditionsformer)
Previews.swift            ← Canvas-previews för alla huvudvyer med mock-data (används i Xcode Canvas, byggs ej i release)
HealthKitManager.swift    ← sparar HKWorkout till Apple Health
ExerciseLibrary.swift     ← laddar exercises_def.json, ExerciseDef struct, ExerciseLibrary singleton + BodyLimitation/ProgramConstraint/MuscleGroup enums
ReminderManager.swift         ← UNUserNotificationCenter-wrapper; schedule(weekdays:hour:minute:), cancel(), suggestedTime(from:)
WhatsNewSheet.swift           ← releasenoter per version (öppnas från VERSION-raden i SettingsView)
ExercisActivityAttributes.swift ← ActivityKit-attribut för Live Activity (programnamn, accentfärg, övning/set-state)
LiveActivityManager.swift ← hanterar start/update/end av Live Activity under styrketräning
WidgetDataStore.swift     ← skriver WidgetSnapshot till App Group UserDefaults (group.rubenluthman.Exercis)
WidgetSnapshotBuilder.swift ← bygger WidgetSnapshot från SwiftData (streak, senaste pass, nästa program)
```

**Widget-mapp** (`ExercisWidget/`, separat target):
```
ExercisWidgetBundle.swift   ← WidgetBundle-entry för widget-target
ExercisLiveActivity.swift   ← Live Activity-layout (Dynamic Island + Lock Screen)
ExercisHomeWidget.swift     ← Hemskärmswidget (small + medium): streak, senaste pass, nästa program
WidgetShared.swift          ← WidgetSnapshot + WidgetDataStore + ProgramColor (kopia för widget-target)
ExercisWidget.entitlements  ← App Group: group.rubenluthman.Exercis
```

**App Group** (`group.rubenluthman.Exercis`):
- Måste aktiveras i Xcode för BÅDA targets: Exercis och ExercisWidget (Signing & Capabilities → + → App Groups)
- `WidgetDataStore` skriver/läser via `UserDefaults(suiteName: "group.rubenluthman.Exercis")`
- App-target har `WidgetDataStore.swift` + `WidgetSnapshot` + `WidgetSnapshotBuilder.swift`
- Widget-target har `WidgetShared.swift` (kopia av WidgetSnapshot + WidgetDataStore + ProgramColor)
- `WidgetShared.swift` ska INTE läggas till app-target (ger redefinition-fel)

---

## Theme.swift

Enda plats för färger, typsnitt, knappstillar och gemensamma UI-komponenter.

### Färger

Alla färger definieras i `Assets.xcassets` som named color sets med automatisk light/dark-variant. `Theme.swift` exponerar dem som `Color`-extensions.

**Strukturella accentfärger** — aliases till palettrader:
```swift
Color.homeAccent    // → paletteIntenseRed  light #B73B3F / dark #F97775
Color.workoutAccent // → paletteGreen       light #23821F / dark #63BD5C
Color.historyAccent // → paletteLightBlue   light #0078B8 / dark #00B3F7
Color.appBackground // Color(.systemBackground)
Color.appDivider    // Color(.separator)
```

**Programfärgpalett** — OKLCH L=0.5325 C=0.160, 12 kulörer stegade 30°:
```swift
Color.paletteIntenseRed  // H=22.4°   light #B73B3F / dark #F97775
Color.paletteOrange      // H=52.4°   light #B04900 / dark #F18435
Color.paletteYellow      // H=82.4°   light #995F00 / dark #D59800
Color.paletteLime        // H=112.4°  light #707400 / dark #A7AE00
Color.paletteGreen       // H=142.4°  light #23821F / dark #63BD5C
Color.paletteTeal        // H=172.4°  light #008862 / dark #00C49A
Color.paletteCyan        // H=202.4°  light #008494 / dark #00C0D0
Color.paletteLightBlue   // H=232.4°  light #0078B8 / dark #00B3F7
Color.paletteDarkBlue    // H=262.4°  light #3767C8 / dark #6DA2FF
Color.palettePurple      // H=292.4°  light #7155BF / dark #A98FFF
Color.paletteMagenta     // H=322.4°  light #9646A2 / dark #D37FDF
Color.palettePink        // H=352.4°  light #AE3B75 / dark #EE76AE
```
`Color.programPalette: [Color]` — array med alla 12, används i programväljaren.

**WCAG-kontrast mot vit bakgrund (ljusläge):** alla ≥4.5:1 (AA) utom teal/cyan (4.4–4.5:1, AA-large — OK för knappar/rubriker, ej liten brödtext).

**⚠️ Yellow och lime på vit bakgrund:** `paletteYellow` (H=82.4°) och `paletteLime` (H=112.4°) är perceptuellt balanserade mot övriga färger i OKLCH, men gul-gröna toner upplevs ofta som "smutsiga" eller nedtonade på vit bakgrund — en egenskap hos det mänskliga synssystemet, inte ett kontrastfel (båda klarar AA). Bör testas visuellt mot vit bakgrund innan de används som programfärger. Om de inte håller estetiskt: höj L något (t.ex. till 0.57) för just dessa två, eller välj bort dem från programpaletten.

### Typsnitt: Jost (enda typsnitt)
```swift
Font.jost(_ weight: Font.Weight, size: CGFloat)
```

| Vikt        | Används till                                      |
|-------------|---------------------------------------------------|
| Black 900   | "EXERCIS" på LockView                             |
| Bold 700    | Sidrubriker (17pt, kerning 2)                     |
| SemiBold 600| Knappar, accentetiketter, stora siffror (34pt)    |
| Medium 500  | Section labels, sub-labels, kolumnrubriker (11–12pt, kerning 1.5) |
| Regular 400 | Brödtext, hints, datum (13–14pt)                  |

### Textstorlekshierarki

| Storlek | Kategori | Exempel |
|---------|----------|---------|
| 17pt    | Sidrubriker | "SETTINGS", "HISTORY" |
| 14–15pt | Primär radtext | Programnamn, kardionamn, toggletitlar |
| 13–14pt | Brödtext / beskrivningar | Toggle-beskrivningar, iCloud-info |
| 12pt    | Section labels, åtgärdsrader | "STRENGTH PROGRAMS", "EXPORT TRAINING DATA", "START/END" i SessionTimePicker |
| 11pt    | Stat-undertexter (under stora siffror) | "STREAK", "BEST", "SESSIONS", "EFFORT" |
| 9pt     | Badge-piller | "INCREASE", progressionsförslag (pill-format, behåller 9pt) |
| 10pt    | Chart-axeletiketter | Månadsförkortningar och Y-axelvärden i diagram |

**Regel:** inget UI-text under 11pt utom badge-piller (9pt) och chart-axlar (10pt).

### Knappstillar
- `FilledButtonStyle(accent:)` — fylld, vit text, höjd 50pt, `clipShape(RoundedRectangle(cornerRadius: 4))`
- `OutlineButtonStyle(accent:)` — kontur i accentfärg, höjd 50pt

### Dynamic Type
`Font.jost()` använder `Font.custom(_:size:relativeTo:)` med en storleksbaserad `TextStyle` som referens — Jost skalar automatiskt med användarens textstorleksinställning i iOS.

### ChartEmptyState

Delad vy i Theme.swift — visar "No logged sessions yet." / "Need at least two sessions to show chart." beroende på `isEmpty`. Används av samtliga fyra chart sheets (ExerciseChartSheet, CardioChartSheet, EffortChartSheet, CardioEffortChartSheet) för konsekvent tomt-tillstånd när `< 2` datapunkter finns — extraherad ur fyra identiska kopior vid apprevision.

### Scroll edge fade
`View.softScrollEdge()` i Theme.swift — applicerar en 20pt gradient-mask längs toppen av ScrollView (clear→black). Fungerar på iOS 17+. Appliceras på alla `ScrollView` i appen (StrengthView, HistoryView). Masken påverkar endast rendering, inte hit-testing.

### Haptic feedback
| Händelse | Typ |
|----------|-----|
| Pass sparat (KLAR/HOPPA ÖVER/drag-dismiss) | `.success` notification |
| Pass raderat | `.warning` notification |
| Long press ÖKA-badge | `.impact(.medium)` |
| NÄSTA fältnavigering (styrka + kondition) | `.selection` |
| Expand/collapse sektion eller månad | `.selection` |

### Navigationsbrygga
`enableSwipeBack()` — View-extension som via UIKit-bridge återaktiverar `interactivePopGestureRecognizer` (behövs eftersom `.toolbar(.hidden, for: .navigationBar)` inaktiverar swipe-back i iOS 17).

### Fria funktioner för affärslogik (testbara)

Alla fria funktioner i Theme.swift är enhetstestade och ska hållas fria från SwiftUI/SwiftData-beroenden.

| Funktion | Syfte |
|----------|-------|
| `epleyE1RM(weight:reps:)` | Epley-formel för beräknat 1RM |
| `estimatedCalories(met:bodyMass:seconds:)` | Kaloriberäkning via MET |
| `computeCurrentStreak(days:)` | Aktuell träningsstreak från `Set<Date>` |
| `computeBestStreak(days:)` | Bästa streak någonsin från `Set<Date>` |
| `progressionSuggestion(prevMax:shouldIncrease:bestSetReps:)` | Föreslår nästa vikt (+2.5 kg om ÖKA) och reps |
| `csvField(_:)` | RFC 4180-citerar ett CSV-fält (komma/citattecken/radbrytning) |
| `strengthCSV(_:)` | Genererar CSV-sträng för styrkepass |
| `cardioCSV(_:)` | Genererar CSV-sträng för konditionspass |
| `formatWeight(_:)` | Formaterar Double → sträng utan onödiga decimaler |
| `parseWeight(_:)` | Parsar sträng → Double, accepterar punkt och komma |
| `displayWeight(_:imperial:)` | Konverterar lagrad kg → visningssträng (lbs vid imperial) |
| `displayDistance(_:imperial:)` | Konverterar lagrad km → visningssträng (mi vid imperial) |
| `parseWeightInput(_:imperial:)` | Parsar visad vikt → kg för lagring |
| `parseDistanceInput(_:imperial:)` | Parsar visad distans → km för lagring |
| `weightLabel(_:)` | "KG" eller "LBS" beroende på enhetsval |
| `distanceLabel(_:)` | "KM" eller "MI" beroende på enhetsval |

---

## Design-regler

- Systemanpassad bakgrund (`Color(.systemBackground)`), primär text (`.primary`) — anpassar sig till mörkt läge automatiskt
- Accentfärgen är det **enda** färginslaget – används på rubriker, övningsnamn, knappar och detaljer
- Inga emojis, inga ikoner utöver SF Symbols (chevron, xmark)
- Versaliserade etiketter med spärr (letter spacing)
- Tunna **0.5 pt avdelare** via `ThinDivider`
- UI-text lokaliseras via iOS standard-lokaliseringssystem. **Engelska är basspråket** (alla strängar definieras på engelska). Svenska tillhandahålls via `.strings`-filer. SwiftUI `Text()` med strängliteraler lokaliserar automatiskt; övriga strängar använder `String(localized:)`.
- Datum formateras alltid med `Locale(identifier: "sv_SE")`
- KLAR-knapp: fylld i accentfärg, längst ner i vyn (i safeAreaInset). Döljs när effort-picker öppnas.
- Tillbaka-knapp: bara "←" utan text, font regular 22pt, `.frame(width: 90, alignment: .trailing)`
- Horizontal padding: **24pt** genomgående på alla rader

---

## Datamodeller (SwiftData)

**Cascade delete på alla relationer.**

```swift
@Model class WorkoutSession {
    var id: UUID; var date: Date; var startDate: Date; var healthKitID: UUID?; var effortScore: Int?
    var programId: UUID?      // kopplar session till WorkoutProgram för prefill
    var programName: String?  // denormaliserat — används i CSV-export
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]
}
@Model class ExerciseLog {
    var name: String; var orderIndex: Int; var session: WorkoutSession?
    // exerciseDefId: String? finns i modellen men används ej än
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
    var isOnTrainingPage: Bool = true   // visas på Träning-tab
    var programConstraint: String = ""  // ProgramConstraint.rawValue — skuggar övningar i ExercisePickerView
    @Relationship(deleteRule: .cascade) var exercises: [ProgramExercise]
}
@Model class ProgramExercise {
    var exerciseId: String; var exerciseName: String; var sortIndex: Int; var setCount: Int
    var program: WorkoutProgram?
}
```

**`CardioType` enum** (i Models.swift, `Identifiable`):

26 cases i lowercase rawValue — grupperade i kommentarer:
- **Maskiner**: `crosstrainer`, `cycling_stationary`, `rowing_machine`, `treadmill_run`, `treadmill_walk`, `stair_climber`, `ski_erg`, `assault_bike`
- **Utomhus**: `running`, `walking`, `hiking`, `road_cycling`, `mountain_biking`, `swimming`
- **Nordiska**: `cross_country_skiing`, `ice_skating`
- **Vatten**: `kayaking`, `canoeing`
- **Övrigt**: `climbing`, `boxing`, `battle_ropes`, `sled`, `rucking`
- **Calisthenics cardio**: `jump_rope`, `burpees`, `mountain_climbers`

Lagras som `String` i `CardioSession` för att undvika migrationsproblem. Gamla VERSALER-rawvärden migreras vid app-start via `migrateCardioTypes(context:)` i Models.swift.

`var tracksElevation: Bool` — `true` för: `hiking`, `running`, `walking`, `road_cycling`, `mountain_biking`, `cross_country_skiing`, `rucking`, `climbing`. Styr om `CMAltimeter` startas i CardioView och om `elevationGain` skickas till HealthKit.

`var met: Double` — MET-värde (Metabolic Equivalent of Task) per typ, används av `estimatedCalories` för kaloriberäkning till HealthKit.

`var hkActivityType: HKWorkoutActivityType` — mappning till HealthKit-aktivitetstyp.

**`WorkoutDraft`** (Codable, sparas i UserDefaults):
```swift
struct WorkoutDraft: Codable {
    var exercises: [ExerciseDraft]  // ExerciseDraft: name, sets, shouldIncrease, previousMaxWeight
    var startTime: Date
    var collapsedExercises: [Int]   // default [] vid avkodning av gamla drafts
    var programId: String?          // default nil vid avkodning av gamla drafts
}
```
- Har custom `init(from:)` för bakåtkompatibilitet — nya fält med default-värden avkodas tyst från äldre JSON
- `suggestedWeight`/`suggestedReps` sparas **inte** i draft — beräknas om vid prefill från historik

**`ExerciseFormData`** (in-memory, ej Codable):
```swift
struct ExerciseFormData {
    let def: ExerciseDef
    var sets: [SetFormData]
    var shouldIncrease: Bool
    var previousMaxWeight: Double
    var suggestedWeight: String  // "+2.5 kg om ÖKA, annars samma" — visas som badge i ExerciseSection
    var suggestedReps: String
}
```

**Vikt-inmatning**: acceptera både punkt och komma som decimaltecken (`parseWeight`).
**Vikt-visning**: formatera med `formatWeight` (NumberFormatter, locale: .current).

**ModelContainer** registrerar `[WorkoutSession.self, CardioSession.self, WorkoutProgram.self]` — relaterade modeller (ExerciseLog, SetLog, ProgramExercise) inkluderas automatiskt via `@Relationship`.

---

## Övningar

Laddas från `Resources/exercises_def.json` via `ExerciseLibrary` (singleton). ~186 övningar med `status == "include"` är aktiva — resten är exkluderade i JSON.

**Övningsnamn är på engelska** — medvetet val. De lokaliseras inte via `.strings` och visas på engelska oavsett enhetsspråk. Lagras på engelska i historik (`ExerciseLog.name`) och CSV-export.

`ExerciseDef` fält: `id` (stabil nyckel, används i `ProgramExercise.exerciseId`), `name` (visas i UI och lagras i `ExerciseLog.name`), `aliases` (gamla namn, migreras vid app-start), `repRange`, `setRange`, `primaryMuscles`, `equipment`, `movement`, `contraindications`, `gifFile/gifSource`, `description`.

**Nyckel är `id`** i program (`ProgramExercise.exerciseId`) men **`name`** i loggad historik (`ExerciseLog.name`) — viktigt att hålla isär. Byt aldrig `id` eller `name` utan att lägga gamla värdet i `aliases` och bumpa `migrationVersion` (nuvarande: 6).

**Pensionering av övning** — när en övning byts ut och gammal data ska bevaras i historik:
- Sätt `status` till `"retired"` i JSON (eller håll i separat lista) — ingen migration, ingen radering
- `ExerciseDef.find(name:)` söker aktiva + pensionerade, så historik visas korrekt

**Aktiv radering** kräver explicit delete-steg i `migrateExerciseNames`.

Övningsnamnet i StrengthView är en **klickbar rubrik** som öppnar GIF/info via `GifSheet`. I HistoryView är namnen klickbara och öppnar `ExerciseChartSheet` (e1RM-progression via Epley-formeln).

---

## Skärmar & Navigation

```
LockView → (Face ID) → MainTabView
                         ├── TrainingView (Träning) → StrengthView (navigationDestination)
                         │                          → CardioView (navigationDestination)
                         ├── HistoryView (Historik)
                         ├── ProfileView (Profil)
                         └── SettingsView (Inställningar) → ProgramEditorView (sheet)
```

- 4 tabbar: **Träning · Historik · Profil · Inställningar**
- `navigationDestination(item:)` för StrengthView och CardioView — swipe-back via `enableSwipeBack()`
- **KLAR** sparar och returnerar via dismiss; **←** (swipe-back) sparar draft via `onDisappear`

### LockView (ingen accentfärg)
- "EXERCIS" Jost Black 900, centrerat vertikalt
- `faceid` SF Symbol (~40pt) som retry-knapp, `.secondary` färg — visas bara om Face ID misslyckades
- `auth.authenticate()` triggas i `.onAppear` och via retry-ikonen

### TrainingView (Träning-tab, accentfärg per program/workoutAccent)
- Visar valda styrkeprogram (filter: `isOnTrainingPage == true`) under STYRKA
- Visar valda konditionsformer (från `selectedCardioTypes` AppStorage) under KONDITION
- Tryck på program → navigerar till StrengthView; tryck på konditionsform → navigerar till CardioView med `initialType`
- Draft-indikator: pencil-ikon på program med aktiv draft; "FORTSÄTT"-text på konditionsform med aktiv draft
- Tomt tillstånd om inget är konfigurerat

### StrengthView — Styrketräning (accentfärg: homeAccent/programfärg)
- Header: "STYRKETRÄNING" 17pt bold, kerning 2 + förkortat datum 13pt
- Formuläret **förifyller automatiskt** per program från senaste session med samma `programId`
- Set-antal per övning definieras i programmet (1–6, default 3)
- Kolumnrubriker: **SET, KG, REPS** — layout: SET=maxWidth leading, KG=80pt leading, REPS=120pt trailing
- **Ihopfällbara sektioner**, **ÖKA-badge** (long press 500ms), **vila-timer** (triggas efter sista reps-fält — konfigureras globalt i SettingsView: 0/30/60/90/120s, `@AppStorage("restTimerSeconds")`, default 90s)
- **PR-detektion**: jämför e1RM mot historik, visar PR-indikator vid KLAR
- **Progressionsförslag**: badge under set-numret (`→ X kg × Y reps`) i accentfärg; försvinner när man börjar skriva. Förslag = föregående sessions bästa set; +2.5 kg om ÖKA är aktivt
- **Tangentbordsverktygsfält**: NÄSTA + KLAR i homeAccent
- **Draft**: sparas i UserDefaults (WorkoutDraft inkl. ihopfällningsläge och programId)
- **Live Activity**: startas vid pass-start via `LiveActivityManager.shared` — visar aktuell övning, set-nummer och progress på Dynamic Island/Lock Screen. Uppdateras per set, avslutas vid KLAR eller dismiss.
- Datum klickbart → `SessionTimePicker`

### CardioView — Konditionsträning (accentfärg: workoutAccent)
- Öppnas med `initialType: CardioType?` — öppnar rätt accordion direkt
- **Accordion med valda konditionstyper** — separerade av ThinDivider
- **Tid mäts automatiskt**: start = när CardioView öppnas, slut = KLAR. Inget manuellt tidsinmatning.
- Enda manuell input: **KM** (distans) för typer med distans
- **Tangentbordsverktygsfält**: bara KLAR (ett fält = ingen NÄSTA)
- **Draft**: sparar aktiv typ + eventuell distans till UserDefaults
- Datum klickbart → `SessionTimePicker` (startändring drar med slutet, slut fritt — stödjer pass över midnatt)
- KLAR → effort-picker → sparar `CardioSession`, loggar till HealthKit

### HistoryView (accentfärg: historyAccent)
- Header: "HISTORIK" 17pt bold + "←" 90pt trailing
- `HistoryEntry`-enum (`.workout` / `.cardio`) blandar och sorterar nyast först
- **Månadsgrupper** (`MonthGroup`): poster grupperas per år/månad, rubrik i historyAccent med antal styrka/kondition. Ihopfällbara — senaste månaden öppen, övriga stängda vid första öppning. Årsrubrik (`HistoryRow.year`) visas bara om data spänner flera år — klickbar, öppnar årssammanfattning.
- Varje rad utfällbar (HistoryCard / CardioCard) — senaste posten öppnas automatiskt
- Radera via ×-knapp eller kontextmeny — visar `.alert("Ta bort pass?")` med destructive-knapp
- Delete hanterar även HealthKit-borttagning via `HealthKitManager.deleteWorkout(uuid:)`
- Styrkeövningar visas i historyAccent; konditionstyp visas i **historyAccent** (inte workoutAccent — allt i historikläget är blått)
- **Klickbara namn**: övningsnamn i HistoryCard öppnar `ExerciseChartSheet`; kardiotyp i CardioCard öppnar `CardioChartSheet`

### ExerciseChartSheet / CardioChartSheet / EffortChartSheet (accentfärg: historyAccent)
- Öppnas som `.sheet` med `.presentationDetents([.medium, .large])` från HistoryCard/CardioCard
- Hämtar all data via `@Query` (ärver modelContainer från miljön)
- Linjediagram (Swift Charts) med punktmarkeringar i accentfärg
- X-axeln visar månadsförkortning; om data spänner över flera år visas även tvåsiffrigt år (t.ex. "JAN\n25")
- Svenska månadsförkortningar — punkter i förkortningarna strimmas bort
- Statistikrad per sheet:
  - ExerciseChartSheet: BÄSTA · SENASTE · PASS (enhet: kg); toggle **1RM / VOL** i headern — VOL = sets × reps × kg per session
  - CardioChartSheet: LÄNGST · SENASTE · PASS (enhet: min/km); toggle TID/DISTANS om distansdata finns
  - EffortChartSheet: LÄTTAST · SENASTE · TUFFAST (enhet: /10, visas i grå 14pt); öppnas från ansträngningsraden i HistoryCard (styrkepass)
  - CardioEffortChartSheet: LÄTTAST · SENASTE · TUFFAST per kardioform; öppnas från ansträngningsraden i CardioCard
  - PeriodSummarySheet: STYRKA · VOLYM · KONDITION · TID + **månadsvy**: prickrad (en cirkel per dag, röd=styrka, grön=kondition, gradient=båda, grå=inget); **årsvy**: stapeldiagram per månad. Öppnas från månadsnamn (detent `.height(280)`) respektive årsrubrik (detent `.medium`) i HistoryView. Volym visas i kg (<1000) eller ton (≥1000). Nollvärden visas som `—`.
- Tomt tillstånd om < 2 datapunkter

### ProfileView (ingen accentfärg)
- Profilbild (PhotosPicker) + redigerbart namn
- **Toppstatistik**: STRENGTH · CARDIO · VOLUME · CARDIO TIME i fyra kolumner
- **Streak**: aktuell streak som 72pt black-siffra + BEST, 14-dagars prickrad (blå=aktiv, grå=vilat, today har kontur)
- **Senaste pass**: titel (programnamn eller kardioform), undertitel (övningar/minuter), relativ tid + kalenderdag
- **Personliga rekord**: top-8 e1RM per övning, rankade 1–8, e1RM i historyAccent
- **Veckosnitt**: AVG/WEEK · THIS WEEK · BEST WEEK

### SettingsView (ingen accentfärg)
- Sektioner: STRENGTH PROGRAMS · CARDIO TYPES · LIMITATIONS · TRAINING · HEALTH · PRIVACY · REMINDERS · DATA · ABOUT
- **REMINDERS**: toggle, veckodagsknappar (Mån–Sön), tidväljare (auto-satt från senaste passstart, fallback 17:00)
- **DATA**: backup-förklaring (iCloud Backup, vad som går förlorat), CSV-export via `UIActivityViewController`
- **ABOUT → VERSION**: öppnar `WhatsNewSheet` med releasenoter
- `#if DEBUG`-sektion: RESET ONBOARDING

---

## Apple Health

`HealthKitManager` (singleton `struct`) sparar `HKWorkoutBuilder` till Apple Health:

| Pass | ActivityType | Tid |
|------|-------------|-----|
| Styrketräning | `.traditionalStrengthTraining` | start = när StrengthView öppnas, slut = KLAR |
| crosstrainer | `.elliptical` | slut = nu, start = nu − minuter |
| cycling_stationary, road_cycling, mountain_biking, assault_bike | `.cycling` | slut = nu, start = nu − minuter |
| rowing_machine, ski_erg, kayaking, canoeing | `.rowing` | slut = nu, start = nu − minuter |
| hiking, rucking, crosstrainer, stair_climber | `.hiking` | slut = nu, start = nu − minuter |
| running, treadmill_run | `.running` | slut = nu, start = nu − minuter |
| walking, treadmill_walk | `.walking` | slut = nu, start = nu − minuter |
| sled | `.functionalStrengthTraining` | slut = nu, start = nu − minuter |

- Begär tillstånd vid varje StrengthView/CardioView-öppning (`requestAuthorization()`) — iOS hanterar "redan beviljat" automatiskt
- Alla anrop guards med `HKHealthStore.isHealthDataAvailable()` — no-op på simulator
- `healthKitID: UUID?` sparas på session-objektet för att möjliggöra radering
- Kalorier beräknas via `estimatedCalories(met:bodyMass:seconds:)` — MET hämtas från `CardioType.met`, kroppsvikt läses från HealthKit (fallback 75 kg)
- **iOS 18+**: ansträngningspoäng sparas som `HKQuantityType(.workoutEffortScore)` via `store.relateWorkoutEffortSample(_:with:activity:)` — gäller både styrke- och konditionspass

---

## UserDefaults-nycklar

| Nyckel | Typ | Ägare | Syfte |
|--------|-----|-------|-------|
| `hasDraft` | Bool (@AppStorage) | TrainingView/StrengthView | Om styrke-draft finns |
| `hasCardioDraft` | Bool (@AppStorage) | TrainingView/CardioView | Om konditions-draft finns |
| `workoutDraft` | Data | UserDefaults | WorkoutDraft (JSON) inkl. ihopfällningsläge |
| `cardioDraftType` | String | UserDefaults | Typ för aktiv konditions-draft |
| `cardioDraftStartTime_{TYPE}` | Double | UserDefaults | Starttid (timeIntervalSince1970) för pausat konditionspass |
| `cardioDraftDistance_{TYPE}` | String | UserDefaults | Distans (km) för pausat konditionspass |
| `cardioSavedDuration_{TYPE}` | String | UserDefaults | Senast sparad duration per kardioform (beräknad från tid) |
| `cardioSavedDistance_{TYPE}` | String | UserDefaults | Senast sparad distans per kardioform |
| `cardioEffortScore_{TYPE}` | Int | UserDefaults | Senast sparad ansträngning per kardioform (startvärde i picker) |
| `workoutEffortScore` | Int | UserDefaults | Senast sparad ansträngning för styrkepass (startvärde i picker) |
| `increaseExercises` | [String] | UserDefaults | Övningsnamn med aktiv ÖKA-badge (styrka) |
| `increaseCardioTypes` | [String] | UserDefaults | Kardioformer med aktiv ÖKA-badge |
| `exerciseNameMigrationVersion` | Int | UserDefaults | Version för körd namnmigration (bumpa vid övningsändringar) |
| `bodyLimitations` | String (@AppStorage) | SettingsView/ExercisePickerView | Kommaseparerade BodyLimitation.rawValue — skuggar övningar som belastar valda leder |
| `reminderEnabled` | Bool (@AppStorage) | SettingsView | Om träningspåminnelser är aktiva |
| `reminderWeekdays` | String (@AppStorage) | SettingsView | Kommaseparerade veckodagar (1=sön, 2=mån…7=lör) |
| `reminderHour` | Int (@AppStorage) | SettingsView | Timme för påminnelse (24h), sätts automatiskt från senaste passstart |
| `reminderMinute` | Int (@AppStorage) | SettingsView | Minut för påminnelse |
| `onboardingCompleted` | Bool (@AppStorage) | ExercisApp/OnboardingView/SettingsView | Om onboarding är genomförd (DEBUG: kan nollställas i SettingsView) |
| `lockEnabled` | Bool (@AppStorage) | ExercisApp/SettingsView | Om Face ID-lås är aktiverat |
| `profileName` | String (@AppStorage) | ProfileView | Användarens visningsnamn |
| `restTimerSeconds` | Int (@AppStorage) | StrengthView/SettingsView | Global vilotimer-längd (0/30/60/90/120s, default 90) |
| `selectedCardioTypes` | String (@AppStorage) | OnboardingView/TrainingView/SettingsView | Kommaseparerade `CardioType.rawValue` som visas på Träning-tab |
| `useImperialUnits` | Bool (@AppStorage) | SettingsView + alla vy/kort som visar vikt/distans | Enhetsval KG/KM (false) eller LBS/MI (true) — konvertering vid presentation via `displayWeight`/`displayDistance` |
| `healthKitSyncEnabled` | Bool (@AppStorage) | SettingsView | Om pass sparas till Apple Health |
| `healthKitWeightEnabled` | Bool (@AppStorage) | SettingsView | Om kroppsvikt hämtas från Apple Health för kaloriberäkning |

---

## Begränsningssystem (ExercisePickerView)

Övningsväljaren har två oberoende signaler som skuggar övningar (opacity 0.4) och samlar dem under "EJ REKOMMENDERAT" längst ner i listan:

**Kroppsbegränsningar** (globala, `@AppStorage("bodyLimitations")`):
- Sätts i SettingsView → BEGRÄNSNINGAR med toggles per led
- `BodyLimitation` enum i ExerciseLibrary.swift: KNÄ / AXEL / RYGG / ARMBÅGE / HANDLED / HÖFT
- Varje led mappar till specifika `contraindications`-taggar i exercises_def.json

**Programbegränsningar** (per program, `WorkoutProgram.programConstraint`):
- Sätts i ProgramEditorView → Begränsning med chip-väljare
- `ProgramConstraint` enum: INGEN / PUSH / PULL / BEN / ÖVERKROPP / KROPPSVIKT
- Standardprogram får rätt constraint från seeder (t.ex. Push → "push", Bodyweight → "bodyweight")
- Skickas in till ExercisePickerView som parameter

**Filterchips** (sessionella, nollställs vid stängning):
- MUSKEL → `MuscleGroup` enum (6 grupper → primaryMuscles-mappning)
- REDSKAP → equipment-råvärden
- RÖRELSE → movement-råvärden
- Öppnar FilterSheet (`.sheet`, `.medium`/`.large` detents) med checkboxar

Alla tre system är additive — en övning skuggas om någon av signalerna matchar.

---

## AuthManager.swift

- `ObservableObject` + `@Published var isAuthenticated: Bool`
- Wrappa `LAContext` med `.deviceOwnerAuthentication` (Face ID → lösenkod automatiskt)
- Svarar på `DispatchQueue.main.async` i completion (LAContext kallar bakgrundstråd)
- Används som `@StateObject` i RootView

---

## Viktiga SwiftData-noter

- `ModelContainer` konfigureras i `ExercisApp.swift` (CloudKit ej aktiverat)
- Alla relationer har `deleteRule: .cascade`
- Sortering i HistoryView: nyast först
- Schema-versionering finns: `ExercisSchemaV1` (`VersionedSchema`, version 1.0.0) + `ExercisMigrationPlan` (`SchemaMigrationPlan`, tom `stages`-lista) i Models.swift — `ModelContainer` skapas via `Schema(ExercisSchemaV1.models)` och `migrationPlan: ExercisMigrationPlan.self` i ExercisApp.swift. Vid framtida fältnamnbyten/borttag: lägg till `ExercisSchemaV2` + en `MigrationStage` i planen, bumpa `versionIdentifier`
- `try? context.save()` används genomgående — fel loggas ej (acceptabelt för single-user app)

---

## Enhetflexibilitet

Vikt och distans lagras alltid i metriska bastal — `Double` för kg (`weight`) och km (`distanceKm`). SwiftData-fälten ändras aldrig vid enhetsbyte (ingen migration krävs).

Imperial-stöd är **implementerat** via `useImperialUnits` (@AppStorage, växlas i SettingsView → UNITS: "KG / KM" / "LBS / MI"):
- Konvertering sker vid presentation, inte i lagringen — `displayWeight(_:imperial:)` / `displayDistance(_:imperial:)` (kg→lbs ×2.20462, km→mi ×0.621371)
- Inmatning konverteras tillbaka till metriskt vid parsning — `parseWeightInput(_:imperial:)` / `parseDistanceInput(_:imperial:)`
- Etiketter via `weightLabel(_:)` / `distanceLabel(_:)`
- Alla fria funktioner finns i Theme.swift, är enhetstestade och fria från SwiftUI/SwiftData-beroenden

Tid lagras fortfarande som råa minuter (`Double`, `durationMinutes`) utan enhetsväxling — bara KG/KM ↔ LBS/MI stöds idag.

---

## Planerade funktioner och expansion

Se [ROADMAP.md](ROADMAP.md) för alla planerade funktioner, beslutade designval och parkerade förslag.

---

## Krav som inte får brytas

1. Deployment target **iOS 17**
2. **iPhone only** (iPad stöds inte)
3. **Portrait only**
4. `NSFaceIDUsageDescription` i Info.plist
5. `NSHealthShareUsageDescription` och `NSHealthUpdateUsageDescription` i Info.plist
6. CloudKit ej aktiverat (kräver betalt Apple Developer-konto)
7. Jost är **enda** typsnitt – inga system fonts
8. Accentfärg är **enda** färginslaget utöver systemfärger (`.primary`, `.secondary`, `Color(.systemBackground)`)
9. Vikt lagras alltid som `Double`
10. UI-text lokaliseras — engelska som basspråk, svenska via `.strings`
