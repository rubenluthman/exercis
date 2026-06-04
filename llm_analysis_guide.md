# Guide: Extern LLM-analys av Exercis

## Syfte

Få en strategisk genomgång av kodbasen från ett utifrånperspektiv — inkonsekvenser, onödiga beroenden och risker inför nästa stora omskrivning (TabView-navigation, SwiftData-övningar).

## Filer

- `full_codebase.txt` — alla 27 Swift-filer concatenerade (~6 100 rader)
- `llm_analysis_prompt.md` — prompten att använda

## Rekommenderade modeller (i ordning)

1. **Gemini 2.5 Pro** (gemini.google.com) — 1M kontextfönster, gratis, bäst för stora kodbaser
2. **ChatGPT o3** (chatgpt.com) — stark på arkitekturanalys, 128k kontext (räcker)
3. **Claude.ai** — om du vill ha en second opinion, men du pratar redan med Claude Code

## Steg-för-steg

1. Öppna Gemini 2.5 Pro på gemini.google.com
2. Starta en ny chatt
3. Ladda upp `full_codebase.txt` som fil (klicka gem-ikonen / bifoga fil)
4. Klistra in innehållet från `llm_analysis_prompt.md` som ditt meddelande
5. Skicka — vänta på svar (kan ta 30–60 sekunder)
6. Ta med svaret tillbaka till FleetView för att agera på fynden

## Tips

- Be om uppföljning om något fynd är oklart — modellen har hela koden i kontexten
- Fråga gärna "vilka filer berörs av X?" om du vill gå djupare på ett specifikt fynd
- Kör **inte** analysen i Claude.ai Desktop — kontextfönstret räcker inte för hela filen
