# Exercis Backlog

Två kategorier: **Rubens beslut** (explicit överenskommet) och **Claudes rekommendationer** (förslag att diskutera).
Uppdateras löpande under sessioner och vid apprevision.

---

## Rubens beslut

- [x] **CSV-export** — klart 2026-06-02
- [x] **Fixa buggar B–E** — klart 2026-06-02
- [x] **CHANGELOG.md** — klart 2026-06-02

---

## Claudes rekommendationer

### 🔴 Hög prioritet (svåra att lägga till senare)

- [x] **CardioType.displayName som property på modellen** — visningsnamnen finns bara som privat metod i OnboardingView, orsakar aktiv bugg i CardioView (visar "cycling_stationary" etc.) och leder till duplication i varje ny vy
- [x] **Prefill per program, inte senaste session** — `buildForms` tar `sessions.first` oavsett program; med 7 program märks detta direkt. `programId` finns redan på `WorkoutSession`
- [x] **selectedCardioTypes från onboarding används inte** — sparas i AppStorage men läses aldrig av CardioView; onboarding-steg 2 är meningslöst just nu
- [x] **Enhetssystem: ta bort döda UI-inställningar** — AppStorage-nycklar behållna för framtida implementation — `weightUnit`/`distanceUnit` finns i Settings men ignoreras av formulär, historik, charts och HealthKit. Varje ny vy som byggs utan enhetsmedvetenhet gör det dyrare att fixa

### 🟡 Snart

- [x] **ProfileView INSTÄLLNINGAR-länk** — åtgärdad 2026-06-02
- [x] **ProgramCard hardkodar "3 SET"** — åtgärdad 2026-06-02
- [x] **PhotosPicker i ProfileView saknar accessibilityLabel** — åtgärdad 2026-06-02

### 🟢 Nästa revision

- [x] **LockView placeholder-hack** — åtgärdad 2026-06-02
- [x] **Haptics centraliserade** — `Haptics`-enum i Theme.swift, alla inline-anrop ersatta — åtgärdad 2026-06-02

---

## Parkerat

- **GIF-filer i git** — acceptabelt tills köpt databas ersätter dem; lägg till `Exercis/Resources/GIFs/` i `.gitignore` när bytet sker
- **`cardio_types.json` i Resources laddas inte av någon Swift-kod** — planerad men ej implementerad; ta upp när CardioType-systemet byggs om
- **Enhetssystem (lbs/miles)** — AppStorage-nycklar finns, UI borttaget; implementera konsekvent i formulär, historik, charts och HealthKit när det prioriteras
- **HIIT** — timer-baserad träning med work/rest-intervall; `HIITProgram`-modell och `HIITView` med nedräkning; HealthKit: `.highIntensityIntervalTraining`
- **Övningsväljare** — textbaserad sökning med muskelgrupp- och begränsningsfilter (axel, knä, ländrygg, handled); fuzzy-matching; taggontologin bestäms innan kureringen
- **Begränsningsfilter** — manuell tagg-annotering per övning; övningar markeras med varningsikon vid konflikt, döljs inte
- ~~**Vila-timer**~~ — byggt 2026-06-02
- ~~**PR-detektion**~~ — byggt 2026-06-02
- **Live Activities / Dynamic Island** — visar aktivt set/övning på låsskärmen under pass
- **Siri Shortcuts** — "Starta mitt träningspass" via App Intents
- **Widgets** — dagens träning, veckans streak, nästa program
- **iCloud Sync (CloudKit)** — kräver betalt Developer-konto; rimlig premiumfunktion
- **Apple Watch-app** — Ruben har ingen klocka men Exercis borde ha Watch-stöd
- **HKWorkoutActivity per övning** — loggar varje `ExerciseLog` som ett aktivitetssegment i HealthKit; ger rikare vy i Apple Fitness
- **elevationGain för vandring/löpning** — `CMAltimeter` via iPhone; `HKQuantityType(.distanceHillAscent/.distanceHillDescent)` (iOS 16+)
- ~~**Reduce Motion för GIFs**~~ — byggt i GifSheet 2026-06-02
- **GIF-licens vid App Store** — byt hasaneyldrm → ExerciseDB Pro innan submission; flaggas automatiskt när App Store eller Developer-konto nämns
- **Apple Swift Packages** — `swift-algorithms` (`chunked(by:)` för månadsgrupper i HistoryView) och `swift-collections` (`OrderedDictionary`) kan förenkla datakod; inte prioriterat förrän appen växer
- **Aliases för övningar** — 198 övningar saknar alternativa söknamn; kräver en källa (synonymdatabas) eller manuell genomgång; de tre migrerade övningarna (Squats, Incline Dumbbell Press, Wide-Grip Pulldown) är klara

---

*Senast uppdaterad: 2026-06-02 — alla kända åtgärdspunkter klara*
