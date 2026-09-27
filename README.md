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

On macOS, the **green window button at the top-left** enters full screen.
Move the pointer to the top edge to reveal it again and leave full screen.
The native preview uses the standard OS title bar and window controls.
The browser build shows a custom top-left fullscreen button **only on Windows**
when the browser supports fullscreen. macOS uses its normal window controls,
with no extra button or reserved strip inside the game.

Press **Start** (or A) on the title screen. The first start in a session opens
a 26-second automatic tutorial: Robin performs real gameplay actions while
an Xbox-style controller and both players' keyboard keys animate on the right.
It covers movement, dash strikes, tap/held jumps, combos, aerial attacks,
all three powers, and joining/pausing/returning to the menu.

Skip with **Start / Enter / Esc / View** or the **Skip** button. Use **A / Space /
Right** or **Next** to advance, and **Left** or **<** to revisit a step. Replay
from **How to Play**, keyboard **H**, or controller **Y** on the main menu.
The tutorial follows the selected English or Taiwan Chinese language and does
not spend player resources or affect campaign progress.

After the tutorial, the **level map** shows the route through all four stages.
Open it directly with **Level Map** on the title screen or keyboard **M**.
Only Jump City is available at first. Clear all four waves, including the boss
and its reinforcements, to unlock the next stage. Completed stages remain
available for replay. Choose a node with the mouse, movement keys or controller,
then select **Play Level / Replay Level**, **A**, or **Enter**.

The map's upper-right **Reset Progress** button (keyboard **R**, controller **Y**)
opens a confirmation. **Keep Progress** is selected by default; confirming reset
clears every completion and leaves only level 1 available. **Esc / B / View**
cancels. Reset does not change the selected language.

On the select screen, every
controller or keyboard that presses Start joins, up to four players. Each player
picks a different Titan with left/right and readies up with A. Once everyone is
ready the game starts after 3 seconds, or right away if someone presses Start.
Players can also drop in mid-game by pressing Start.

| Action | Controller | Keyboard 1 | Keyboard 2 |
|---|---|---|---|
| Move | Left stick / D-pad | W A S D | Arrow keys |
| Dash | Double-tap a stick / D-pad direction | Double-tap W / A / S / D | Double-tap an arrow key |
| Dash attack | X during dash | J during dash | `,` or numpad 1 during dash |
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

Double-tap the same direction within 0.26 seconds to dash. Release between taps
(return the stick toward neutral); holding a direction walks normally. Dashes
work in all four directions and keep their direction for the burst. Attack during
the dash for a lunging knockdown strike that costs no energy.

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
Fight through **four stages and sixteen encounters**, with larger mixed waves and
reinforcements that scale up for co-op:

| Players | Regular enemy count | Regular enemy HP | Boss HP |
|---|---|---|---|
| 1 | 1x | 1x | 1x |
| 2 | 1.5x | 1.25x | 1.6x |
| 3 | 2x | 1.5x | 2.2x |
| 4 | 2.5x | 1.75x | 2.8x |

Counts and maximum HP round to the nearest whole number. Boss encounters keep one
boss and scale the accompanying regular enemies. Joining mid-wave adds staggered
reinforcements and adjusts living enemies' HP while preserving their remaining
health percentage. Players waiting to respawn still count; players out of lives
do not. Existing reinforcements remain for that wave, and continuing does not add
them a second time. The next wave uses the current active player count.

Each stage ends with a boss. Clearing the first three returns to the map and
selects the newly available stage; defeating Slade shows the victory screen.
Press Start to return to the completed map. Every level attempt starts with
full health, three lives and 60 energy. Joined players stay together between levels.

| Stage | Setting | Boss |
|---|---|---|
| Jump City | Sunset streets | Cinderblock — punches, charges, ground slams |
| Iron Docks | Moonlit harbor, cranes and cargo | Mammoth — aggressive charges and heavy slams |
| Hex Foundry | H.I.V.E. reactors and industrial machinery | Jinx — three-lane hex volleys |
| Slade HQ | Rooftops above the city | Slade — blade volleys, rushes and close combat |

Slade Bots and Heavy Bots are joined by **Razor Bots** (fast rush attacks),
**Blaster Bots** (telegraphed ranged shots), **Guard Bots** (frontal shields;
flank them or use knockdowns), and **Shock Bots** (jump over their electric pulse).
Watch the attack warnings, change lanes to dodge projectiles, and jump over the
marked slam areas. The HUD tracks the stage, local wave, and enemies remaining.

## Browser saves and release build

Browser play uses `web/`, a production host for the signed Rive game. It saves
completed levels automatically to `localStorage` under
`ttgo.campaign.progress.v1`. The save belongs to this browser and site origin,
is shared by local co-op players, and survives a page reload or browser restart.
Replaying earlier levels preserves later unlocks. Other open tabs synchronize
completion and reset changes. Reset removes only this game's save.

The native `rive .` preview has no browser storage and keeps progress only for
the current run. The map says **Session Progress** there. In the browser it says
**Saved in This Browser**, or **Saving Unavailable — Session Only** if storage is
blocked. Private browsing follows the browser's own storage lifetime.

```bash
rive login                  # one-time authentication for Rive script signing
cd web
npm ci
npm test                    # persistence, reload, reset and unavailable-storage cases
npm run build               # signs the game and bundles web/dist for hosting
```

