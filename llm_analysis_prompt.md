# Prompt: Strategisk kodgranskning av Exercis

Du har fått en iOS-app skriven i SwiftUI + SwiftData. Appen heter Exercis och är en privat träningslogg för en användare — styrketräning och kondition. Den är byggd organiskt av en ensam utvecklare och har aldrig granskats av en extern part.

## Din uppgift

Gör en **strategisk arkitekturgenomgång**. Fokus är inte att hitta stavfel eller stilproblem — fokus är att hitta:

1. **Inkonsekvenser** — platser där samma sak görs på olika sätt i olika filer, eller där namngivning/struktur inte följer något tydligt mönster
2. **Onödiga beroenden** — kod som är hårdare kopplad än den behöver vara, eller där state hanteras på ett sätt som gör framtida ändringar svårare
3. **Risker inför nästa omskrivning** — appen ska snart få en stor strukturell förändring: nuvarande TabView (4 tabbar) ska omstruktureras till 3 tabbar där Inställningar och Profil flyttar till ett kugghjul i navigationsbaren, och `ExerciseDef` ska bli en SwiftData-modell istället för en statisk struct. Vad i nuvarande kod riskerar att skapa problem när det sker?
4. **Datamodell-problem** — UserDefaults-nycklar som är för löst definierade, SwiftData-relationer som är felaktigt modellerade, state som lever på fel ställe

## Format

- **Max 10 fynd** — prioritera det viktigaste, skippa trivialt
- Varje fynd: rubrik, berörda filer, problemet i 2–3 meningar, konkret rekommendation
- Avsluta med en **sammanfattande riskbedömning** (ett stycke): hur välmående är kodbasen inför den kommande omskrivningen?

## Kontext du behöver känna till

- Deployment target: iOS 17
- En användare, ingen backend, ingen CloudKit-sync
- Jost är enda typsnittet, definierat i Theme.swift
- UserDefaults används för drafts, inställningar och migrationsversion
- Övningar laddas från exercises_def.json via ExerciseLibrary singleton
- GIF-filer bäddas in som base64 och visas i WKWebView
- Inga enhetstester finns

Koden följer bifogad fil.
