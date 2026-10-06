import { test } from 'node:test';
import assert from 'node:assert/strict';
import { QUALITY_KEY, connectQuality, detectQuality, initialQuality, renderRatio, saveQuality } from './quality.mjs';

const surface = (quality, w, h, dpr) => {
  const ratio = renderRatio(quality, w, h, dpr);
  return [Math.floor(w * ratio), Math.floor(h * ratio)];
};

test('4K at 1x or 2x: high is native, medium is 1080p, low is 720p', () => {
  for (const [w, h, dpr] of [[3840, 2160, 1], [1920, 1080, 2]]) {
    assert.deepEqual(surface('high', w, h, dpr), [3840, 2160]);
    assert.deepEqual(surface('medium', w, h, dpr), [1920, 1080]);
    assert.deepEqual(surface('low', w, h, dpr), [1280, 720]);
  }
});

test('the surface is never upscaled past the screen ratio', () => {
  assert.equal(renderRatio('high', 1280, 720, 1), 1);
  assert.equal(renderRatio('medium', 1280, 720, 1), 1);
  assert.equal(renderRatio('low', 1920, 1080, 1), Math.sqrt(1280 * 720 / (1920 * 1080)));
  assert.equal(renderRatio('high', 800, 600, 1.5), 1.5);
});

test('the cap holds for other shapes and a hidden canvas', () => {
  const [w, h] = surface('medium', 3440, 1440, 1);
  assert.ok(w * h <= 1920 * 1080 && w * h > 1920 * 1080 * 0.99);
  assert.equal(renderRatio('low', 0, 0, 2), 2);
  assert.equal(renderRatio('low', 100, 100, 0), 1);
});

