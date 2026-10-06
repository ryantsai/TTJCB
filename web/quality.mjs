export const QUALITY_KEY = 'ttgo.quality.v1';

// Pixel budgets for the drawing surface. The Rive renderer is fill-rate bound,
// so each level caps how many pixels one frame covers, whatever the aspect
// ratio, and CSS stretches the canvas to the window.
export const QUALITY_PIXELS = {
  high: 3840 * 2160,
  medium: 1920 * 1080,
  low: 1280 * 720,
};
export const QUALITIES = Object.keys(QUALITY_PIXELS);

export function isQuality(value) {
  return QUALITIES.includes(value);
}

// The device pixel ratio to draw at: the screen's own ratio, reduced until the
// surface fits the level's budget. Never above the screen's ratio, so a small
// window or a low-density screen is never upscaled.
export function renderRatio(quality, cssWidth, cssHeight, devicePixelRatio = 1) {
  const native = devicePixelRatio > 0 ? devicePixelRatio : 1;
  const area = cssWidth * cssHeight;
  if (!(area > 0)) return native;
  const budget = QUALITY_PIXELS[quality] ?? QUALITY_PIXELS.medium;
  return Math.min(native, Math.sqrt(budget / area));
}

// Best level for a device, from its GPU name and whether it is a touch device.
// Only the level's cap matters on screens that are already below it, so this
// errs towards what an integrated GPU can sustain at 4K.
export function detectQuality({ renderer = '', touch = false } = {}) {
  const gpu = String(renderer).toLowerCase();
  if (/swiftshader|llvmpipe|softpipe|software|basic render/.test(gpu)) return 'low';
  if (touch || !gpu) return 'medium';
  if (/nvidia|geforce|quadro|radeon (rx|pro)|\barc\b.*\ba\d{3}\b|apple (m\d|gpu)/.test(gpu)) return 'high';
  return 'medium'; // Intel and AMD integrated graphics, Adreno, Mali, anything unknown.
}

export function gpuRenderer(document = globalThis.document) {
  try {
    const gl = document.createElement('canvas').getContext('webgl2') ||
      document.createElement('canvas').getContext('webgl');
    if (!gl) return '';
    const info = gl.getExtension('WEBGL_debug_renderer_info');
    const name = info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : '';
    gl.getExtension('WEBGL_lose_context')?.loseContext();
    return typeof name === 'string' ? name : '';
  } catch { return ''; }
}

export function detectDeviceQuality(environment = globalThis) {
  let touch = false;
  try { touch = Boolean(environment.matchMedia?.('(pointer: coarse)').matches); } catch {}
  return detectQuality({ renderer: gpuRenderer(environment.document), touch });
}

export function savedQuality(environment = globalThis) {
  try {
    const saved = environment.localStorage.getItem(QUALITY_KEY);
    if (isQuality(saved)) return saved;
  } catch {}
  return null;
}

// Only a player's own choice is stored, so detection stays temporary and
// follows the device if the browser or GPU changes.
export function initialQuality(environment = globalThis) {
  return savedQuality(environment) ?? detectDeviceQuality(environment);
}

export function saveQuality(quality, environment = globalThis) {
  if (!isQuality(quality)) return;
  try { environment.localStorage.setItem(QUALITY_KEY, quality); } catch {}
}

// The host writes the initial level before playback. Only a Rive user-action
// revision (a click on the title screen's graphics panel) writes localStorage.
export function connectQuality(viewModel, environment = globalThis, onChange = () => {}) {
  const quality = viewModel.string('browserQuality');
  const revision = viewModel.number('qualityRevision');
  if (!quality || !revision) throw new Error('The Rive build is missing quality bindings.');
  const automatic = detectDeviceQuality(environment);
  const read = () => savedQuality(environment) ?? automatic;
  quality.value = read();
  onChange(quality.value);
  let lastRevision = revision.value;
  const save = () => {
    if (revision.value === lastRevision) return;
    lastRevision = revision.value;
    if (!isQuality(quality.value)) return;
    onChange(quality.value);
    saveQuality(quality.value, environment);
  };
  revision.on(save);
  const changed = event => {
    if (event.key !== QUALITY_KEY && event.key !== null) return;
    quality.value = read();
    onChange(quality.value);
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
