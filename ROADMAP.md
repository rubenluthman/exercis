# Exercis Roadmap

Allt planerat, beslutat och parkerat på ett ställe.
Uppdateras löpande under sessioner och vid apprevision.

**Arbetsflöde:** när något är klart — flytta det till **Klart**-sektionen längst ner. Stryk inte bara över det där det står.

---


## Planerade funktioner

*(Inga kvarstående)*

---

## Beslutade designval (ej byggt än)

*(Inga kvarstående — alla designval är implementerade)*

---

## Inför App Store (kräver Developer-konto)

- **iCloud Sync (CloudKit)** — kräver betalt konto
- **GIF-licens** — byt hasaneyldrm mot licensierad källa (ExerciseDB Pro) innan submission
- **GIF-filer i git** — ~~finns i historik trots .gitignore, behöver städas~~ rensat med git-filter-repo (2026-06-05)
- **Widgets** — streak och "nästa program"; kräver Widget Extension + App Group

---

## Parkerat

**Rubens beslut:**
- **HIIT** — timer-baserad träning; `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`

**Claudes förslag (avskrivna):**
- **TabView-omstrukturering** — 3 tabbar (Styrka / Kondition / Historik) avskrivet. 4-tabbar med samlad Träning-tab (program + kondition på en sida) är rätt struktur, ger gott om plats.
- **ExerciseDef → SwiftData `@Model`** — inget praktiskt behov; prefill per program fungerar redan via `programId` på `WorkoutSession`.
- **HKWorkoutActivity per övning** — segmentlängd = rörelse + vila, går inte att särskilja, ger ingen meningsfull data
- **Siri Shortcuts** — saknar tydligt use case för en-användarapp
- **Apple Watch-app** — Ruben har ingen klocka
- **Swift Packages** (`swift-algorithms`, `swift-collections`) — inte motiverat förrän appen växer

---

## Klart

- [x] Onboarding — 2 steg (program-grid + konditionscheckboxar), standardprogram seedas (2026-06-05)
- [x] GIF-system — 155 övningar med GIF (accentfärg + tryckbar), GifSheet med WKWebView + muskelinfo (2026-06-05)
- [x] Övningsbeskrivningar — 186 granskade, 8 faktafel åtgärdade (2026-06-05)
- [x] exercises_def.json + cardio_types.json — AI-revision via Gemini + ChatGPT (2026-06-05)
- [x] Begränsningsfilter — kroppsbegränsningar + programbegränsningar i ExercisePickerView
- [x] Enhetssystem lbs/miles (2026-06-04)
- [x] TrainingView — Träning-tab med program + konditionsformer (2026-06-04)
- [x] Inställningar som egen tab (2026-06-04)
- [x] Automatisk tidsloggning för kondition (2026-06-04)
- [x] Aliases + beskrivningar för alla övningar — 186/186 (2026-06-04)
- [x] CSV-export (2026-06-02)
- [x] Haptics centraliserade (2026-06-02)
- [x] Onboarding-dubletter vid reinstall (2026-06-05)
- [x] Zombie Live Activity vid krasch (2026-06-05)
- [x] SwiftData-fel synliga i UI (2026-06-05)
- [x] Lokalisering — engelska basspråk, svenska via sv.lproj (2026-06-05)
- [x] XCTest-target + första tester (Epley, viktsformatering) (2026-06-05)
- [x] WorkoutDraft encode/decode + bakåtkompatibilitet (2026-06-05)
- [x] Migrationstester — CardioType + övningsnamn (2026-06-05)
- [x] CardioType-mappningstester — tracksElevation + HKWorkoutActivityType (2026-06-05)
- [x] hkActivityType extraherad till CardioType — enda sanningskälla (2026-06-05)
- [x] Fix: duplikat-alias-krasch i migrateExerciseNames (2026-06-05)
- [x] Fix: lokalisering i hjälpfunktioner (Text(LocalizedStringKey)) (2026-06-05)

*Senast uppdaterad: 2026-06-05*

