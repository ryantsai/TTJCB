# Level map and persistence

The four existing stages are independently selectable levels, each containing
four encounters. Level 1 starts unlocked. A level is complete only when its final
boss encounter has no enemies or queued reinforcements and at least one Titan
is alive. A completion unlocks the next level; replaying earlier levels never
reduces progress. Losing or leaving a level does not mark it complete.

## Save record and Rive bindings

`web/progress-storage.mjs` stores a versioned JSON record in localStorage:

```json
{"version":1,"cleared":2}
```

The key is `ttgo.campaign.progress.v1`. `cleared` is an integer from 0 through 4;
malformed, out-of-range or unsupported-version records restore as a fresh campaign.
A contiguous completion count is sufficient because levels unlock in order.
Character choice, scores and mid-level combat state are not part of this save.

The `Window` view model exposes:

| Property | Purpose |
|---|---|
| `completedLevels` | Completed prefix of the four-level route |
| `progressReady` | Host hydration has finished, including unavailable-storage fallback |
| `progressRevision` | Incremented only after a local completion or confirmed reset |
| `progressStatus` | `session`, `saved` or `unavailable`, displayed on the map |
| `browserGamepads` | Up to four standard controller snapshots for the shared input handler |

The browser host hydrates before playback and observes revision changes through
Rive's [documented web data-binding API](https://rive.app/docs/runtimes/web/data-binding).
The Luau bridge reads external updates before simulation, then publishes local
changes afterward. Initial defaults and save restoration do not trigger writes.
The adapter also flushes a pending revision on `pagehide` and retains its
observers when a page enters the browser's back/forward cache.

Reset is a visible map action with a cancellable confirmation, defaulting to
Keep Progress. Confirming removes this key alone and returns selection to level 1.
Other tabs receive storage updates. For normal completions the adapter preserves
the higher saved count if another tab has already advanced farther.

Storage failures leave the game playable for the session and change the map's
save status; they do not crash the game or claim a persistent save. The native
preview does not supply localStorage, so its progress remains session-only.

## Build and verification

The CLI's local `rive docs publishing` explains that unsigned scripts are
rejected by web runtimes. `npm run build` in `web/` runs
`rive . --publish=local` from the project root to obtain a signed file, then
bundles the host. This requires `rive login`. It does not publish a public page.
Continue to use the native preview for authoring, as specified in `AGENTS.md`.

```bash
rive . --verify
rive inspect . --summary
rive . --test
rive . --screenshot=build/level-map-new.png --key=space --advance=1 --key=escape --advance=1
rive . --screenshot=build/level-map-saved-tc.png --data=completedLevels=2 --data=progressReady=true --data=progressStatus=saved --key=tab --key=space --advance=1 --key=escape --advance=1
rive . --screenshot=build/level-map-reset.png --data=completedLevels=4 --data=progressReady=true --data=progressStatus=saved --key=space --advance=1 --key=escape --advance=1 --key=r --advance=1
cd web
npm test
npm run build:host
```

Native regression tests drive the game's actual keyboard, pointer, controller
and advance callbacks. They cover all four level launches/completions, locked
access, boss reinforcements, defeat, replay, reset/cancel, pointer scaling,
hydration, cross-tab restore and browser-controller disconnect. JavaScript tests
exercise the persistence adapter across new host instances, failed storage,
malformed records, cross-tab events and page-exit flushing. A host-only bundle
checks JavaScript packaging but is not a playable browser build or a browser
playtest; final browser gameplay requires the signed release.
