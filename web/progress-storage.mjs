export const STORAGE_KEY = 'ttgo.campaign.progress.v1';

export function parseProgress(raw) {
  try {
    const value = JSON.parse(raw);
    if (value?.version === 1 && Number.isInteger(value.cleared) && value.cleared >= 0 && value.cleared <= 4) {
      return value.cleared;
    }
  } catch {}
  return 0;
}

// Connect the saved record before playback. Only game-originated revision
// changes write to storage; hydrating the default VM must never overwrite it.
export function connectProgress(viewModel, environment = globalThis) {
  const count = viewModel.number('completedLevels');
  const ready = viewModel.boolean('progressReady');
  const revision = viewModel.number('progressRevision');
  const status = viewModel.string('progressStatus');
  if (!count || !ready || !revision || !status) throw new Error('The Rive build is missing campaign progress bindings.');
  let storage;
  let lastRevision = revision.value;
  const read = () => parseProgress(storage.getItem(STORAGE_KEY));
  ready.value = false;
  try {
    storage = environment.localStorage; // Access itself can throw in private/blocked contexts.
    count.value = read();
    status.value = 'saved';
  } catch {
    count.value = 0;
    status.value = 'unavailable';
  }
  ready.value = true;

  const save = () => {
    if (revision.value === lastRevision) return;
    lastRevision = revision.value;
    const cleared = count.value;
    if (!Number.isInteger(cleared) || cleared < 0 || cleared > 4) return;
    try {
      if (!storage) storage = environment.localStorage;
      if (cleared === 0) storage.removeItem(STORAGE_KEY);
      else {
        // Another tab may have progressed farther while this one replayed a level.
        const best = Math.max(cleared, read());
        storage.setItem(STORAGE_KEY, JSON.stringify({ version: 1, cleared: best }));
        count.value = best;
      }
      status.value = 'saved';
    } catch { status.value = 'unavailable'; }
  };
  revision.on(save);
  const changed = (event) => {
    if (event.key !== STORAGE_KEY && event.key !== null) return;
    if (event.storageArea && event.storageArea !== storage) return;
    try { count.value = read(); status.value = 'saved'; }
    catch { status.value = 'unavailable'; }
  };
  environment.addEventListener?.('storage', changed);
  // A pending Rive event also gets one final synchronous flush when leaving.
  environment.addEventListener?.('pagehide', save);
  return () => {
    save();
    revision.off(save);
    environment.removeEventListener?.('storage', changed);
    environment.removeEventListener?.('pagehide', save);
  };
}
