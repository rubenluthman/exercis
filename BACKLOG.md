# Exercis Backlog

Två kategorier: **Rubens beslut** (explicit överenskommet) och **Claudes rekommendationer** (förslag att diskutera).
Uppdateras löpande under sessioner och vid apprevision.

---

## Rubens beslut

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

## Rubens parkerade beslut

- **HIIT** — timer-baserad träning; `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`
- **iCloud Sync (CloudKit)** — kräver betalt Developer-konto
- **GIF-licens vid App Store** — byt hasaneyldrm → ExerciseDB Pro innan submission

---

## Claudes parkerade förslag

- **Live Activities / Dynamic Island** — visar aktivt set/övning på låsskärmen under pass
- **GIF-filer i git** — nu i .gitignore; ersätt med licensierad källa innan App Store
- **Enhetssystem (lbs/miles)** — AppStorage-nycklar finns; implementera konsekvent när det prioriteras
- **Begränsningsfilter** — tagg-annotering per övning; varningsikon vid konflikt
- **Siri Shortcuts** — App Intents; "Hej Siri, starta ett pass"
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
