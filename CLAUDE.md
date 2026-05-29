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
HealthKitManager.swift    ← sparar HKWorkout till Apple Health
```

---

## Theme.swift

Enda plats för färger, typsnitt, knappstillar och gemensamma UI-komponenter.

### Färger
```swift
Color.homeAccent    // #B04848 ljust / #D06868 mörkt  — dämpad röd    (LockView, HomeView, StrengthView)
Color.workoutAccent // #4A8050 ljust / #5EAA66 mörkt  — sagegreen     (CardioView / kondition)
Color.historyAccent // #4878B0 ljust / #6A9FD4 mörkt  — cornflowerblå (HistoryView, HistoryCard, CardioCard, alla chart sheets)
Color.appBackground // Color(.systemBackground) — adaptiv (vit i ljust läge, mörk i mörkt läge)
Color.appDivider    // Color(.separator) — används av ThinDivider (0.5 pt)
```

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
- All text i UI:t ska vara på **svenska** — undantag: övningsnamnen (Barbell Back Squat etc.) som är på engelska
- Datum formateras alltid med `Locale(identifier: "sv_SE")`
- KLAR-knapp: fylld i accentfärg, längst ner i vyn — undantag: i CardioView flödar den ovanför effort-sheeten
- Tillbaka-knapp: bara "←" utan text, font regular 22pt, `.frame(width: 90, alignment: .trailing)`
- Horizontal padding: **24pt** genomgående på alla rader

---

## Datamodeller (SwiftData)

**Cascade delete på alla relationer.**

```swift
@Model class WorkoutSession {
    var id: UUID; var date: Date; var healthKitID: UUID?; var effortScore: Int?
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
    var id: UUID; var date: Date; var durationMinutes: Double
    var cardioType: String; var healthKitID: UUID?; var distanceKm: Double?; var effortScore: Int?
}
```

**`CardioType` enum** (i Models.swift):
```swift
enum CardioType: String, Codable, CaseIterable {
    case crosstrainer = "CROSSTRAINER"
    case cykel        = "CYKEL"
    case roddmaskin   = "RODDMASKIN"
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

### LockView (accentfärg: homeAccent)
- "EXERCIS" Jost Black 900, centrerat vertikalt med Spacer
- `VStack(spacing: 12)` med `padding(.top, 30)` — matchar HomeView exakt
- LOGGA IN-knapp (fylld, homeAccent) + två `Color.clear.frame(height: 50)` som platshållare
- `auth.authenticate()` triggas i `.onAppear` (auto Face ID) och via LOGGA IN-knapp (retry)

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

### CardioView — Konditionsträning (accentfärg: workoutAccent)
- Header: "KONDITION" 17pt bold, kerning 2 + datum 13pt + "←" 90pt trailing
- **Accordion med 3 typer**: CROSSTRAINER / CYKEL / RODDMASKIN — separerade av ThinDivider
- Tryck på en rad för att öppna den; tryck igen för att stänga (ingen behöver vara öppen)
- Öppet/stängt läge sparas i `@AppStorage("lastCardioType")` (tom sträng = ingen öppen)
- Varje typ minns sin senaste *sparade* duration i UserDefaults (`cardioSavedDuration_{TYPE}`) — laddas vid öppning
- **Draft**: ← sparar aktiv typs värde (om ifyllt) till `cardioDraftType`/`cardioDraftMinutes`. Återladdas via FORTSÄTT KONDITION. Övriga typers in-session-värden (ej sparade) går förlorade vid ← — de återhämtas från `cardioSavedDuration_*` från senaste slutförda session.
- **Tangentbordsverktygsfält**: KLAR (vänster, stänger tangentbord) + NÄSTA (höger, går från MIN till KM), båda i workoutAccent
- Ovanför effort-sheet flödar en separat KLAR-knapp (fylld, workoutAccent) — ligger ovanpå sheet-containern, synlig utan att öppna sheeten
- KLAR visar effort-picker-overlay om duration är ifylld, annars dismiss direkt. Minns senaste ansträngning per typ i `cardioEffortScore_{TYPE}`.
- KLAR sparar `CardioSession` (inkl. `effortScore`), sparar duration/distans/ansträngning till UserDefaults, loggar till HealthKit

### HistoryView (accentfärg: historyAccent)
- Header: "HISTORIK" 17pt bold + "←" 90pt trailing
- `HistoryEntry`-enum (`.workout` / `.cardio`) blandar och sorterar nyast först
- **Månadsgrupper** (`MonthGroup`): poster grupperas per år/månad, rubrik i historyAccent med antal styrka/kondition. Ihopfällbara — senaste månaden öppen, övriga stängda vid första öppning. Visas som "MÅNAD" inom aktuellt år, "MÅNAD ÅÅÅÅ" för äldre år.
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
10. All UI-text på svenska (utom övningsnamn på engelska)
