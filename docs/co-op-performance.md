# Co-op impact responsiveness

The previous `damage()` path set a global 45 ms hit pause, or 80 ms for a
knockdown. `updatePlay()` returned early during that pause, stopping every
player, enemy, projectile and physics update. The outer update still cleared
one-frame input edges. Frequent co-op hits therefore interrupted unrelated
players and could discard their attack/jump taps even with a fast renderer.

Impacts now hold only the victim and a contacting melee attacker: 25 ms for
light hits, 50 ms for knockdowns. Projectile owners and unrelated actors keep
updating. Each actor gets a time slice before combat so update ordering does
not determine when a hold begins. Combat and direction presses are buffered
through the hold and consumed once on resume. Hit sparks, outlines, shake and
the full character artwork remain present.

## Native Rive rendering

`gfx.luau` now combines each text run with the documented `Path:add(path,
transform)` API and reuses the resulting immutable geometry. Ordinary English
text takes two path submissions per run instead of two per letter. Mixed
ASCII/Noto Sans TC takes at most four submissions, preserving the separate
stroke and fill styles. The 256-entry cache bounds retained score strings;
eviction releases references without resetting a path already submitted to
the renderer. Single-glyph decoding remains cached too.

API reference used: `rive docs luau/api/path`, especially the prohibition on
mutating a path after drawing it in the same frame.

## Measurement, 2026-09-27

Rive CLI 1.2.0, Apple M5, macOS 27.0, 1280 × 720, default native headless
renderer. Four distinct Titans, twelve villains, sixteen impact effects, two
speech bubbles and all four HUDs. A deterministic animation clock keeps the
draw workload identical across versions, independently of changed combat
timing. Three alternating baseline/candidate runs per locale, 1,200 frames
per run, without concurrent capture/build jobs. Baseline is the source
snapshot immediately before this optimization, including the new dialogue.

| Native render statistic (median of three runs) | Before | After |
| --- | ---: | ---: |
| English p50 | 1.075 ms | 0.938 ms |
| Taiwan Chinese p50 | 1.145 ms | 1.056 ms |
| English mean | 1.151 ms | 0.952 ms |
| Taiwan Chinese mean | 1.150 ms | 1.068 ms |

Typical render time dropped about 13% in English and 8% in Chinese. These
are the CLI's headless render timings, not end-to-end display latency, GPU
presentation measurements or a guarantee on other hardware. One candidate
run had a 9.377 ms maximum outlier; these runs do not establish an improvement
in worst-case latency. The eliminated whole-game pauses were a separate,
deterministic 45–80 ms gameplay interruption on each hit.

Local raw evidence is in `build/coop-{baseline,candidate}-{en,tw}/paired-*.log`
and `build/coop-perf-results.json`. These ignored build outputs are not required
to run the game.

Reproduce the current native workload with:

```sh
python3 tools/bench_coop.py --name coop-perf-en --locale en
python3 tools/bench_coop.py --name coop-perf-tw --locale zh-TW
rive build/coop-perf-tw --screenshot=build/coop-perf-tw.png --advance=1
```

The fixture deliberately bypasses gameplay updates to isolate rendering.
Behavior is covered separately by the real-callback tests in `coop_test.luau`:
uninterrupted teammate movement/attacks, airborne physics, projectile travel,
buffered combos/specials, remote hits, and simultaneous four-player attacks.
`render_test.luau` checks immutable path reuse, mixed-language batching and
cache eviction. All 68 project tests pass, with zero verify/inspect problems.

Native before/after screenshots were visually checked in both languages.
The character geometry is unchanged; fewer than 0.1% of frame pixels differ
after batching text (small edge rasterization differences).
