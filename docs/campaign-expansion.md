# Eight-stage campaign

This is an original fan-game arrangement inspired by the 2003 Teen Titans cartoon,
not a recreation of a particular episode. Enemy combinations, hazards and attacks
are authored for this game.

| Stage | Distinct encounter mechanic | New opponents / boss |
|---|---|---|
| 1 — Jump City | Introductory combat without environmental damage | Slade robots / Cinderblock |
| 2 — Iron Docks | H.I.V.E. cargo truck crosses a warned lane | Mammoth |
| 3 — Hex Foundry | Localized reactor vent eruptions require moving away | Jinx |
| 4 — Slade HQ | Low security lasers can be jumped or sidestepped | Slade |
| 5 — Mad Mod School | False-floor traps in a checkerboard illusion school | Mod Robots / Mad Mod |
| 6 — H.I.V.E. Academy | Broad sonic fields can be jumped | H.I.V.E. Cadets / Brother Blood |
| 7 — Tamaran | Orbital strikes require leaving a marked landing area | Gordanians / Blackfire |
| 8 — Trigon’s Earth | Hellfire eruptions across the ruined city | Fire Demons / Trigon |

See [level identities](level-identities.md) for the equipment, boss signatures,
boss dialogue sources and complete localization pass.

## Cartoon references

- Mad Mod's illusion school and robots draw from [Mad Mod](https://teentitans.fandom.com/wiki/Mad_Mod).
- Brother Blood's academy draws from the cartoon's [third season](https://teentitans.fandom.com/wiki/Teen_Titans%3A_Season_Three), particularly “Deception” and its H.I.V.E. story arc.
- Tamaran and Blackfire's throne draw from [“Betrothed”](https://teentitans.fandom.com/wiki/Betrothed). The Gordanian combat units are a gameplay remix of the cartoon's alien enemies, not a claim that these exact encounters occur in that episode.
- The ruined city, giant Trigon and fire demons draw from [“The End”](https://teentitans.fandom.com/wiki/The_End_-_Part_3) and the [fire demons](https://teentitans.fandom.com/wiki/Fire_demons). DC's [Trigon profile](https://www.dc.com/characters/trigon) provides broader character context.

New Chinese stage and hazard descriptions are project-authored translations.

## Hazard rules

Every encounter restarts a nine-second cycle: two seconds safe, two seconds of
warning, two seconds active, then three seconds safe. Marked areas use the same
geometry as hit detection. Truck warnings span the lane; the actual truck's
moving body defines its hit area. Only players take environmental damage (18 HP). School floor holes alternate
with intact tiles; the academy sonic ring has a safe inner area.
Each player is hit at most once per activation. Jump height matters; moving out
of the marked area always avoids the hazard. Pausing freezes the encounter clock.

Trigon stands 450px tall and spans approximately 430px of the 1280×720 arena.
He anchors the right side with a reachable melee hitbox at his feet. He alternates
a 1.25-second warned ground slam and a warned three-lane fire volley. The slam
can be jumped or escaped at the far left edge. He resists stagger while alive;
below half health his recovery between attacks shortens. Defeat him and all his
reinforcements with a surviving Titan to complete the eighth stage.

## Validation and native captures

`rive . --test` covers all 32 encounter rosters and co-op scaling, sequential
unlocks through stage 8, hazard warning / safe lanes / jump height, once-per-cycle
damage, pause, Trigon melee vulnerability and his attack cycle. Browser tests
cover eight-stage persistence and compatibility with old four-stage saves.

```bash
python3 tools/capture_campaign.py --stage 2 --hazard 5
python3 tools/capture_campaign.py --stage 8 --wave 4
python3 tools/capture_campaign.py --stage 8 --map --locale zh-TW
```

These native-only captures copy source into ignored `build/campaign-*` directories
and inject an in-memory completed save. They do not change actual browser saves
or the production entry point.
