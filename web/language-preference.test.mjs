import { test } from 'node:test';
import assert from 'node:assert/strict';
import { browserLanguage, connectLanguage, LANGUAGE_KEY } from './language-preference.mjs';

function property(value) {
  const listeners = new Set();
  return { value, on: fn => listeners.add(fn), off: fn => listeners.delete(fn),
    flush() { for (const fn of listeners) fn({ data: this.value }); } };
}
function vm() {
  const p = { browserLanguage: property('en'), languageRevision: property(0) };
  return { p, string: key => p[key], number: key => p[key] };
}
function host(languages, initial = {}) {
  const data = new Map(Object.entries(initial));
  const events = new Map();
  const localStorage = { getItem: key => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, String(value)), removeItem: key => data.delete(key) };
  return { navigator: { languages }, data, localStorage,
    addEventListener: (name, fn) => events.set(name, fn),
    removeEventListener: name => events.delete(name),
    dispatch: (name, value) => events.get(name)?.(value) };
}
function choose(v, language) {
  v.p.browserLanguage.value = language;
  v.p.languageRevision.value++;
  v.p.languageRevision.flush();
}

test('browser language detects Traditional Chinese and defaults other languages to English', () => {
  for (const tag of ['zh-TW', 'zh-Hant', 'zh-Hant-HK', 'zh-HK', 'zh-MO']) {
    assert.equal(browserLanguage({ languages: [tag] }), 'zh-TW');
  }
  for (const tag of ['zh-CN', 'zh-Hans', 'zh', 'ja-JP', 'fr-FR', 'en-US']) {
    assert.equal(browserLanguage({ language: tag }), 'en');
  }
  assert.equal(browserLanguage({ languages: ['ja-JP', 'zh-TW', 'en-US'] }), 'zh-TW');
  assert.equal(browserLanguage({ languages: ['en-US', 'zh-TW'] }), 'en');
});

test('automatic language is used on first load without creating a preference', () => {
  const h = host(['zh-TW']); const v = vm(); connectLanguage(v, h);
  assert.equal(v.p.browserLanguage.value, 'zh-TW');
  v.p.languageRevision.flush();
  assert.equal(h.data.has(LANGUAGE_KEY), false);
  assert.equal(vm().p.browserLanguage.value, 'en');
});

test('explicit choice overrides the browser and survives reload', () => {
  const h = host(['zh-TW']); const v = vm(); connectLanguage(v, h);
  choose(v, 'en');
  assert.equal(h.data.get(LANGUAGE_KEY), 'en');
  const reopened = vm(); connectLanguage(reopened, h);
  assert.equal(reopened.p.browserLanguage.value, 'en');
  assert.equal(reopened.p.languageRevision.value, 0);
});

test('invalid saved values fall back to browser language', () => {
  for (const invalid of ['', 'zh-CN', 'null', '{"language":"zh-TW"}']) {
    const h = host(['zh-Hant'], { [LANGUAGE_KEY]: invalid });
    const v = vm(); connectLanguage(v, h);
    assert.equal(v.p.browserLanguage.value, 'zh-TW');
    assert.equal(h.data.get(LANGUAGE_KEY), invalid);
  }
});

test('another tab can update or clear the explicit preference', () => {
  const h = host(['zh-TW']); const v = vm(); connectLanguage(v, h);
  h.localStorage.setItem(LANGUAGE_KEY, 'en');
  h.dispatch('storage', { key: 'other', storageArea: h.localStorage });
  assert.equal(v.p.browserLanguage.value, 'zh-TW');
  h.dispatch('storage', { key: LANGUAGE_KEY, storageArea: h.localStorage });
  assert.equal(v.p.browserLanguage.value, 'en');
  h.localStorage.removeItem(LANGUAGE_KEY);
  h.dispatch('storage', { key: LANGUAGE_KEY, storageArea: h.localStorage });
  assert.equal(v.p.browserLanguage.value, 'zh-TW');
  assert.equal(v.p.languageRevision.value, 0);
});

test('blocked storage keeps the current language and pending choices flush on pagehide', () => {
  const blocked = { navigator: { language: 'zh-TW' },
    get localStorage() { throw new Error('blocked'); } };
  const v = vm(); connectLanguage(v, blocked);
  assert.equal(v.p.browserLanguage.value, 'zh-TW');
  choose(v, 'en');
  assert.equal(v.p.browserLanguage.value, 'en');
  const h = host(['en-US']); const pending = vm(); const stop = connectLanguage(pending, h);
  pending.p.browserLanguage.value = 'zh-TW'; pending.p.languageRevision.value++;
  h.dispatch('pagehide');
  assert.equal(h.data.get(LANGUAGE_KEY), 'zh-TW');
  stop(); choose(pending, 'en');
  assert.equal(h.data.get(LANGUAGE_KEY), 'zh-TW');
});
