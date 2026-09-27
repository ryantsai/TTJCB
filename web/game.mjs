import { Rive, Layout, Fit, Alignment, RuntimeLoader } from '@rive-app/webgl2';
import { connectProgress } from './progress-storage.mjs';

RuntimeLoader.setWasmUrl(new URL('./rive.wasm', location.href).href);
const canvas = document.querySelector('#game');
const notice = document.querySelector('#notice');
const fullscreen = document.querySelector('#fullscreen');
let releaseProgress;
let gamepadProperty;
let keyboardProperty;
let lastPads = '';
let keySequence = 0;
const keyEvents = [];
const keyCodes = {
  KeyW: 87, KeyA: 65, KeyS: 83, KeyD: 68,
  KeyJ: 74, KeyK: 75, KeyL: 76, KeyI: 73, KeyU: 85,
  KeyM: 77, KeyR: 82, KeyH: 72,
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
const game = new Rive({
  src: new URL('./game.riv', location.href).href,
  canvas, artboard: 'main', stateMachines: 'Game', autoplay: false, autoBind: true,
  layout: new Layout({ fit: Fit.Layout, alignment: Alignment.Center }),
  onLoad() {
    try {
      releaseProgress = connectProgress(game.viewModelInstance);
      gamepadProperty = game.viewModelInstance.string('browserGamepads');
      keyboardProperty = game.viewModelInstance.string('browserKeyboard');
      game.resizeDrawingSurfaceToCanvas();
      game.play('Game');
      notice.hidden = true;
      fullscreen.hidden = !document.fullscreenEnabled;
      canvas.focus();
    } catch (error) { notice.textContent = `Unable to load game progress: ${error.message}`; }
  },
  onLoadError() { notice.textContent = 'The game could not load. Please try again.'; },
});
const observer = new ResizeObserver(() => game.resizeDrawingSurfaceToCanvas());
observer.observe(canvas);
fullscreen.addEventListener('click', async () => {
  try {
    if (document.fullscreenElement) await document.exitFullscreen();
    else await document.documentElement.requestFullscreen();
    canvas.focus();
  } catch { fullscreen.title = 'Fullscreen is unavailable in this browser.'; }
});
document.addEventListener('fullscreenchange', () => {
  const active = Boolean(document.fullscreenElement);
  fullscreen.setAttribute('aria-label', active ? 'Exit fullscreen' : 'Enter fullscreen');
  fullscreen.setAttribute('aria-pressed', String(active));
  fullscreen.title = active ? 'Exit fullscreen' : 'Fullscreen';
  game.resizeDrawingSurfaceToCanvas();
});
function pollGamepads() {
  if (gamepadProperty) {
    const pads = document.hidden ? [] : Array.from(navigator.getGamepads?.() ?? []);
    const snapshot = pads.filter(pad => pad?.connected && pad.mapping === 'standard').slice(0, 4).map(pad => {
      let mask = 0;
      for (let i = 0; i < Math.min(16, pad.buttons.length); i++) {
        if (pad.buttons[i].pressed || pad.buttons[i].value > 0.5) mask |= 1 << i;
      }
      const axis = value => Math.max(-1, Math.min(1, Number.isFinite(value) ? value : 0)).toFixed(3);
      return `${pad.index},${axis(pad.axes[0])},${axis(pad.axes[1])},${mask}`;
    }).join(';');
    if (snapshot !== lastPads) { gamepadProperty.value = snapshot; lastPads = snapshot; }
  }
  requestAnimationFrame(pollGamepads);
}
requestAnimationFrame(pollGamepads);
// Keep the save observer alive across the browser's back/forward cache.
window.addEventListener('pagehide', event => { if (!event.persisted) releaseProgress?.(); });
