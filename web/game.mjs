import { Rive, Layout, Fit, Alignment, RuntimeLoader } from '@rive-app/webgl2';
import { connectProgress } from './progress-storage.mjs';
import { connectLanguage, initialLanguage } from './language-preference.mjs';

import { connectTouchGamepad, TOUCH_PAD_ID } from './touch-gamepad.mjs';

import { hostStrings } from './host-strings.mjs';
import { connectQuality, renderRatio } from './quality.mjs';
import { connectHome, loadHome } from './home-link.mjs';
import { loadGameBuffer } from './loading-progress.mjs';

const releaseVersion = new URL(import.meta.url).searchParams.get('v');
const assetUrl = name => new URL(`${name}${releaseVersion ? `?v=${releaseVersion}` : ''}`, location.href).href;
RuntimeLoader.setWasmUrl(assetUrl('./rive.wasm'));
const canvas = document.querySelector('#game');
const notice = document.querySelector('#notice');
const noticeText = document.querySelector('#notice-text');
const loadingBar = document.querySelector('#loading-progress');
const loadingValue = document.querySelector('#loading-value');
const retry = document.querySelector('#loading-retry');
const paint = () => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)));
retry.addEventListener('click', () => location.reload());
const fullscreen = document.querySelector('#fullscreen');
const touch = connectTouchGamepad(document.querySelector('#touch-gamepad'), canvas);
let locale = initialLanguage();
let quality = 'medium';
let releaseQuality;
let releaseHome;
const home = loadHome(assetUrl);
let noticeKey = 'loading';
let fullscreenUnavailable = false;
function updateHostLanguage(next = locale) {
  locale = next;
  const strings = hostStrings[locale];
  document.documentElement.lang = locale;
  document.title = strings.title;
  canvas.setAttribute('aria-label', strings.title);
  noticeText.textContent = strings[noticeKey];
  document.querySelector('#loading-title').textContent = strings.title;
  loadingBar.setAttribute('aria-label', strings.loading);
  retry.textContent = strings.retry;
  for (const element of document.querySelectorAll('[data-touch-label]')) {
    const label = strings.touch[element.dataset.touchLabel];
    element.setAttribute('aria-label', label);
    const caption = element.querySelector('small');
    if (caption) caption.textContent = label;
  }
  const active = Boolean(document.fullscreenElement);
  fullscreen.setAttribute('aria-label', active ? strings.exit : strings.enter);
  fullscreen.setAttribute('aria-pressed', String(active));
  fullscreen.title = fullscreenUnavailable ? strings.unavailable : active ? strings.exit : strings.fullscreen;
}
function showNotice(key) {
  noticeKey = key;
  notice.hidden = false;
  notice.setAttribute('aria-busy', 'false');
  retry.hidden = false;
  updateHostLanguage();
}
function loading(percent, key) {
  if (key) noticeKey = key;
  loadingBar.value = Math.max(loadingBar.value, percent);
  loadingValue.textContent = `${Math.round(loadingBar.value)}%`;
  updateHostLanguage();
}
updateHostLanguage();
let releaseProgress;
let releaseLanguage;
let gamepadProperty;
let keyboardProperty;
let lastPads = '';
let keySequence = 0;
const keyEvents = [];
const keyCodes = {
  KeyW: 87, KeyA: 65, KeyS: 83, KeyD: 68,
  KeyJ: 74, KeyK: 75, KeyL: 76, KeyI: 73, KeyU: 85,
  KeyR: 82, KeyH: 72,
  Space: 32, Enter: 257, Escape: 256, Backspace: 259, Tab: 258,
  ArrowUp: 265, ArrowLeft: 263, ArrowDown: 264, ArrowRight: 262,
  Comma: 44, Period: 46, Slash: 47, Semicolon: 59, Quote: 39,
  ShiftRight: 344, ControlRight: 345, Delete: 261,
  Numpad1: 321, Numpad2: 322, Numpad3: 323, NumpadEnter: 335,
};
function forwardKey(event) {
  const code = keyCodes[event.code];
  if (!keyboardProperty || code === undefined || event.metaKey || event.ctrlKey || event.altKey) return;
  event.preventDefault();
  event.stopImmediatePropagation();
  keyEvents.push(`${++keySequence},${code},${event.type === 'keyup' ? 'up' : event.repeat ? 'repeat' : 'down'}`);
  if (keyEvents.length > 32) keyEvents.shift();
  keyboardProperty.value = keyEvents.join(';');
}
canvas.addEventListener('keydown', forwardKey, { capture: true });
canvas.addEventListener('keyup', forwardKey, { capture: true });
// The drawing surface follows the graphics level chosen on the title screen:
// the screen's own pixel ratio, reduced to fit the level's pixel budget.
function resizeSurface() {
  const { width, height } = canvas.getBoundingClientRect();
  game?.resizeDrawingSurfaceToCanvas(renderRatio(quality, width, height, window.devicePixelRatio || 1));
}
let game;
async function boot() {
  loading(15, 'loadingGame');
  const buffer = await loadGameBuffer(assetUrl('./game.riv'), fraction => loading(15 + fraction * 55));
  loading(75, 'loadingEngine');
  await paint();
  await RuntimeLoader.awaitInstance();
  game = new Rive({
    buffer,
    canvas, artboard: 'main', stateMachines: 'Game', autoplay: false, autoBind: true,
    layout: new Layout({ fit: Fit.Layout, alignment: Alignment.Center }),
    async onLoad() {
      try {
        loading(85, 'loadingSave');
        await paint();
        releaseProgress = connectProgress(game.viewModelInstance);
        releaseLanguage = connectLanguage(game.viewModelInstance, globalThis, updateHostLanguage);
        releaseQuality = connectQuality(game.viewModelInstance, globalThis, next => { quality = next; resizeSurface(); });
        home.then(url => {
          if (url) releaseHome = connectHome(game.viewModelInstance, url, target => location.assign(new URL(target, location.href)));
        }).catch(error => console.error(error));
        gamepadProperty = game.viewModelInstance.string('browserGamepads');
        keyboardProperty = game.viewModelInstance.string('browserKeyboard');
        resizeSurface();
        game.play('Game');
        loading(95, 'loadingFrame');
        await paint();
        loading(100, 'ready');
        await paint();
        notice.hidden = true;
        notice.setAttribute('aria-busy', 'false');
        touch.ready();
        fullscreen.hidden = !document.fullscreenEnabled;
        canvas.focus();
      } catch (error) { console.error(error); showNotice('progressError'); }
    },
    onLoadError() { showNotice('loadError'); },
  });
}
boot().catch(error => { console.error(error); showNotice('loadError'); });
const observer = new ResizeObserver(resizeSurface);
observer.observe(canvas);
fullscreen.addEventListener('click', async () => {
  try {
    if (document.fullscreenElement) await document.exitFullscreen();
    else await document.documentElement.requestFullscreen();
    canvas.focus();
  } catch { fullscreenUnavailable = true; updateHostLanguage(); }
});
document.addEventListener('fullscreenchange', () => {
  fullscreenUnavailable = false;
  updateHostLanguage();
  resizeSurface();
});
function pollGamepads() {
  if (gamepadProperty) {
    const pads = document.hidden ? [] : Array.from(navigator.getGamepads?.() ?? []);
    const virtual = document.hidden ? null : touch.sample();
    const records = pads.filter(pad => pad?.connected && pad.mapping === 'standard' && pad.index !== TOUCH_PAD_ID).slice(0, virtual ? 3 : 4).map(pad => {
      let mask = 0;
      for (let i = 0; i < Math.min(16, pad.buttons.length); i++) {
        if (pad.buttons[i].pressed || pad.buttons[i].value > 0.5) mask |= 1 << i;
      }
      const axis = value => Math.max(-1, Math.min(1, Number.isFinite(value) ? value : 0)).toFixed(3);
      return `${pad.index},${axis(pad.axes[0])},${axis(pad.axes[1])},${mask}`;
    });
    if (virtual) records.push(virtual);
    const snapshot = records.join(';');
    if (snapshot !== lastPads) { gamepadProperty.value = snapshot; lastPads = snapshot; }
  }
  requestAnimationFrame(pollGamepads);
}
requestAnimationFrame(pollGamepads);
// Keep the save observer alive across the browser's back/forward cache.
window.addEventListener('pagehide', event => {
  if (!event.persisted) { releaseProgress?.(); releaseLanguage?.(); releaseQuality?.(); releaseHome?.(); }
});
