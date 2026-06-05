# Exercis Roadmap

Allt planerat, beslutat och parkerat på ett ställe.
Uppdateras löpande under sessioner och vid apprevision.

---


## Planerade funktioner

1. **Onboarding-dubletter vid reinstall** — kontrollera `UserDefaults.standard.bool(forKey: "hasSeededPrograms")` i seedern; om sant, skippa seeding. Sätt nyckeln till `true` efter första seedning. Förhindrar att standardprogram dupliceras om UserDefaults rensas medan SwiftData-databasen finns kvar.

2. **Zombie Live Activity vid krasch** — i `StrengthView.onAppear`: iterera `Activity<ExercisActivityAttributes>.activities`, avsluta alla vars `contentState` inte matchar aktuell session. Förhindrar att en gammal Live Activity sitter kvar på Lock Screen i upp till 8 timmar efter krasch.

3. **CSV-export: share sheet** — byt nuvarande export mot `UIActivityViewController` (eller SwiftUI `ShareLink`) så att iOS standard share sheet visas. Ruben kan då spara till Filer, AirDrop, maila etc. Liten förändring i ProfileView/SettingsView.

4. **SwiftData-fel synliga** — byt `try? context.save()` mot `do/try/catch` med en `@State var saveError: Bool` och ett `.alert("Kunde inte spara", ...)` i berörda vyer (StrengthView, CardioView). Single-user OK med tyst fallback, men en synlig varning vid faktiskt fel förhindrar att data tyst försvinner.

5. **Lokalisering** — lägg till `sv.lproj/Localizable.strings` med alla synliga UI-strängar. SwiftUI `Text()` med strängliteraler plockar upp dem automatiskt; icke-SwiftUI-strängar kräver `String(localized:)`. Kartlägg strängar med `grep -r 'Text("' --include="*.swift"`. Engelska är basspråk — svenska-filen är det enda som behöver skapas.

---

## Beslutade designval (ej byggt än)

*(Inga kvarstående — alla designval är implementerade)*

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

*Senast uppdaterad: 2026-06-05*

