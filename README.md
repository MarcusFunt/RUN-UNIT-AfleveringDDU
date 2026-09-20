# RUN//UNIT

RUN//UNIT er et 2D-platformspil lavet i Godot 4 som DDU-afleveringsprojekt.

Spilleren styrer UNIT-07, en fabriksrobot der forlader fabrikken og bevæger sig gennem byen for at få Beacon 9 i gang igen. Spillet er bygget som en kort kampagne med en tutorial og tre efterfølgende baner.

**Spil i browseren:** https://marcusfunt.github.io/RUN-UNIT-AfleveringDDU/

## Baner og progression

1. **Calibration** – tutorial, hvor bevægelse, hop og crouch introduceres.
2. **Factory Escape** – UNIT-07 forlader fabrikken gennem den stoppede produktionslinje.
3. **Recovery** – spilleren krydser serviceområdet og finder den del, der skal bruges ved Beacon 9.
4. **Beacon 9** – den sidste rute frem mod beaconen.

Progressionen bliver vist direkte i HUD'en med distance, bedste distance, en progress-bar for den aktuelle bane og spillerens health. Checkpoints gemmer den seneste position på banen, så et restart ikke altid sender spilleren helt tilbage til starten.

## Designvalg i forhold til opgaven

- **Regler og styring:** Calibration-banen viser bevægelse, normalt hop, opladet spring-hop og crouch direkte i spilleverdenen med skilte og ikoner.
- **Synlig progression:** HUD'en viser health, distance, bedste distance og hvor langt spilleren er gennem den aktuelle bane.
- **Feedback:** Damage ændrer health-displayet med det samme, og bevægelse, hop, landing og skade har visuel/lydmæssig respons.
- **Konsistens:** De samme controls og HUD-elementer bruges gennem hele kampagnen, mens hazards bygger på fælles genbrugelige scripts.
- **Grafik:** Spillet bruger en samlet industriel sci-fi-stil. Robotten består af separate dele, så ben, hjul, krop og antenne kan reagere på spillerens bevægelse i stedet for kun at bruge en statisk sprite.

## Styring

- **A / D** eller **venstre / højre**: bevægelse
- **Space** eller **pil op**: hop
- **Hold hop nede og slip**: oplad fjederen til et højere hop
- **Pil ned**: crouch
- **R**: start igen fra seneste checkpoint
- **Esc**: pausemenu

Tasterne kan ændres under **System Settings -> Controls**.

## Centrale dele af koden

### Bevægelse og opladet hop

`scripts/player/player_motor.gd` står for spillerens fysik. Hop er ikke bare en fast impuls: mens hop-knappen holdes nede, opbygges en `charge_ratio`. Når knappen slippes, bliver den værdi omsat til en hoppehastighed mellem et minimums- og maksimumshop.

Motoren har også **coyote time** og input buffering, så et hop stadig kan registreres lige efter kanten af en platform eller kort før spilleren lander. Crouch ændrer både hastighed og collision-shapets højde, og spilleren kan ikke rejse sig, hvis der ikke er plads over robotten.

### Hazards

`scripts/hazards/hazard_area.gd` er basis for hazards. Den håndterer damage, lethal hits, knockback og hitstun.

`scripts/hazards/timed_hazard.gd` bygger ovenpå denne klasse og lader en hazard skifte mellem aktiv og inaktiv efter en cyklus. `cycle_seconds`, `active_seconds` og `phase_offset_seconds` kan ændres i Godot, så den samme kode kan genbruges til hazards med forskellige timings.

### HUD og feedback

`scripts/ui/hud.gd` opdaterer distance, bedste distance, baneprogression og health-celler. Det gør spillets progression og konsekvensen af damage synlig med det samme.

`scripts/player/robot_visual.gd` holder den visuelle animation adskilt fra selve spillerens collision og bevægelsesfysik. Scriptet styrer blandt andet hjulrotation, kropshældning, fjederben, landing compression og antennens bevægelse.

### Kampagne og checkpoints

`scripts/gameplay/game.gd` samler den aktive bane: spiller, world, HUD, hazards, checkpoints og level completion.

`scripts/gameplay/run_session.gd` holder styr på valgt bane, bedste distance og seneste checkpoint mellem scene-skift.

## Projektstruktur

| Mappe | Indhold |
| --- | --- |
| `scenes/` | Spilscener, level scenes, HUD, player og hazards |
| `scripts/player/` | Bevægelse, health, input, feedback og robot-animation |
| `scripts/gameplay/` | Kampagne, game state, score og session/checkpoints |
| `scripts/hazards/` | Genbrugelige hazard-klasser |
| `scripts/world/` | Banernes world-logik, exits og story/setpiece-funktioner |
| `scripts/ui/` | HUD, menuer og slutskærm |
| `assets/tiled/` | Tiled-levels og tilemap-data |
| `assets/` | Grafik, lyd og importerede assets |
| `addons/` | YATI og Maaack's Menus Template |

## Kør projektet lokalt

1. Brug **Godot 4.7.x**.
2. Åbn `project.godot`.
3. Tryk **Run Project**.

Projektet bruger GL Compatibility-rendereren, så det også kan eksporteres til web. Den færdige web-export ligger på repositoryets `gh-pages` branch.

Banerne er lavet som Tiled-maps og importeres gennem **YATI**. Menu-systemet er baseret på **Maaack's Menus Template** og er derefter tilpasset RUN//UNIT.

## Eksterne assets og addons

- **YATI 2.2.7**, Roland Helmerichs – MIT License (`addons/YATI/LICENSE`)
- **Maaack's Godot Menus Template**, Marek Belski og contributors – MIT License (`addons/maaacks_menus_template/LICENSE.txt`)
- **Kenney Sci-Fi Sounds / Impact Sounds** – CC0 (`assets/audio/kenney/LICENSE.txt`)
- **Industrial parallax artwork**, Luis Zuno / Ansimuz – CC0 (`assets/generated/licenses/industrial_parallax_CC0.txt`)
- **750 Effect and FX Pixel All**, BDragon1727 – gratis licens til ikke-kommerciel brug og ændringer (`assets/generated/licenses/fx_pack_provenance.txt`)
- **Battery/module-sprite** – den oprindelige pakke blev leveret uden en licensfil; provenance-noten er bevaret i `assets/generated/licenses/battery_provenance.txt`

De originale licens- og attribution-filer er bevaret i projektet sammen med de relevante assets/addons.

## Om dette repository

Dette er afleveringsrepositoryet til DDU-projektet. `main` er holdt til selve Godot-projektet og de filer, der skal bruges for at åbne og køre spillet. Udviklingsværktøjer, automatisering og tests fra arbejdsrepoet er derfor ikke en del af denne aflevering.
