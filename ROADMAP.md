# Exercis Roadmap

Allt planerat, beslutat och parkerat på ett ställe.
Uppdateras löpande under sessioner och vid apprevision.

---

## Näst på tur

- **Extern LLM-analys av kodbasen** — filer redo: `full_codebase.txt` + `llm_analysis_prompt.md`. Kör i Gemini 2.5 Pro, ta med fynd till FleetView.
- **GIF-system** — isolerat, ger direkt synlig förbättring, blockerar ingenting. Bra startpunkt.

---

## Planerade funktioner

### GIF-system
- Övningsnamn med GIF visas i accentfärg (tryckbar) — utan GIF i `.primary`
- Tryck → halvskärm med GIF (WKWebView, base64-inbäddning)
- `ⓘ` (`info.circle`) i GIF-sheeten → expanderar till primära muskler, sekundära muskler, beskrivningstext (Apple Photos-mönster)
- GIF-mappning: `gif_mapping.md` i projektets rot (180 övningar, exact/strong/weak/none)
- GIF-filer: `Exercis/Resources/GIFs/` (folder reference i Xcode)

```swift
enum GifSource: String, Codable {
    case hasaneyldrm   // primär källa, icke-kommersiell
    case exercisedb    // sekundär källa, icke-kommersiell
    case needsSource   // borde ha GIF men ingen hittad än
    case none          // behöver inte GIF
}
```

### TabView-navigation
Ersätter nuvarande custom TrainingView + navigationDestination. Tre tabbar:

```
│  💪 Styrka  │  ♥ Kondition  │  📊 Historik  │
```

- **Styrka** → `ProgramListView` med programkort. Tryck program → `StrengthView` som `.fullScreenCover` (tab-bar dold under aktivt pass). Draft visas som "FORTSÄTT [PROGRAMNAMN]" överst.
- **Kondition** → användarens kardio-lista. Tryck typ → `CardioView` som `.fullScreenCover`.
- **Historik** → som nu.
- **Inställningar** → `gear`-ikon i navigationsbaren, öppnar Settings/Profile som sheet.

LockView ligger kvar som `.fullScreenCover` ovanpå TabView vid app-launch.

### ExerciseDef → SwiftData
- `ExerciseDef`: statisk struct → SwiftData `@Model`
- `ExerciseLog` får `exerciseDefId: String?`
- `programID` lagras på `WorkoutSession`
- Prefill per program (senaste vikt per program, inte globalt) — redan klart i logik, kräver datamodell

### Onboarding (2 steg)
**Steg 1 — Träningsprogram:**
- Grid med 7 programkort i tematiska grupper (whitespace som separator, inga rubriker)
- Full Body ensam · Överkropp + Underkropp · Push + Pull + Legs · Bodyweight ensam
- Multi-select, HOPPA ÖVER + FORTSÄTT → (inaktiv tills val gjorts)

**Steg 2 — Kondition:**
- Checkboxar per kardioform, grupperade efter subcategory
- HOPPA ÖVER + KOM IGÅNG →

Behörigheter (Face ID, HealthKit) begärs inte i onboarding — frågas kontextuellt.

### HealthKit — utökat
- `HKWorkoutActivity` (iOS 17+): varje `ExerciseLog` → aktivitetssegment i workout
- `HKQuantityType(.distanceHillAscent/.distanceHillDescent)` (iOS 16+) för vandring/löpning via `CMAltimeter`
- `CardioSession` får `elevationGain: Double?`

---

## Beslutade designval (ej byggt än)

### Färgsystem
- Strukturella skärmar har fasta appfärger: LockView (neutral), TrainingView (`homeAccent`), CardioView (`workoutAccent`), HistoryView (`historyAccent`), Settings/Profile (neutral)
- Träningsprogram har användardefinierade färger (kuraterad palett)
- StrengthView under aktivt pass använder programmets färg, inte `homeAccent`

### Programkort
4pt färglist längs toppen. Vit bakgrund, `Color(.separator)` 0.5pt kant, `cornerRadius(8)`. Programnamn: Jost Bold 15pt, kerning 1.5, programfärg. Undertitel "5 ÖVNINGAR · 3 SET": Jost Medium 10pt, kerning 1.5, `.secondary`. Markerat: programfärg 12% opacitet + `checkmark.circle.fill` uppe till höger.

### Standardprogram (7 st, 5 övningar och 3 set som default)
| # | Program | Grupp |
|---|---------|-------|
| 1 | Full Body | HELKROPP |
| 2 | Överkropp | SPLIT |
| 3 | Underkropp | SPLIT |
| 4 | Push | PUSH–PULL–LEGS |
| 5 | Pull | PUSH–PULL–LEGS |
| 6 | Legs | PUSH–PULL–LEGS |
| 7 | Bodyweight | KROPPSVIKT |

Bodyweight: Body Squats, Push Ups, Bodyweight Lunges, Superman, Plank (`wger_*`-id:n)

### CardioType enum
Se `cardio_types.json` — 26 typer med `id`, `displayName`, `hkActivityType`, `gifSource`, `hasDistance`, `hasElevation`. Migration via `migratedFrom`-fältet.

---

## Inför App Store (kräver Developer-konto)

- **iCloud Sync (CloudKit)** — kräver betalt konto
- **GIF-licens** — byt hasaneyldrm mot licensierad källa (ExerciseDB Pro) innan submission
- **GIF-filer i git** — finns i historik trots .gitignore, behöver städas
- **Widgets** — streak och "nästa program"; kräver Widget Extension + App Group

---

## Parkerat

**Rubens beslut:**
- **HIIT** — timer-baserad träning; `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`

**Claudes förslag (avskrivna):**
- **Siri Shortcuts** — saknar tydligt use case för en-användarapp
- **Apple Watch-app** — Ruben har ingen klocka
- **HKWorkoutActivity per övning** — segmentlängd = rörelse + vila, går inte att särskilja, ger ingen meningsfull data
- **Swift Packages** (`swift-algorithms`, `swift-collections`) — inte motiverat förrän appen växer

---

## Klart

- [x] Övningsbeskrivningar — 186 granskade, 8 faktafel åtgärdade (2026-06-05)
- [x] exercises_def.json + cardio_types.json — AI-revision via Gemini + ChatGPT (2026-06-05)
- [x] Begränsningsfilter — kroppsbegränsningar + programbegränsningar i ExercisePickerView
- [x] Onboarding — pencil-ikon för att redigera program direkt (2026-06-04)
- [x] Enhetssystem lbs/miles (2026-06-04)
- [x] TrainingView — Träning-tab med program + konditionsformer (2026-06-04)
- [x] Inställningar som egen tab (2026-06-04)
- [x] Automatisk tidsloggning för kondition (2026-06-04)
- [x] Aliases + beskrivningar för alla övningar — 186/186 (2026-06-04)
- [x] CSV-export (2026-06-02)
- [x] Haptics centraliserade (2026-06-02)

*Senast uppdaterad: 2026-06-05*