test('detection: discrete and Apple GPUs high, integrated medium, software low', () => {
  const pick = renderer => detectQuality({ renderer });
  assert.equal(pick('ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'high');
  assert.equal(pick('ANGLE (AMD, AMD Radeon RX 6700 XT Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'high');
  assert.equal(pick('ANGLE (Intel, Intel(R) Arc(TM) A770 Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'high');
  assert.equal(pick('ANGLE (Apple, ANGLE Metal Renderer: Apple M5, Unspecified Version)'), 'high');
  assert.equal(pick('Apple GPU'), 'high');
  assert.equal(pick('ANGLE (Intel, Intel(R) UHD Graphics 630 Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'medium');
  assert.equal(pick('ANGLE (Intel, Intel(R) Iris(R) Xe Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'medium');
  assert.equal(pick('ANGLE (AMD, AMD Radeon(TM) Graphics Direct3D11 vs_5_0 ps_5_0, D3D11)'), 'medium');
  assert.equal(pick('ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero)), SwiftShader driver)'), 'low');
  assert.equal(pick('llvmpipe (LLVM 15.0.7, 256 bits)'), 'low');
  assert.equal(pick(''), 'medium');
  assert.equal(pick(undefined), 'medium');
});

test('detection: touch devices are medium unless the GPU is software', () => {
  assert.equal(detectQuality({ renderer: 'Apple GPU', touch: true }), 'medium');
  assert.equal(detectQuality({ renderer: 'NVIDIA GeForce RTX 4070', touch: true }), 'medium');
  assert.equal(detectQuality({ renderer: 'SwiftShader', touch: true }), 'low');
});

const environment = (stored, renderer = 'Intel(R) UHD Graphics 630') => {
  const store = new Map(stored ? [[QUALITY_KEY, stored]] : []);
  return {
    store,
    localStorage: { getItem: key => store.get(key) ?? null, setItem: (key, value) => store.set(key, value) },
    matchMedia: () => ({ matches: false }),
    document: { createElement: () => ({ getContext: () => ({
      getExtension: name => name === 'WEBGL_debug_renderer_info' ? { UNMASKED_RENDERER_WEBGL: 1 } : null,
      getParameter: () => renderer,
    }) }) },
  };
};

test('a saved choice wins; detection is not stored', () => {
  const first = environment();
  assert.equal(initialQuality(first), 'medium');
  assert.equal(first.store.size, 0);
  assert.equal(initialQuality(environment('low', 'NVIDIA GeForce RTX 4070')), 'low');
  assert.equal(initialQuality(environment('bogus', 'NVIDIA GeForce RTX 4070')), 'high');
});

test('saving keeps the player\'s choice for the next launch', () => {
  const env = environment();
  saveQuality('high', env);
  assert.equal(initialQuality(env), 'high');
  saveQuality('ultra', env);
  assert.equal(env.store.get(QUALITY_KEY), 'high');
});

test('storage that throws falls back to detection', () => {
  const env = environment(undefined, 'NVIDIA GeForce RTX 4070');
  env.localStorage = { getItem() { throw new Error('blocked'); }, setItem() { throw new Error('blocked'); } };
  assert.equal(initialQuality(env), 'high');
  assert.doesNotThrow(() => saveQuality('low', env));
});

function property(value) {
  const listeners = new Set();
  return { value, on: fn => listeners.add(fn), off: fn => listeners.delete(fn),
    flush() { for (const fn of listeners) fn({ data: this.value }); } };
}
function viewModel() {
  const p = { browserQuality: property('high'), qualityRevision: property(0) };
  return { p, string: key => p[key], number: key => p[key] };
}
function pick(vm, quality) {
  vm.p.browserQuality.value = quality;
  vm.p.qualityRevision.value++;
  vm.p.qualityRevision.flush();
}
function listening(env) {
  const events = new Map();
  return Object.assign(env, {
    addEventListener: (name, fn) => events.set(name, fn),
    removeEventListener: name => events.delete(name),
    dispatch: (name, event) => events.get(name)?.(event),
  });
}

test('the detected level is handed to the game without being stored', () => {
  const env = listening(environment());
  const vm = viewModel(); const seen = [];
  connectQuality(vm, env, level => seen.push(level));
  assert.equal(vm.p.browserQuality.value, 'medium');
  assert.deepEqual(seen, ['medium']);
  vm.p.qualityRevision.flush();
  assert.equal(env.store.has(QUALITY_KEY), false);
});

test('a choice in the game applies at once, is stored, and survives a reload', () => {
  const env = listening(environment());
  const vm = viewModel(); const seen = [];
  connectQuality(vm, env, level => seen.push(level));
  pick(vm, 'low');
  assert.deepEqual(seen, ['medium', 'low']);
  assert.equal(env.store.get(QUALITY_KEY), 'low');
  const reopened = viewModel();
  connectQuality(reopened, env);
  assert.equal(reopened.p.browserQuality.value, 'low');
  assert.equal(reopened.p.qualityRevision.value, 0);
});

test('an invalid value from the game is ignored', () => {
  const env = listening(environment());
  const vm = viewModel(); const seen = [];
  connectQuality(vm, env, level => seen.push(level));
  pick(vm, 'ultra');
  assert.deepEqual(seen, ['medium']);
  assert.equal(env.store.has(QUALITY_KEY), false);
});

test('another tab\'s choice reaches the game; clearing it returns to detection', () => {
  const env = listening(environment());
  const vm = viewModel(); const seen = [];
  connectQuality(vm, env, level => seen.push(level));
  env.store.set(QUALITY_KEY, 'high');
  env.dispatch('storage', { key: QUALITY_KEY });
  assert.equal(vm.p.browserQuality.value, 'high');
  env.store.delete(QUALITY_KEY);
  env.dispatch('storage', { key: QUALITY_KEY });
  assert.equal(vm.p.browserQuality.value, 'medium');
  env.dispatch('storage', { key: 'other' });
  assert.deepEqual(seen, ['medium', 'high', 'medium']);
});

test('a Rive build without the bindings is rejected', () => {
  assert.throws(() => connectQuality({ string: () => undefined, number: () => undefined }, listening(environment())), /quality bindings/);
});