Serve `web/dist/` from a stable HTTP(S) origin. The host includes the WebGL2
runtime, WASM, bundled Noto Sans TC font, browser controller input and a Windows-only
top-left fullscreen button. This build command creates local release files; it does not
publish a website or push the project to the Rive editor. Rive's server compiles
and signs the scripts, so signing requires a logged-in session and network access.
If authentication fails, the build stops before copying a game file into the host.

The published site is [ryantsai.github.io/TTJCB](https://ryantsai.github.io/TTJCB/).
To publish a new version, run `python3 tools/publish_github_pages.py` from the
project root. It signs the current Rive sources, builds the host and pushes the
release files to the `gh-pages` branch. The GitHub Pages source is that branch's
root. The source checkout stays on `main`; only the compiled site is on
`gh-pages`. This script requires the local Rive and GitHub CLI logins.

Use **`rive .` for authoring previews**. Unsigned local builds cannot play in web
runtimes. `npm run build:host` checks the host bundle without signing and omits
the playable `.riv` file. See [the progress implementation notes](docs/level-progress.md)
for the save contract and validation commands.

## Files

English and **繁體中文（台灣）** are available from the main menu's top-right
selector. Click a language, press **Tab**, or press controller **LB**. The choice
stays active throughout the current session. Chinese uses the **Noto Sans TC**
Google Fonts web font, bundled for offline Rive rendering. Taiwan TV terminology,
source research and font regeneration details are in
[docs/localization-zh-TW.md](docs/localization-zh-TW.md).

| File | What it holds |
|---|---|
| `scene.rml` | responsive game container, progress bindings and script registration |
| `main.luau` | Rive layout entry point |
| `tutorial.luau` | timed control demonstrations, animated controller/keycaps and tutorial navigation |
| `tutorial_test.luau` | real Robin actions, input synchronization, skip/replay, co-op joining and localization |
| `level_map.luau` | four-stage route, unlock states, stage details and reset confirmation |
| `progress.luau` | sequential unlock rules and the Rive view-model save bridge |
| `progress_test.luau` | stage selection, completion, replay, reset, hydration and browser controller regressions |
| `browser_input.luau` | standard browser gamepad snapshots routed to the native input handler |
| `web/` | signed browser release host, localStorage adapter, save tests and build script |
| `campaign.luau` | enemy stats, stage identities, and all sixteen encounter rosters |
| `campaign_test.luau` | campaign progression, new enemy behavior and co-op regressions |
| `game.luau` | the game: input, modes, combat, AI, waves, camera, HUD |
| `movement_test.luau` | regression tests using the game's input and update callbacks |
| `coop_test.luau` | independent co-op timing and input buffering during impacts |
| `render_test.luau` | immutable text geometry reuse and bounded cache eviction |
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
| `localization.luau` | Taiwan translations and named text templates |
| `localization_test.luau` | language input, glyph coverage and translated campaign regressions |
| `remarks_catalog.luau` | researched character voices and paired English/Taiwan dialogue |
| `remarks.luau` | random variants, repetition control and speech priorities |
| `speech.luau` | readable comic bubbles, wrapping and co-op placement |
| `remarks_test.luau` | contextual dialogue, cooldown, localization and layout checks |
| `tc_glyphs.luau` | generated Noto Sans TC vector glyphs from the bundled WOFF2 |
| `tools/bench_coop.py` | repeatable native Rive stress scene with four heroes and twelve enemies |

To inspect a later map state, run
`rive . --data=completedLevels=2 --data=progressReady=true --key=m`.
This injects a temporary save into the native preview; it does not write browser storage.

Titans react in speech bubbles when enemies appear, they take damage, health
gets low, they use each power, pick up pizza, clear a wave or get knocked out.
Three variants per situation keep their voices varied. Cooldowns and a two-speaker
limit keep co-op readable. Dialogue follows the selected language and includes
short cartoon catchphrases plus original lines in each character's voice; see
[the dialogue research](docs/character-remarks.md).

Hits briefly hold only the affected actors (25 ms for light hits, 50 ms for
knockdowns). Teammates, projectiles, camera and wave logic continue normally,
and combat taps are buffered through the local hold. Ranged hits never hold
the projectile's owner. Text is batched into immutable native Rive paths with
a bounded cache, retaining Noto Sans TC and the comic outlines. Run
`python3 tools/bench_coop.py --locale zh-TW` for the native rendering workload;
see [the performance notes](docs/co-op-performance.md) for measurements and scope.

### Movement feel

Tap gamepad **A** (keyboard **K / Space**) for a short hop, or hold it for a higher jump. A jump pressed just before touching down is buffered. Press **X** (**J**) in the air for the hero's aerial strike. Takeoff has a brief crouch; rising, apex, falling and landing poses are distinct. Landing recovery is visual and does not lock movement or attacks. Robin and Beast Boy use springy strides, Cyborg has a heavier gait, and Starfire and Raven glide. Normal attacks retain their character-specific combos with two-handed staff grips, anticipation and recovery.

Movement uses broad, tapered limbs, a forward-leading chest, and a steady head. Human leg proportions keep the supporting leg extended, with a low foot pickup and a modest knee bend during the passing step. Shoes pivot at the ankle and keep a flat sole while planted; step timing follows travel distance. Takeoff and landing compress the torso; capes and hair sweep behind the motion. Starfire flies with one knee raised and one leg trailing, while Raven opens her cloak into a flowing silhouette. Dashes leave two brief pose echoes, and normal attacks have larger body follow-through and character-colored swing arcs.
