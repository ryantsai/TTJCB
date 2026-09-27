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
| Primary special (30 energy) | B / RB | L | `/` or numpad 3 |
| Secondary special (40 energy) | Y | I | `;` |
| Ultimate (100 energy / full meter) | RT | U | apostrophe (`'`) |
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

| Titan | Secondary — Y | Ultimate — RT |
|---|---|---|
| Robin | Staff Cyclone: spins his staff to knock back nearby enemies on both sides | Birdarang Storm: three waves of returning birdarangs across three lanes |
| Cyborg | Seismic Slam: crouches and punches the street, launching nearby enemies | Mega Sonic Cannon: a wide beam with five damage pulses |
| Starfire | Comet Rush: a glowing forward dash punch | Star Nova: a charged explosion around her |
| Raven | Shadow Grasp: pulls enemies in front of her closer | Soul Self: projects a giant raven spirit forward |
| Beast Boy | Gorilla Smash: transforms into a gorilla for an area slam | T-Rex Rampage: becomes a charging dinosaur |

Specials and ultimates can cancel a grounded normal attack. Tap the button once per cast;
holding RT does not repeat the ultimate. Energy fills over time and whenever you land or
take a hit. The HUD shows the cost and readiness of B, Y and RT; the full meter turns gold.
Pizza heals.
Clear five waves of Slade Bots and Heavy Bots across Jump City, then beat
Cinderblock.

## Files

| File | What it holds |
|---|---|
| `main.luau` | Rive layout entry point |
| `game.luau` | the game: input, modes, combat, AI, waves, camera, HUD |
| `movement_test.luau` | regression tests using the game's input and update callbacks |
| `heroes.luau` | the five Titans, drawn in the Teen Titans Go! style |
| `armature.luau` | side-view arm reach and consistent elbow bend for gameplay |
| `profiles.luau` | three-quarter gameplay faces and trailing hair; opponent-facing gaze in either direction |
| `art.luau` | villains, Cinderblock, effects and the Jump City stage |
| `pose.luau` | the animation pose shared by the drawing modules |
| `powers.luau` | secondary/ultimate names, costs, timing, reach and damage |
| `power_art.luau` | ability effects, gorilla and T-Rex transformations |
| `attacks.luau` | per-Titan normal combos shared by combat and animation |
| `motion.luau` | anticipation, impact and recovery timing shared by the game and pose review |
| `gfx.luau` | drawing primitives: path pool, shapes, clipping, text |
| `font.luau` | the stroke font, since Rive scripts have no text API |

To test a later wave, set `START_CHECKPOINT` near the top of `game.luau`.

### Movement feel

Tap gamepad **A** (keyboard **K / Space**) for a short hop, or hold it for a higher jump. A jump pressed just before touching down is buffered. Press **X** (**J**) in the air for the hero's aerial strike. Takeoff has a brief crouch; rising, apex, falling and landing poses are distinct. Landing recovery is visual and does not lock movement or attacks. Robin and Beast Boy use springy strides, Cyborg has a heavier gait, and Starfire and Raven glide. Normal attacks retain their character-specific combos with two-handed staff grips, anticipation and recovery.
