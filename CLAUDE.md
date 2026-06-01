# Exercis – Claude Code Context

Privat iOS-app för att logga styrketräning och konditionsträning. En användare.

---

## Tech Stack

- **SwiftUI + SwiftData**, iOS 17+, iPhone only, portrait only
- **iCloud-backup** via standard enhetssäkerhetskopiering (CloudKit-sync ej aktiverat – kräver betalt Apple Developer Program-konto)
- **Autentisering**: Face ID via `LAContext .deviceOwnerAuthentication` – automatisk fallback till enhetens lösenkod. Inget eget lösenord. Auto-triggas vid app-launch; retry-knapp om det misslyckas.
- **Deployment target**: iOS 17 (icke förhandlingsbart)
- **Apple Health**: HKWorkout sparas vid varje avslutat styrke- och konditionspass
- `NSFaceIDUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` krävs i Info.plist

---

## Filstruktur

Alla filer ligger platt i `Exercis/`-mappen.

```
ExercisApp.swift      ← @main ExercisApp + RootView + AppScreen
AuthManager.swift     ← AuthManager (Face ID/lösenkod)
Models.swift          ← SwiftData-modeller (WorkoutSession, CardioSession, ExerciseDef, WorkoutDraft, CardioType)
Theme.swift           ← färger, typsnitt, knappstillar, ThinDivider, enableSwipeBack, formatWeight/parseWeight
HomeView.swift        ← startsida med tre knappar
LockView.swift        ← inloggningsskärm
StrengthView.swift    ← logga styrketräningspass (SetFormData, ExerciseFormData, nextField-logik)
ExerciseSection.swift ← övningssektion med sets/reps + WorkoutField-enum + UserDefaults-extension
VideoSheet.swift      ← video/webb i SFSafariViewController vid klick på övningsnamn
CardioView.swift      ← logga konditionspass (accordion med CROSSTRAINER/CYKEL/RODDMASKIN)
HistoryView.swift     ← historiklista (blandar styrka och kondition, HistoryEntry-enum)
HistoryCard.swift     ← expanderbart kort för styrkepass (övningsnamn klickbara → ExerciseChartSheet)
CardioCard.swift      ← expanderbart kort för konditionspass (typ klickbar → CardioChartSheet)
ExerciseChartSheet.swift      ← e1RM-progression per övning (Swift Charts, öppnas från HistoryCard)
CardioChartSheet.swift        ← durationsprogression per kardioform (Swift Charts, öppnas från CardioCard)
EffortChartSheet.swift        ← ansträngningsprogression över styrkepass (Swift Charts, öppnas från HistoryCard)
CardioEffortChartSheet.swift  ← ansträngningsprogression per kardioform (Swift Charts, öppnas från CardioCard)
PeriodSummarySheet.swift      ← periodsammanfattning månads/årsvy (Swift Charts, öppnas från HistoryView)
SessionTimePicker.swift   ← delad sheet för att redigera start/slut-tid (öppnas via datum-text i header)
HealthKitManager.swift    ← sparar HKWorkout till Apple Health
```

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
| Black 900   | "EXERCIS" på LockView och HomeView                |
| Bold 700    | Sidrubriker (17pt, kerning 2)                     |
| SemiBold 600| Knappar, accentetiketter, stora siffror (34pt)    |
| Medium 500  | Kolumnrubriker, sekundär text (10pt, kerning 1.5) |
| Regular 400 | Brödtext, hints, datum (13–14pt)                  |

### Knappstillar
- `FilledButtonStyle(accent:)` — fylld, vit text, höjd 50pt, `clipShape(RoundedRectangle(cornerRadius: 4))`
- `OutlineButtonStyle(accent:)` — kontur i accentfärg, höjd 50pt

