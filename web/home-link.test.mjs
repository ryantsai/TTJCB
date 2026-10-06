import { test } from 'node:test';
import assert from 'node:assert/strict';
import { connectHome, loadHome } from './home-link.mjs';

const asset = name => `https://example.test/ttjcb/${name.slice(2)}?v=1`;
const file = (ok, body) => async () => ({ ok, json: async () => { if (body instanceof Error) throw body; return body; } });

test('a home.json with a url gives the home address', async () => {
  const seen = [];
  const url = await loadHome(name => { seen.push(name); return asset(name); }, file(true, { url: '../' }));
  assert.equal(url, '../');
  assert.deepEqual(seen, ['./home.json']);
});

test('no file, bad JSON, a missing url or a network error mean no button', async () => {
  assert.equal(await loadHome(asset, file(false, {})), null);
  assert.equal(await loadHome(asset, file(true, new SyntaxError('<!doctype html>'))), null);
  assert.equal(await loadHome(asset, file(true, { url: '' })), null);
  assert.equal(await loadHome(asset, file(true, { url: 3 })), null);
  assert.equal(await loadHome(asset, async () => { throw new TypeError('offline'); }), null);
});

function property(value) {
  const listeners = new Set();
  return { value, on: fn => listeners.add(fn), off: fn => listeners.delete(fn),
    flush() { for (const fn of listeners) fn({ data: this.value }); } };
}
function viewModel() {
  const p = { homeAvailable: property(false), homeRevision: property(0) };
  return { p, boolean: key => p[key], number: key => p[key] };
}

test('the button is offered, and a click in the game navigates once', () => {
  const vm = viewModel(); const visited = [];
  const release = connectHome(vm, '../', url => visited.push(url));
  assert.equal(vm.p.homeAvailable.value, true);
  vm.p.homeRevision.flush();
  assert.deepEqual(visited, []);
  vm.p.homeRevision.value++; vm.p.homeRevision.flush();
  assert.deepEqual(visited, ['../']);
  vm.p.homeRevision.flush();
  assert.deepEqual(visited, ['../']);
  release();
  assert.equal(vm.p.homeAvailable.value, false);
  vm.p.homeRevision.value++; vm.p.homeRevision.flush();
  assert.deepEqual(visited, ['../']);
});

test('a Rive build without the bindings is rejected', () => {
  assert.throws(() => connectHome({ boolean: () => undefined, number: () => undefined }, '../', () => {}), /home bindings/);
});
