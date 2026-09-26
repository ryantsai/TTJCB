# Teen Titans: Jump City Brawl

An unofficial fan-made 2D belt-scrolling beat-'em-up for 1–4 players, built as a
Rive CLI project. The whole game is Luau scripts drawing vector art.

```bash
rive .            # play in the preview window (rebuilds on save)
rive . --verify   # type-check
rive . --test     # movement, facing, combat and projectile regressions
rive . --once     # write build/titans_brawl.riv
```

## Playing

Press **Start** (or A) on the title screen. On the select screen, every
controller or keyboard that presses Start joins, up to four players. Each player
picks a different Titan with left/right and readies up with A. Once everyone is
ready the game starts after 3 seconds, or right away if someone presses Start.
Players can also drop in mid-game by pressing Start.

| Action | Controller | Keyboard 1 | Keyboard 2 |
|---|---|---|---|
| Move | Left stick / D-pad | W A S D | Arrow keys |
| Attack (3-hit combo) | X | J | `,` or numpad 1 |
| Jump (attack in the air to jump-kick) | A | K or Space | `.` or numpad 2 |
| Special (uses 30 energy) | Y, B, RB or RT | L | `/` or numpad 3 |
| Join / pause / continue | Start | Enter | Right Shift or numpad Enter |
| Back (menus) / quit (while paused) | B / Back | Esc | Right Ctrl |

## The Titans

| Titan | Normal combo (X / J) | Special |
|---|---|---|
| Robin | Staff thrust → wide sweep → overhead staff | Birdarang: a boomerang that hits on the way out and on the way back |
| Cyborg | Body blow → uppercut → hammer fists | Sonic Cannon: a full-screen beam that hits several times |
| Starfire | Star palm → rising palm → double star burst | Starbolt Volley: three green energy bolts |
| Raven | Shadow lash → rising shadow → dark palm | Dark Burst: an area blast around her ("Azarath Metrion Zinthos!") |
| Beast Boy | Claw rake → back claw → twin claw pounce | Rhino Charge: turns into a rhino and plows through everyone |

Press attack again during a strike to queue the next hit. Normal combos use no energy.
Each Titan has different attack timing, reach, damage, and movement; the third hit knocks foes down.

Energy fills over time and whenever you land or take a hit. Pizza heals.
Clear five waves of Slade Bots and Heavy Bots across Jump City, then beat
Cinderblock.

## Files

| File | What it holds |
|---|---|
| `main.luau` | Rive layout entry point |
| `game.luau` | the game: input, modes, combat, AI, waves, camera, HUD |
| `movement_test.luau` | regression tests using the game's input and update callbacks |
| `heroes.luau` | the five Titans, drawn in the Teen Titans Go! style |
| `profiles.luau` | right-facing gameplay heads and trailing hair; mirrored when facing left |
| `art.luau` | villains, Cinderblock, effects and the Jump City stage |
| `pose.luau` | the animation pose shared by the drawing modules |
| `attacks.luau` | per-Titan normal combos shared by combat and animation |
| `motion.luau` | anticipation, impact and recovery timing shared by the game and pose review |
| `gfx.luau` | drawing primitives: path pool, shapes, clipping, text |
| `font.luau` | the stroke font, since Rive scripts have no text API |

To test a later wave, set `START_CHECKPOINT` near the top of `game.luau`.
