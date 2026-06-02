# Changelog

---

## v0.2.0 — 2026-06-01
*Den stora ombyggnaden. Appen gick från ett personligt träningsverktyg till en generaliserbar plattform för alla.*

**Nytt**
- Träningsprogram — sju inbyggda (Full Body, Överkropp, Underkropp, Push, Pull, Legs, Bodyweight) med egna färger ur en kuraterad 12-kulörig OKLCH-palett
- Onboarding — nyinstallation väljer program och konditionsformer innan första passet
- TabView ersätter HomeView — Styrka, Kondition och Historik som permanenta tabbar; inställningar nås via kugghjul i navigationsbaren
- Övningsbibliotek — 180+ övningar inlästa från JSON med muskler, utrustning, rörelsemönster och GIF-animation
- 26 konditionsformer (maskiner, utomhus, nordiska, vatten, övrigt, calisthenics) — användaren väljer sina i onboarding
- Profilvy med avatar, namn och livstidsstatistik
- Inställningar — HealthKit-toggles, Face ID-toggle

**Förbättringar**
- Styrkepassets accentfärg följer det aktiva programmets färg istället för en fast appfärg
- Prefill från senaste session per program (inte globalt senaste pass)
- Konditionstyper filtreras efter användarens val från onboarding

**Bakom kulisserna**
- `ExerciseDef` gick från hårdkodad struct till JSON-driven `ExerciseLibrary`
- Ny `WorkoutProgram`-modell med `ProgramExercise` junction-entitet
- CardioType-enum utökad med 22 nya typer; raw values migrerade från svenska till språkneutrala ID:n

---

## v0.1.0 — 2026-05-27
*Ursprungsversionen. Byggd exklusivt för Rubens eget träningsprogram.*

Appen hette ursprungligen "Träning" — döptes om till "Exercis" samma kväll.

- Fem fasta övningar: Barbell Back Squat, Incline Dumbbell Bench Press, Romanian Deadlift, Seated Cable Row, Lat Pulldown
- Tre konditionsformer: Crosstrainer, Cykel, Roddmaskin (Vandring tillkom kort efter)
- Logga styrkepass med vikt och reps per set — prefill från senaste passet
- Historik med månadsgrupper, expanderbara kort och progression per övning (e1RM via Epley-formeln)
- Ansträngningspoäng (1–10) per pass
- Apple Health-integration — sparar HKWorkout med kaloriberäkning via MET × kroppsvikt
- Face ID-lås vid app-start
- Periodsammanfattning — månads- och årsvy med stapeldiagram
- Draft-system — påbörjat pass återupptas automatiskt
- Sessionstidsredigering — justera start/slut i efterhand
- OKLCH-palett med 12 kulörer implementerad (2026-05-28)

---

*Underhålls av Claude Code. Formuleringar diskuteras med Ruben vid behov.*
