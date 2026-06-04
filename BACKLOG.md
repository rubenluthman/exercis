# Exercis Backlog

Två kategorier: **Rubens beslut** (explicit överenskommet) och **Claudes rekommendationer** (förslag att diskutera).
Uppdateras löpande under sessioner och vid apprevision.

---

## Rubens beslut

- [x] ~~**Övningsbeskrivningar — kvalitetsgenomgång** — klart 2026-06-05; alla 186 granskade via GPT-4o + Gemini, 8 faktafel/säkerhetsrisker åtgärdade~~
- [x] ~~**exercises_def.json + cardio_types.json — AI-revision** — klart 2026-06-05; contraindications (16 övningar), repRange/setRange (19 övningar) och hkActivityType (2 kardioformer) granskade och korrigerade via Gemini + ChatGPT. Mistral testades men gav oanvändbar output (hallucerade ID:n och fel taggformat).~~

- [x] ~~**Enhetssystem (lbs/miles)** — klart 2026-06-04; charts (ExerciseChartSheet, CardioChartSheet, PeriodSummarySheet) konverterar ännu inte — nästa revision~~
- [x] ~~**CSV-export** — klart 2026-06-02~~
- [x] ~~**Fixa buggar B–E** — klart 2026-06-02~~
- [x] ~~**CHANGELOG.md** — klart 2026-06-02~~
- [x] ~~**TrainingView** — Träning-tab med valda program + konditionsformer, klart 2026-06-04~~
- [x] ~~**Inställningar som egen tab** — programhantering + konditionsformer, klart 2026-06-04~~
- [x] ~~**Automatisk tidsloggning för kondition** — tid mäts från öppning till KLAR, klart 2026-06-04~~
- [x] ~~**Aliases + beskrivningar för alla övningar** — 186/186 klart 2026-06-04~~

---

## Claudes rekommendationer

### 🔴 Hög prioritet (svåra att lägga till senare)

- [x] ~~**CardioType.displayName som property på modellen** — åtgärdad~~
- [x] ~~**Prefill per program, inte senaste session** — åtgärdad~~
- [x] ~~**selectedCardioTypes från onboarding används inte** — åtgärdad~~
- [x] ~~**Enhetssystem: ta bort döda UI-inställningar** — åtgärdad~~

### 🟡 Snart

- [x] ~~**ProfileView INSTÄLLNINGAR-länk** — åtgärdad 2026-06-02~~
- [x] ~~**ProgramCard hardkodar "3 SET"** — åtgärdad 2026-06-02~~
- [x] ~~**PhotosPicker i ProfileView saknar accessibilityLabel** — åtgärdad 2026-06-02~~

### 🟢 Nästa revision

- [x] ~~**LockView placeholder-hack** — åtgärdad 2026-06-02~~
- [x] ~~**Haptics centraliserade** — åtgärdad 2026-06-02~~

---

## Inför App Store-release (kräver Developer-konto)

- **iCloud Sync (CloudKit)** — kräver betalt Developer-konto
- **GIF-licens** — byt hasaneyldrm-källan mot licensierad (ExerciseDB Pro) innan submission
- **GIF-filer i git** — städa bort från repot; i .gitignore men finns i historik
- **Widgets** — streak och "nästa program"; kräver Widget Extension + App Group

---

## Rubens parkerade beslut

- **HIIT** — timer-baserad träning; `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`

---

## Claudes parkerade förslag

- **Begränsningsfilter** — tagg-annotering per övning; varningsikon vid konflikt
- **Siri Shortcuts** — App Intents; saknar tydligt use case för en-användarapp där appen öppnas manuellt
- **Apple Watch-app** — Ruben har ingen klocka
- **HKWorkoutActivity per övning** — ett pass, inte fem; segmenten syns under workoutet i Hälsa. Problemet: segmentlängd = rörelse + vila, går inte att särskilja — ger ingen meningsfull data
- **Apple Swift Packages** — `swift-algorithms` + `swift-collections`; inte prioriterat förrän appen växer

---

---

## Revision 2026-06-04 — fynd

- [x] Deployment target var 26.5 — fixat till 17.0
- [x] `draftActiveKey` i CardioView — oanvänd variabel, borttagen
- [x] `longPressFired` i CardioView — kvarglömt från accordion, borttaget
- [x] `lastCardioType` AppStorage — borttagen (accordion-artefakt)
- [x] `distanceCrossCountrySkiing` — saknade `#available(iOS 18.0, *)` guard

*Senast uppdaterad: 2026-06-05*
