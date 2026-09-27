export const LANGUAGE_KEY = 'ttgo.language.v1';

export function browserLanguage(navigator = {}) {
  const languages = navigator.languages?.length ? navigator.languages : [navigator.language];
  for (const tag of languages) {
    if (typeof tag !== 'string') continue;
    const parts = tag.toLowerCase().split('-');
    if (parts[0] === 'en') return 'en';
    if (parts[0] === 'zh' && !parts.includes('hans') &&
        (parts.includes('hant') || parts.some(part => ['tw', 'hk', 'mo'].includes(part)))) return 'zh-TW';
  }
  return 'en';
}

// The host writes the initial value before playback. Only a Rive user-action
// revision writes localStorage, so browser-language detection stays temporary.
export function connectLanguage(viewModel, environment = globalThis) {
  const language = viewModel.string('browserLanguage');
  const revision = viewModel.number('languageRevision');
  if (!language || !revision) throw new Error('The Rive build is missing language bindings.');
  const automatic = browserLanguage(environment.navigator);
  let storage;
  const read = () => {
    try {
      storage = environment.localStorage;
      const saved = storage.getItem(LANGUAGE_KEY);
      return saved === 'en' || saved === 'zh-TW' ? saved : automatic;
    } catch { return automatic; }
  };
  language.value = read();
  let lastRevision = revision.value;
  const save = () => {
    if (revision.value === lastRevision) return;
    lastRevision = revision.value;
    if (language.value !== 'en' && language.value !== 'zh-TW') return;
    try {
      if (!storage) storage = environment.localStorage;
      storage.setItem(LANGUAGE_KEY, language.value);
    } catch {}
  };
  revision.on(save);
  const changed = event => {
    if (event.key !== LANGUAGE_KEY && event.key !== null) return;
    if (event.storageArea && event.storageArea !== storage) return;
    language.value = read();
  };
  environment.addEventListener?.('storage', changed);
  environment.addEventListener?.('pagehide', save);
  return () => {
    save();
    revision.off(save);
    environment.removeEventListener?.('storage', changed);
    environment.removeEventListener?.('pagehide', save);
  };
}
