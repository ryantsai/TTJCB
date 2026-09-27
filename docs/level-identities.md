# Level identities, boss patterns and localization

Research reviewed September 27, 2026. All eight bosses have a distinct signature
and bilingual remarks. Levels 2–8 also each have a different hazard and collectible
support device. This is a
fan-game arrangement of cartoon ideas. The pickup names, timed effects, numerical
balance and attack patterns below are original game adaptations, not claims that
those exact items or fights appeared in an episode.

| Level | Trap and counterplay | Collectible equipment | Boss signature |
|---|---|---|---|
| 1 — Jump City | Introductory street encounters | Existing pizza health pickups | Cinderblock sends four concrete fissure segments along his lane toward the player's side, starting after a 1.2-second warning; jump or sidestep; the whole sequence can hit each player only once |
| 2 — Iron Docks | Moving cargo truck; leave its marked lane | Salvage Gauntlet: 12 seconds of 50% stronger normal, dash and aerial strikes | Mammoth locks a lane, rushes across it, then smashes the endpoint; sidestep the rush or jump the final impact |
| 3 — Hex Foundry | Pink reactor exhaust; leave the vent area | Hex Capacitor: restores 60 energy immediately | Jinx marks three ground hexes which erupt in sequence; move away from each mark |
| 4 — Slade HQ | Low security laser; jump or change lanes | Hacked Drone: 12 seconds of automatic robot cover fire | Slade performs two crossing attack passes in different lanes with a pause between them |
| 5 — Mad Mod School | Alternating checkerboard floor holes; use intact tiles or jump | Hypno Jammer: disables stage traps for the team for 12 seconds and protects its holder from hypnosis | Mad Mod projects two hypnoscreen zones; the central gap stays safe; a hit slows movement for two seconds |
| 6 — H.I.V.E. Academy | Sonic rings with a safe inner area; jump or leave the ring | Sonic Amplifier: ten seconds of periodic short-range damage pulses | Brother Blood drains 25 energy on a hit in his ring; the inner area and outside edge are safe |
| 7 — Tamaran | A tall orbital beam; leave its landing marker | Tamaranean Shield: absorbs three hits, lasting up to 12 seconds | Blackfire uses a jewel-enhanced sequence of four strikes across alternating lanes |
| 8 — Trigon’s Earth | Hellfire fissure eruptions; move away | Azarath Ward: ten seconds of gradual healing and nearby enemy-projectile removal | Trigon adds four parallel eye-beam lanes with narrow safe gaps to his existing slam/fire-volley cycle |

Equipment appears in every encounter of levels 2–8 in addition to existing pizza.
Walk over it to collect it. Its name and effect appear next to the pickup; the
player HUD shows the equipped device and remaining time (and shield charges).
Timed equipment replaces the previous equipped device; the capacitor is an
instant recharge. Effects pause with the game and respawning creates an
unequipped hero. Boss patterns lock their target positions before striking,
show warnings, hit once per phase, and stop when the boss is interrupted or
killed. Boss speech shares the two-bubble limit with the Titans.

## Research and adaptation

- **Cinderblock / Jump City:** [“Divide and Conquer”](https://teentitans.fandom.com/wiki/Divide_and_Conquer/Transcript)
  describes his ground stomp opening a long fissure and scattering debris.
  [Cinderblock's profile](https://teentitans.fandom.com/wiki/Cinderblock) describes
  his concrete body and normal lack of spoken dialogue. The travelling crack,
  staged warning and jumpable height adapt that attack for the introductory boss.
  His 12 remarks are original localized roars and concrete sound captions across
  entrance, signature, low-health and defeat events, not invented episode quotes.
- **Mammoth / the industrial docks:** [Mammoth's profile](https://teentitans.fandom.com/wiki/Mammoth)
  describes his exceptional strength; [“Final Exam”](https://teentitans.fandom.com/wiki/Final_Exam/Transcript)
  shows his heavy-object attacks and the H.I.V.E. team's coordinated fighting.
  Cargo handling, the salvage fist and the locked-lane rush are level-specific
  interpretations. The short Mammoth quote “Your worst nightmare!” and Jinx's
  “Attack Pattern Alpha!” are retained from this transcript.
- **Jinx / the foundry:** [Jinx's profile](https://teentitans.fandom.com/wiki/Jinx)
  describes bad-luck manipulation and pink energy disrupting structures.
  This motivates chained floor failures and unstable reactor equipment.
- **Slade / the headquarters:** [“Apprentice, Part 1”](https://teentitans.fandom.com/wiki/Apprentice_-_Part_1/Transcript)
  establishes his calculated traps, technology and effort to recruit Robin.
  The hacked security drone and two-pass feint are authored counterplay. The
  short excerpt “I've chosen you” supplies one entrance line.
- **Mad Mod / the school:** [Hypnoscreens](https://teentitans.fandom.com/wiki/Hypnoscreens)
  and [“Mad Mod”](https://teentitans.fandom.com/wiki/Mad_Mod_%28episode%29/Transcript)
  support hypnotic displays, illusion architecture, robotic enforcers and his
  schoolmaster manner. “Off to class!” is a short retained quote. The jammer,
  checkerboard safe tiles and temporary slow are game mechanics inspired by them.
- **Brother Blood / the academy:** [Blood's profile](https://teentitans.fandom.com/wiki/Brother_Blood)
  describes mind control and telekinetic protection; [“Wavelength”](https://teentitans.fandom.com/wiki/Wavelength)
  connects H.I.V.E. technology with stolen sonic-cannon plans. His controlling
  teacher voice, draining ring and recoverable sonic amplifier follow those themes.
- **Blackfire / Tamaran:** [“Betrothed”](https://teentitans.fandom.com/wiki/Betrothed/Transcript)
  places Blackfire on Tamaran's throne with the power-enhancing Jewel of Charta.
  Her original lines emphasize superiority, her sister and the jewel. Orbital
  targeting and the three-hit shield are game adaptations of royal alien technology.
- **Trigon / ruined Earth:** [“The End, Part 3”](https://teentitans.fandom.com/wiki/The_End_-_Part_3/Transcript)
  supports his apocalyptic scale, forceful attacks and Raven's opposition.
  The short quote “Your world is ended!” is retained. His beam geometry and the
  defensive ward are original mechanics inspired by that confrontation.

These sources are community-maintained episode transcripts and profiles, not
studio scripts. Apart from the short excerpts explicitly identified above, the
96 boss entries are original game dialogue, sound captions or concise adaptations. All Chinese
lines are authored Taiwan translations, not verified quotations from the dub.

## Localization and verification

H.I.V.E. consistently displays as **海夫**, including **海夫學院** on the background
sign, **海夫貨運** on containers, truck markings, cadet names and the level map.
Boss warnings, remarks, equipment names/instructions, browser loading/error
messages, fullscreen controls, document title and accessible labels all follow
the selected language. Physical key/controller legends and language autonyms
remain recognizable labels.

The font generator includes hero and boss dialogue; `%` now exists in the native
stroke font. Native UI literal checks reject unlocalized draw strings. Dynamic
campaign/tutorial labels, equipment, warnings and remark pairs are covered by
Rive tests, including Chinese glyph coverage and three-line bubble limits.

```bash
python3 tools/check_localization.py
rive . --verify
rive inspect . --summary
rive . --test
npm test --prefix web
python3 tools/capture_campaign.py --stage 6 --signature --equipment --locale zh-TW
python3 tools/capture_campaign.py --stage 8 --signature --pattern-time 1.7 --locale en
python3 tools/capture_campaign.py --stage 1 --signature --pattern-time 1.5 --locale zh-TW
```