### Dynamic Type
`Font.jost()` använder `Font.custom(_:size:relativeTo:)` med en storleksbaserad `TextStyle` som referens — Jost skalar automatiskt med användarens textstorleksinställning i iOS.

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
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]
}
@Model class ExerciseLog {
    var name: String; var orderIndex: Int; var session: WorkoutSession?
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

**`CardioType` enum** (i Models.swift):
```swift
enum CardioType: String, Codable, CaseIterable {
    case crosstrainer = "CROSSTRAINER"
    case cykel        = "CYKEL"
    case roddmaskin   = "RODDMASKIN"
    case hiking       = "VANDRING"
}
```
Lagras som `String` i `CardioSession` för att undvika migrationsproblem.

**`WorkoutDraft`** (Codable, sparas i UserDefaults):
- Innehåller övningsdata, `startTime` och `collapsedExercises: [Int]`
- Har custom `init(from:)` för bakåtkompatibilitet (nya fält får default-värden vid avkodning av gamla drafts)

**Vikt-inmatning**: acceptera både punkt och komma som decimaltecken (`parseWeight`).
**Vikt-visning**: formatera med `formatWeight` (NumberFormatter, locale: .current).

**ModelContainer** registrerar `[WorkoutSession.self, CardioSession.self]` — relaterade modeller (ExerciseLog, SetLog) inkluderas automatiskt via `@Relationship`.

---

## Övningar

Exakt dessa fem, i denna ordning, definierade i `ExerciseDef.all`:

| Kanoniskt namn | Visningsnamn | Rep-intervall | Video |
|----------------|-------------|--------------|-------|
| Barbell Back Squat | Barbell Back Squat | 5–8 REPS | YouTube R2dMsNhN3DE |
| Neutral-Grip Incline Dumbbell Bench Press | Incline Dumbbell Bench Press (shortName: Incline Bench Press i ExerciseSection) | 6–10 REPS | YouTube 8nNi8jbbUPE |
| Romanian Deadlift | Romanian Deadlift | 6–8 REPS | YouTube -m45n1_x32E |
| Seated Cable Row | Seated Cable Row | 8–12 REPS | muscleandstrength.com/exercises/seated-row.html |
| Neutral-Grip Lat Pulldown | Lat Pulldown | 8–12 REPS | YouTube iKrKgWR9wbY |

`ExerciseDef` har tre namnfält: `name` (lagras i SwiftData, används som nyckel), `displayName` (visas i UI), `aliases` (gamla namn som migreras vid app-start). Byt aldrig `name` utan att lägga gamla värdet i `aliases` och bumpa `migrationVersion`.

**Pensionering av övning** — när en övning byts ut och gammal data ska bevaras i historik:
1. Flytta definitionen från `all` till `retired` (ingen migration, ingen radering)
2. Lägg till den nya övningen i `all`
3. Gammal data visas korrekt i HistoryCard och ExerciseChartSheet via `ExerciseDef.find(name:)` som söker i båda listorna

**Aktiv radering** (som Chest-Supported Row) är ett separat spår — kräver explicit delete-steg i `migrateExerciseNames`.

Övningsnamnet i StrengthView är en **klickbar rubrik** (Button) som öppnar videon i SFSafariViewController. I HistoryView är namnen klickbara och öppnar `ExerciseChartSheet` (e1RM-progression via Epley-formeln).

---

## Skärmar & Navigation

```
LockView → (Face ID) → HomeView → StrengthView
                               → CardioView
                               → HistoryView
```

- Navigation via `NavigationStack` + `NavigationLink(value: AppScreen)` — ingen skärmposition sparas mellan app-starter (alltid LockView vid ny start)
- Swipe-back aktivt på alla tre undersidor via `enableSwipeBack()`
- **KLAR** sparar och returnerar till HomeView; **←** returnerar utan att spara (men sparar draft om data finns)
- **Swipe-back** beter sig identiskt med ← — sparar draft via `onDisappear` → `saveDraftIfNeeded()` (skippar om `didCompleteSession = true`)

### LockView (ingen accentfärg)
- "EXERCIS" Jost Black 900, centrerat vertikalt med Spacer
- `faceid` SF Symbol (~40pt) som retry-knapp, `.secondary` färg — visas bara om Face ID misslyckades
- `accessibilityLabel: "Logga in"` på retry-ikonen
- Inga platshållare, inget färgat element — neutral skärm
- `auth.authenticate()` triggas i `.onAppear` (auto Face ID) och via ikonen (retry)
- **Obs:** befintlig implementation använder fylld homeAccent-knapp + två `Color.clear.frame(height: 50)` — ersätts vid nästa revision

### HomeView (accentfärg: homeAccent)
- "EXERCIS" (Jost Black 900) + tre knappar i `VStack(spacing: 12)`, `padding(.horizontal, 24)`, `padding(.top, 30)`
- **STYRKA** (fylld, homeAccent) — om draft: **FORTSÄTT STYRKA** + × för att kassera
- **KONDITION** (fylld, workoutAccent) — om draft: **FORTSÄTT KONDITION** + × för att kassera
- **HISTORIK** (konturknapp, historyAccent)
- Senaste passens datum visas under HISTORIK (nyast av styrka/kondition, svensk locale) — klickbart, navigerar till HistoryView
- Kassera-alert: separata `.alert()` för styrka respektive kondition (destructive button)

### StrengthView — Styrketräning (accentfärg: homeAccent)
- Header: "STYRKETRÄNING" 17pt bold, kerning 2 + förkortat datum 13pt + "←" 90pt trailing
- Formuläret **förifyller automatiskt** med tyngsta setets vikt och reps (samma värde på alla tre set) från senaste sessionen; tomt vid allra första passet
- Alltid 3 set per övning
- Kolumnrubriker: **SET, KG, REPS** — layout: SET=maxWidth leading, KG=80pt leading, REPS=120pt trailing
- **Ihopfällbara sektioner**: tryck var som helst på sektionen (ej namn-länk eller textfält) för att fälla ihop/ut. Chevron visas vid ihopfällt läge, rep-intervall vid utfällt. Startar alltid utfällt vid nytt pass.
- **ÖKA-badge**: håll inne (500ms long press) på sektion för att toggla — indikerar vikthöjning nästa pass. Rensas automatiskt om tyngre vikt skrivs in. Sparas i UserDefaults.
- **Tangentbordsverktygsfält**: NÄSTA (navigerar weight→reps→nästa övning) + KLAR, båda i homeAccent. NÄSTA är inaktivt på sista fältet.
- **Draft**: ← sparar till UserDefaults (WorkoutDraft inkl. ihopfällningsläge). Återladdas via FORTSÄTT STYRKA. Rensas vid KLAR eller om alla fält är tomma.
- Datum-texten i headern är klickbar → öppnar `SessionTimePicker` för att sätta anpassat datum/start/slut. Standard: start = när StrengthView öppnades, slut = nu.

### CardioView — Konditionsträning (accentfärg: workoutAccent)
- Header: "KONDITION" 17pt bold, kerning 2 + datum 13pt + "←" 90pt trailing
- **Accordion med 4 typer**: CROSSTRAINER / CYKEL / RODDMASKIN / VANDRING — separerade av ThinDivider
- VANDRING har två tidsfält (H + MIN) istället för ett MIN-fält. Duration sparas som totalt antal minuter i SwiftData och UserDefaults. Visas som "3 h 45 min" i CardioCard. NÄSTA navigerar H → MIN → KM.
- Tryck på en rad för att öppna den; tryck igen för att stänga (ingen behöver vara öppen)
- Öppet/stängt läge sparas i `@AppStorage("lastCardioType")` (tom sträng = ingen öppen)
- Varje typ minns sin senaste *sparade* duration i UserDefaults (`cardioSavedDuration_{TYPE}`) — laddas vid öppning
- **Draft**: ← sparar aktiv typs värde (om ifyllt) till `cardioDraftType`/`cardioDraftMinutes`/`cardioDraftHours`. Återladdas via FORTSÄTT KONDITION. Övriga typers in-session-värden (ej sparade) går förlorade vid ← — de återhämtas från `cardioSavedDuration_*` från senaste slutförda session.
- **Tangentbordsverktygsfält**: NÄSTA (vänster) + KLAR (höger), båda i workoutAccent. NÄSTA navigerar MIN → KM (eller H → MIN → KM för VANDRING).
- KLAR visar effort-picker-overlay om duration är ifylld, annars dismiss direkt. Minns senaste ansträngning per typ i `cardioEffortScore_{TYPE}`.
- Datum-texten i headern är klickbar → öppnar `SessionTimePicker` för att sätta anpassat datum/start/slut. Påverkar `session.startDate`, `session.date` och HealthKit-intervallet. Standard: start = slut − duration, slut = nu.
- KLAR sparar `CardioSession` (inkl. `effortScore`), sparar duration/distans/ansträngning till UserDefaults, loggar till HealthKit

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
  - ExerciseChartSheet: BÄSTA · SENASTE · PASS (enhet: kg, beräknat som e1RM via Epley: `vikt × (1 + reps/30)`)
  - CardioChartSheet: LÄNGST · SENASTE · PASS (enhet: min/km); toggle TID/DISTANS om distansdata finns
  - EffortChartSheet: LÄTTAST · SENASTE · TUFFAST (enhet: /10, visas i grå 14pt); öppnas från ansträngningsraden i HistoryCard (styrkepass)
  - CardioEffortChartSheet: LÄTTAST · SENASTE · TUFFAST per kardioform; öppnas från ansträngningsraden i CardioCard
  - PeriodSummarySheet: STYRKA · VOLYM · KONDITION · TID + **månadsvy**: prickrad (en cirkel per dag, röd=styrka, grön=kondition, gradient=båda, grå=inget); **årsvy**: stapeldiagram per månad. Öppnas från månadsnamn (detent `.height(280)`) respektive årsrubrik (detent `.medium`) i HistoryView. Volym visas i kg (<1000) eller ton (≥1000). Nollvärden visas som `—`.
- Tomt tillstånd om < 2 datapunkter

---

## Apple Health

`HealthKitManager` (singleton `struct`) sparar `HKWorkoutBuilder` till Apple Health:

| Pass | ActivityType | Tid |
|------|-------------|-----|
| Styrketräning | `.traditionalStrengthTraining` | start = när StrengthView öppnas, slut = KLAR |
| Crosstrainer | `.elliptical` | slut = nu, start = nu − minuter |
| Cykel | `.cycling` | slut = nu, start = nu − minuter |
| Roddmaskin | `.rowing` | slut = nu, start = nu − minuter |

- Begär tillstånd vid varje StrengthView/CardioView-öppning (`requestAuthorization()`) — iOS hanterar "redan beviljat" automatiskt
- Alla anrop guards med `HKHealthStore.isHealthDataAvailable()` — no-op på simulator
- `healthKitID: UUID?` sparas på session-objektet för att möjliggöra radering
- Kalorier beräknas via MET × kroppsvikt (läses från HealthKit, fallback 75 kg) × tid i timmar
- **iOS 18+**: ansträngningspoäng sparas som `HKQuantityType(.workoutEffortScore)` via `store.relateWorkoutEffortSample(_:with:activity:)` — gäller både styrke- och konditionspass

---

## UserDefaults-nycklar

| Nyckel | Typ | Ägare | Syfte |
|--------|-----|-------|-------|
| `hasDraft` | Bool (@AppStorage) | HomeView/StrengthView | Om styrke-draft finns |
| `hasCardioDraft` | Bool (@AppStorage) | HomeView/CardioView | Om konditions-draft finns |
| `lastCardioType` | String (@AppStorage) | CardioView | Senast öppnad/stängd typ (tom = ingen) |
| `workoutDraft` | Data | UserDefaults | WorkoutDraft (JSON) inkl. ihopfällningsläge |
| `cardioDraftType` | String | UserDefaults | Typ för konditions-draft |
| `cardioDraftMinutes` | String | UserDefaults | Minuter för konditions-draft |
| `cardioDraftDistance` | String | UserDefaults | Distans (km) för konditions-draft |
| `cardioDraftHours` | String | UserDefaults | Timmar för vandringsdraft (enbart VANDRING) |
| `cardioSavedDuration_{TYPE}` | String | UserDefaults | Senast sparad duration per kardioform |
| `cardioSavedDistance_{TYPE}` | String | UserDefaults | Senast sparad distans per kardioform |
| `cardioEffortScore_{TYPE}` | Int | UserDefaults | Senast sparad ansträngning per kardioform (startvärde i picker) |
| `workoutEffortScore` | Int | UserDefaults | Senast sparad ansträngning för styrkepass (startvärde i picker) |
| `increaseExercises` | [String] | UserDefaults | Övningsnamn med aktiv ÖKA-badge (styrka) |
| `increaseCardioTypes` | [String] | UserDefaults | Kardioformer med aktiv ÖKA-badge |
| `exerciseNameMigrationVersion` | Int | UserDefaults | Version för körd namnmigration (bumpa vid övningsändringar) |

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
- Inga explicita schema-migrationer definierade — fungerar om nya `@Model`-fält ges default-värden. Vid framtida namnbyten/borttag av fält krävs `VersionedSchema` + `SchemaMigrationPlan`.
- `try? context.save()` används genomgående — fel loggas ej (acceptabelt för single-user app)

---

## Enhetflexibilitet (framtidssäkring)

Vikt och tid lagras som råtal utan enhet — `Double` för kg, `Double` för minuter. Enheter antas i UI:t (alltid "KG" resp. "MIN"). Om appen framöver ska stödja lbs eller timmar/sekunder:
- Lagra en `unit`-sträng bredvid värdet, eller konvertera vid presentation
- Bryt inte befintliga SwiftData-fält (`weight: Double`, `durationMinutes: Double`) — lägg till nya fält med default-värden för att undvika migration
- `formatWeight` i Theme.swift är den enda formateringsplatsen för vikt — enhetsbyte görs där

---

## Kommande expansion — beslutade designval

### Färgsystem (program + strukturella skärmar)
- **Strukturella skärmar** har fasta appfärger: LockView (neutral), HomeView (`homeAccent`), CardioView (`workoutAccent`), HistoryView (`historyAccent`), Settings/Profile (neutral, inga accenter)
- **Träningsprogram** har användardefinierade färger (väljs ur kuraterad palett vid skapandet)
- **StrengthView** under aktivt pass använder det aktiva programmets färg, inte `homeAccent`
- Programkort på HomeView visas i respektive programs färg

### GIF-system
```swift
enum GifSource: String, Codable {
    case hasaneyldrm   // primär källa, icke-kommersiell
    case exercisedb    // sekundär källa, icke-kommersiell
    case needsSource   // borde ha GIF men ingen hittad än (roddmaskin, assault bike m.fl.)
    case none          // behöver inte GIF (aktiviteter, inte rörelsemönster)
}
```
- Övningsnamn med GIF visas i accentfärg (tryckbar) — utan GIF i `.primary`
- Tryck → halvskärm med GIF
- `ⓘ` (SF Symbol `info.circle`) i GIF-sheeten → expanderar till detaljer: primära muskler, sekundära muskler, beskrivningstext (Apple Photos-mönster)
- GIF-mappning: `gif_mapping.md` i projektets rot (180 styrkeövningar, exact/strong/weak/none)
- GIF-filer: `Exercis/Resources/GIFs/` (folder reference i Xcode, blå mappikon)

### Träningsprogram — datamodell
- `ExerciseDef`: statisk struct → SwiftData `@Model`
- Ny modell `WorkoutProgram`: namn, färg, ordnad övningslista (`sortIndex: Int` på junction-entitet)
- `ExerciseLog` får `exerciseDefId: String?`
- Prefill per program (senaste vikt per program, inte globalt)
- `programID` lagras på `WorkoutSession`

### Programkort

4pt färglist i programfärg längs toppen. Vit bakgrund, `Color(.separator)` 0.5pt kant, `cornerRadius(8)`. Programnamn: Jost Bold 15pt, kerning 1.5, programfärg. Undertitel "5 ÖVNINGAR · 3 SET": Jost Medium 10pt, kerning 1.5, `.secondary`. Markerat: programfärg 12% opacitet som bakgrund + `checkmark.circle.fill` i programfärg uppe till höger. Används i onboarding-grid och programlista — inte som primär action-knapp på HomeView.

### Standardprogram (7 st, alla med 5 övningar och 3 set som default)
| # | Program | Grupp |
|---|---------|-------|
| 1 | Full Body | HELKROPP |
| 2 | Överkropp | SPLIT |
| 3 | Underkropp | SPLIT |
| 4 | Push | PUSH–PULL–LEGS |
| 5 | Pull | PUSH–PULL–LEGS |
| 6 | Legs | PUSH–PULL–LEGS |
| 7 | Bodyweight | KROPPSVIKT |

Bodyweight-programmet (5 övningar): Body Squats (`wger_body_squats`), Push Ups (`wger_push_ups`), Bodyweight Lunges (`wger_bodyweight_lunges`), Superman (`wger_superman`), Plank (`wger_plank`)

### Navigation — TabView

Ersätter nuvarande custom HomeView. Tre tabbar synliga i vila mellan pass:

```
│  💪 Styrka  │  ♥ Kondition  │  📊 Historik  │
```

- **Styrka** → `ProgramListView` med programkort. Tryck program → `StrengthView` som `.fullScreenCover` (tab-bar dold under aktivt pass). Draft visas som "FORTSÄTT [PROGRAMNAMN]" överst.
- **Kondition** → kardio-typer (användarens personliga lista). Tryck typ → CardioView som `.fullScreenCover`.
- **Historik** → som nu.
- **Inställningar** → kugghjulsikon (`gear`, SF Symbol) i navigationsbaren, öppnar Settings/Profile som sheet.

LockView ligger kvar som `.fullScreenCover` ovanpå TabView vid app-launch.

### Onboarding (2 steg)
**Steg 1 — Träningsprogram:**
- Grid med 7 programkort i tematiska grupper separerade av whitespace — inga gruppetikett-rubriker
- Full Body ensam (full bredd) · Överkropp + Underkropp (2-kolumner) · Push + Pull + Legs (3 kolumner, lika breda) · Bodyweight ensam (full bredd)
- Alla kort samma storlek
- Multi-select — tryck för att toggla
- HOPPA ÖVER (textknapp) + FORTSÄTT → (fylld, inaktiv tills val gjorts)

**Steg 2 — Kondition:**
- Checkboxar per kardioform, grupperade efter subcategory (MASKINER / UTOMHUS / NORDISKA etc.)
- Bygger användarens personliga Kondition-lista
- HOPPA ÖVER + KOM IGÅNG →

Behörigheter (Face ID, HealthKit) begärs **inte** i onboarding — frågas kontextuellt vid första användning.

### CardioType enum
Se `cardio_types.json` — 26 typer med `id` (språkneutralt), `displayName`, `hkActivityType`, `gifSource`, `hasDistance`, `hasElevation`. Migration: `migratedFrom`-fältet per typ.

### HealthKit — utökat
- `HKWorkoutActivity` (iOS 17+): varje `ExerciseLog` → aktivitetssegment i workout
- `HKQuantityType(.distanceHillAscent/.distanceHillDescent)` (iOS 16+) för vandring/löpning via `CMAltimeter`
- `CardioSession` får `elevationGain: Double?`

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
