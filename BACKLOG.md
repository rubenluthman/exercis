# Exercis Backlog

Två kategorier: **Rubens beslut** (explicit överenskommet) och **Claudes rekommendationer** (förslag att diskutera).
Uppdateras löpande under sessioner och vid apprevision.

---

## Rubens beslut

- [x] **Enhetssystem (lbs/miles)** — klart 2026-06-04; charts (ExerciseChartSheet, CardioChartSheet, PeriodSummarySheet) konverterar ännu inte — nästa revision
- [ ] **Övningsbeskrivningar — kvalitetsgenomgång** — 186 beskrivningar genererade av Claude, 15 förbättrade med wger som referens. Resterande 171 är ej granskade mot extern källa. ~60 wger-texter har tekniska detaljer vi saknar.

- [x] **CSV-export** — klart 2026-06-02
- [x] **Fixa buggar B–E** — klart 2026-06-02
- [x] **CHANGELOG.md** — klart 2026-06-02
- [x] **TrainingView** — Träning-tab med valda program + konditionsformer, klart 2026-06-04
- [x] **Inställningar som egen tab** — programhantering + konditionsformer, klart 2026-06-04
- [x] **Automatisk tidsloggning för kondition** — tid mäts från öppning till KLAR, klart 2026-06-04
- [x] **Aliases + beskrivningar för alla övningar** — 186/186 klart 2026-06-04

---

## Claudes rekommendationer

### 🔴 Hög prioritet (svåra att lägga till senare)

- [x] **CardioType.displayName som property på modellen** — åtgärdad
- [x] **Prefill per program, inte senaste session** — åtgärdad
- [x] **selectedCardioTypes från onboarding används inte** — åtgärdad
- [x] **Enhetssystem: ta bort döda UI-inställningar** — åtgärdad

### 🟡 Snart

- [x] **ProfileView INSTÄLLNINGAR-länk** — åtgärdad 2026-06-02
- [x] **ProgramCard hardkodar "3 SET"** — åtgärdad 2026-06-02
- [x] **PhotosPicker i ProfileView saknar accessibilityLabel** — åtgärdad 2026-06-02

### 🟢 Nästa revision

- [x] **LockView placeholder-hack** — åtgärdad 2026-06-02
- [x] **Haptics centraliserade** — åtgärdad 2026-06-02

---

## Inför App Store-release (kräver Developer-konto)

- **iCloud Sync (CloudKit)** — kräver betalt Developer-konto
- **GIF-licens** — byt hasaneyldrm-källan mot licensierad (ExerciseDB Pro) innan submission
- **GIF-filer i git** — städa bort från repot; i .gitignore men finns i historik

---

## Rubens parkerade beslut

- **HIIT** — timer-baserad träning; `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`

---

## Claudes parkerade förslag

- **Begränsningsfilter** — tagg-annotering per övning; varningsikon vid konflikt
- **Siri Shortcuts** — App Intents; saknar tydligt use case för en-användarapp där appen öppnas manuellt
- **Widgets** — streak, nästa program
- **Apple Watch-app** — Ruben har ingen klocka
- **HKWorkoutActivity per övning** — loggar varje ExerciseLog som aktivitetssegment i HealthKit
- **Apple Swift Packages** — `swift-algorithms` + `swift-collections`; inte prioriterat förrän appen växer
- **ProgramListView** — fil är defunct (ersatt av TrainingView + SettingsView); kan tas bort

---

---

## Revision 2026-06-04 — fynd

- [x] Deployment target var 26.5 — fixat till 17.0
- [x] `draftActiveKey` i CardioView — oanvänd variabel, borttagen
- [x] `longPressFired` i CardioView — kvarglömt från accordion, borttaget
- [x] `lastCardioType` AppStorage — borttagen (accordion-artefakt)
- [x] `distanceCrossCountrySkiing` — saknade `#available(iOS 18.0, *)` guard

*Senast uppdaterad: 2026-06-04*
