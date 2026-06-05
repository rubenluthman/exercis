# Exercis – Backlog

Två kategorier: **Rubens beslut** (explicit bekräftade val) och **Claudes rekommendationer** (identifierade under revision eller löpande arbete). Det ska aldrig vara oklart vilken kategori något tillhör.

---

## Rubens beslut

| Beslut | Motivering |
|--------|------------|
| Ingen HIIT-timer | Oklart use case |
| 4-tab-layout är final | TabView-strukturen förhandlas inte |
| Ingen Apple Watch-app | Ruben har ingen Watch |
| Inga Siri Shortcuts | Single-user-app, låg prioritet |

---

## Claudes rekommendationer

### Hög prioritet

- **iOS 26 / Liquid Glass-anpassning** — `FilledButtonStyle`/`OutlineButtonStyle` tar inte glass-behandling automatiskt. `.toolbar(.hidden)` + manuell back-knapp bryter mot redesignad nav-bar. `softScrollEdge()` kan kollidera med nativa glass-scrolledges. Behöver en dedikerad genomgång mot iOS 26.

- **CloudKit-sync** — utan det förlorar användaren all data vid telefonbyte utan aktiv backup. Första prioritet när betalt Apple Developer-konto finns.

- **SwiftData VersionedSchema v1** — definiera nu innan ett fält tas bort eller byter typ. Kostar en timme, sparar en dag av felsökning vid framtida migration.

### Medium prioritet

- **HealthKit-behörighetsbegäran vid onboarding** — begärs idag per öppning av StrengthView/CardioView, vilket skapar onödig latens. Bör begäras en gång.

- **Hemskärmswidget** — streak + nästa program + senaste pass. Stärker daglig retention.

- **Progressionsförslag (automatisk)** — StrengthView vet om du tog PR förra gången; borde föreslå +2.5 kg / +1 rep. Skiljer loggbok från träningscoach.

- **Tillgänglighet: GifSheet** — WKWebView + base64 är osynlig för VoiceOver. Kräver `accessibilityLabel` på övningen.

- **Tillgänglighet: Effort-picker** — om custom: lägg till `accessibilityValue` + `accessibilityAdjustableAction`.

- **`#if DEBUG`-loggning i SwiftData saves** — `try? context.save()` loggar ingenting idag. Tre rader, noll påverkan på release.

### Lägre prioritet / idéer

- **Övningsbyte intra-pass** — byt övning mitt i ett pass utan att förstöra strukturen; spara original + ersättning.

- **Volymtrend i ExerciseChartSheet** — toggle 1RM / VOLYM (sets × reps × kg).

- **Rest-timer per övning** — default lagrad i ProgramExercise istället för global.

- **Påminnelser / streak-logik** — "du tränade senast för X dagar sedan" i TrainingView + frivillig push-notis.

- **Tester: HealthKitManager** — MET-beräkningar och kaloriformel är deterministisk logik som bör ha enhetstester.

- **Tester: PR-detektionslogiken** — e1RM-jämförelse mot historik bör testas isolerat.

- **Tester: CSV-export** — utdataformat testas inte; en komma i ett övningsnamn spräcker parsning.

- **Tester: PeriodSummarySheet-aggregationer** — volym, antal, tid är komplexa beräkningar utan unit tests.

- **Lokalisering: `sv_SE` hårdkodat** — datumformatering är avsiktligt hårdkodad till svenska för en svensk single-user-app. Inget att åtgärda om inte appen någonsin ska stödja fler marknader.

- **Lokalisering: övningsnamn** — alla på engelska, odokumenterat val; bör stå i CLAUDE.md.
