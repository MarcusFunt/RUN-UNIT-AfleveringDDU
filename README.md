# RUN//UNIT

RUN//UNIT er et 2D-platformspil lavet i Godot 4 som DDU-projekt.

Man spiller UNIT-07, en fabriksrobot der forlader fabrikken og skal få Beacon 9 i gang igen. Spillet består af en kort tutorial og tre baner:

- Calibration
- Factory Escape
- Recovery
- Beacon 9

## Styring

- A / D eller venstre / højre: bevægelse
- Space eller pil op: hop
- Hold hop nede og slip: lad fjederen op til et højere hop
- Pil ned: crouch
- R: start igen fra seneste checkpoint
- Esc: pausemenu

Tasterne kan ændres under **System Settings -> Controls**.

## Kør projektet

Åbn `project.godot` i Godot 4.7.x og tryk Run Project.

Banerne ligger i `assets/tiled/levels` og bliver importeret med YATI. Menuerne bygger på Maaack's Menus Template.

De vigtigste egne scripts ligger i `scripts/player`, `scripts/gameplay`, `scripts/world` og `scripts/hazards`.
