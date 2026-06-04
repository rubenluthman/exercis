# Nästa session: Begränsningsfilter i ExercisePickerView

## Vad vi ska skissa på

Ett filtersystem för övningsväljaren (`ExercisePickerView`) — analogt med filter i en klädbutik (FÄRG, STORLEK, KÖN → MUSKELGRUPP, REDSKAP, RÖRELSETYP, BEGRÄNSNING).

Rubens idé: när man skapar/redigerar ett program och väljer övningar kan man filtrera listan med chips/taggar. Multi-select. Listan i `ExercisePickerView` har idag fuzzy search (Fuse.swift) men inga filter.

## Filterkategorier (utkast)

- **Muskelgrupp** — BRÖST · RYGG · AXLAR · BEN · ARMAR · CORE
- **Specifik muskel** — quads, hamstrings, lats, pecs etc.
- **Redskap** — SKIVSTÅNG · HANTEL · KABEL · MASKIN · KROPPSVIKT
- **Rörelsetyp** — TRYCK · DRAG · GÅNG (hinge) · SQUAT · ISOLERING
- **Begränsningar** — persistent, global (inte per program) — knä, axel, rygg, handled etc.

## Öppna designfrågor (inte beslutade ännu)

1. **Varning eller dölja?** Ruben har inte bestämt — jag lutar mot varningsikon (du ser övningen men vet att den är flaggad), inte dölja.
2. **Hur definieras en begränsning?** Lista av kroppsdelar (knä, axel...) eller manuell taggning av enskilda övningar?
3. **Var sätts begränsningar?** Troligen i SettingsView.

## Teknisk kontext

- `ExerciseDef` i `ExerciseLibrary.swift` — statisk struct per övning. Behöver utökas med taggar/metadata (muskelgrupp, redskap, rörelsetyp, berörda leder).
- 186 övningar definierade. Taggning av alla = manuellt arbete.
- `ExercisePickerView` har idag fuzzy search mot `name` + `aliases`. Filter läggs ovanpå det.
- Begränsningar behöver lagras (AppStorage eller SwiftData). SwiftData verkar överdrivet — AppStorage med en Set<String> räcker troligen.

## Vad sessionen ska resultera i

1. Beslut på de tre öppna frågorna ovan
2. Datamodell för taggar på ExerciseDef
3. UI-skiss (beskriven i text, inte kod) för filterpanelen i ExercisePickerView
4. Plan för taggning av övningsbiblioteket

Börja med att läsa `ExerciseLibrary.swift` och `ExercisePickerView.swift` för att förstå nuläget.
