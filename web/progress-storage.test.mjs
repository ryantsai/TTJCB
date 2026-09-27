import { test } from 'node:test';
import assert from 'node:assert/strict';
import { connectProgress, parseProgress, STORAGE_KEY } from './progress-storage.mjs';

function property(value) {
  const listeners = new Set();
  return { value, on: fn => listeners.add(fn), off: fn => listeners.delete(fn),
    flush() { for (const fn of listeners) fn({ data: this.value }); } };
}
function vm() {
  const p = { completedLevels: property(0), progressRevision: property(0), progressReady: property(false), progressStatus: property('session') };
  return { p, number: key => p[key], boolean: key => p[key], string: key => p[key] };
}
function host(initial = {}) {
  const data = new Map(Object.entries(initial));
  const events = new Map();
  const localStorage = { getItem: key => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, String(value)), removeItem: key => data.delete(key) };
  return { data, localStorage, addEventListener: (name, fn) => events.set(name, fn),
    removeEventListener: name => events.delete(name), dispatch: (name, value) => events.get(name)?.(value) };
}
function complete(v, count) {
  v.p.completedLevels.value = count;
  v.p.progressRevision.value++;
  v.p.progressRevision.flush();
}
test('new players start at zero and hydration never writes a default save', () => {
  const h = host(); const v = vm(); connectProgress(v, h);
  assert.equal(v.p.completedLevels.value, 0);
  assert.equal(v.p.progressReady.value, true);
  v.p.progressRevision.flush();
  assert.equal(h.data.has(STORAGE_KEY), false);
});
test('clearing levels survives a fresh page and retains the final completion', () => {
  const h = host(); const v = vm(); const stop = connectProgress(v, h);
  for (let level = 1; level <= 4; level++) {
    complete(v, level);
    const reopened = vm(); connectProgress(reopened, h);
    assert.equal(reopened.p.completedLevels.value, level);
  }
  stop();
  assert.deepEqual(JSON.parse(h.data.get(STORAGE_KEY)), { version: 1, cleared: 4 });
});
test('revisiting an earlier level cannot lower stored progress', () => {
  const h = host({ [STORAGE_KEY]: JSON.stringify({ version: 1, cleared: 3 }) });
  const v = vm(); connectProgress(v, h); complete(v, 1);
  assert.equal(v.p.completedLevels.value, 3);
  assert.equal(parseProgress(h.data.get(STORAGE_KEY)), 3);
});
test('reset persists, removes only this game save and restores first-level access', () => {
  const h = host({ [STORAGE_KEY]: '{"version":1,"cleared":4}', unrelated: 'keep' });
  const v = vm(); connectProgress(v, h); complete(v, 0);
  assert.equal(h.data.has(STORAGE_KEY), false);
  assert.equal(h.data.get('unrelated'), 'keep');
  const next = vm(); connectProgress(next, h);
  assert.equal(next.p.completedLevels.value, 0);
});
test('malformed, out-of-range and incompatible saves never unlock levels', () => {
  for (const raw of [null, '', 'oops', 'null', '[]', '{}', '{"version":2,"cleared":4}',
    '{"version":1,"cleared":-1}', '{"version":1,"cleared":5}', '{"version":1,"cleared":1.5}',
    '{"version":1,"cleared":"4"}', '{"version":1,"cleared":1e400}']) assert.equal(parseProgress(raw), 0);
});
test('blocked reads and failed writes report session-only progress without crashing', () => {
  const blocked = { get localStorage() { throw new Error('blocked'); } };
  const v = vm(); connectProgress(v, blocked); complete(v, 1);
  assert.equal(v.p.progressStatus.value, 'unavailable');
  assert.equal(v.p.completedLevels.value, 1);
  const h = host(); h.localStorage.setItem = () => { throw new Error('quota'); };
  const w = vm(); connectProgress(w, h); complete(w, 2);
  assert.equal(w.p.progressStatus.value, 'unavailable');
});
test('other tabs synchronize progress and reset while unrelated keys are ignored', () => {
  const h = host(); const v = vm(); connectProgress(v, h);
  h.localStorage.setItem(STORAGE_KEY, '{"version":1,"cleared":2}');
  h.dispatch('storage', { key: 'unrelated', storageArea: h.localStorage });
  assert.equal(v.p.completedLevels.value, 0);
  h.dispatch('storage', { key: STORAGE_KEY, storageArea: h.localStorage });
  assert.equal(v.p.completedLevels.value, 2);
  h.localStorage.removeItem(STORAGE_KEY);
  h.dispatch('storage', { key: STORAGE_KEY, storageArea: h.localStorage });
  assert.equal(v.p.completedLevels.value, 0);
});
test('pagehide flushes a pending completion and cleanup removes observers', () => {
  const h = host(); const v = vm(); const stop = connectProgress(v, h);
  v.p.completedLevels.value = 1; v.p.progressRevision.value++;
  h.dispatch('pagehide');
  assert.equal(parseProgress(h.data.get(STORAGE_KEY)), 1);
  stop(); complete(v, 2);
  assert.equal(parseProgress(h.data.get(STORAGE_KEY)), 1);
});
