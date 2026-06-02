# Exercis Backlog

Två kategorier: **Rubens beslut** (explicit överenskommet) och **Claudes rekommendationer** (förslag att diskutera).
Uppdateras löpande under sessioner och vid apprevision.

---

## Rubens beslut

- [ ] **CSV-export** under Inställningar → ny sektion "Data" → "Exportera träningsdata" → iOS share sheet med `styrka.csv` och `kondition.csv`
- [ ] **Fixa buggar B–E** från revision 2026-06-02 (se nedan)
- [ ] **CHANGELOG.md** — dokumentera versionshistorik från v0.1.0 (ursprungligt program) och v0.2.0 (programs + onboarding + TabView)

---

## Claudes rekommendationer

### 🔴 Hög prioritet (svåra att lägga till senare)

- [ ] **CardioType.displayName som property på modellen** — visningsnamnen finns bara som privat metod i OnboardingView, orsakar aktiv bugg i CardioView (visar "cycling_stationary" etc.) och leder till duplication i varje ny vy
- [ ] **Prefill per program, inte senaste session** — `buildForms` tar `sessions.first` oavsett program; med 7 program märks detta direkt. `programId` finns redan på `WorkoutSession`
- [ ] **selectedCardioTypes från onboarding används inte** — sparas i AppStorage men läses aldrig av CardioView; onboarding-steg 2 är meningslöst just nu
- [ ] **Enhetssystem: implementera eller ta bort** — `weightUnit`/`distanceUnit` finns i Settings men ignoreras av formulär, historik, charts och HealthKit. Varje ny vy som byggs utan enhetsmedvetenhet gör det dyrare att fixa

### 🟡 Snart

- [ ] **ProfileView INSTÄLLNINGAR-länk fungerar inte** — `NavigationLink(value: "settings")` saknar `navigationDestination`, gör ingenting
- [ ] **ProgramCard hardkodar "3 SET"** — ignorerar `ProgramExercise.setCount`
- [ ] **PhotosPicker i ProfileView saknar accessibilityLabel** — VoiceOver läser ingenting på avatarknappen

### 🟢 Nästa revision

- [ ] **LockView placeholder-hack** — `Color.clear.frame(height: 44 + 60)` bör ersättas med riktig layout
- [ ] **UISelectionFeedbackGenerator skapas ny instans vid varje tryck** — bör återanvändas

---

## Parkerat

- **GIF-filer i git** — acceptabelt tills köpt databas ersätter dem; lägg till `Exercis/Resources/GIFs/` i `.gitignore` när bytet sker
- **`cardio_types.json` i Resources laddas inte av någon Swift-kod** — planerad men ej implementerad; ta upp när CardioType-systemet byggs om

---

*Senast uppdaterad: 2026-06-02*
