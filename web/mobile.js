// Loaded in <head>, before the game or its loading screen becomes interactive.
// Keep this guard in sync with TTJCB/web/mobile.js (inlined by its host build).
(() => {
  const root = document.documentElement;
  if (root.dataset.mobileGesturesReady !== undefined) return;
  root.dataset.mobileGesturesReady = '';
  let mobile = navigator.maxTouchPoints > 0 || matchMedia('(any-pointer: coarse)').matches;
  const enable = () => { mobile = true; root.classList.add('mobile-gestures'); };
  if (mobile) enable();
  // Hybrid devices may acquire a touchscreen after the page has loaded.
  document.addEventListener('pointerdown', (e) => { if (e.pointerType === 'touch') enable(); }, { capture: true, passive: true });
  document.addEventListener('touchstart', enable, { capture: true, passive: true });

  const editable = (target) => target?.isContentEditable || target?.closest?.(
    'textarea, input:not([type]), input[type="text"], input[type="search"], input[type="password"], input[type="email"], input[type="url"], input[type="tel"], input[type="number"], [contenteditable="true"]',
  );
  const options = { capture: true, passive: false };
  // Safari has its own pinch events and can ignore the viewport's scale limits.
  for (const type of ['gesturestart', 'gesturechange', 'gestureend']) {
    document.addEventListener(type, (e) => { if (mobile) e.preventDefault(); }, options);
  }
  document.addEventListener('touchmove', (e) => {
    if (mobile && (e.touches.length > 1 || (e.scale !== undefined && e.scale !== 1))) e.preventDefault();
  }, options);
  for (const type of ['contextmenu', 'selectstart', 'dragstart', 'dblclick']) {
    document.addEventListener(type, (e) => {
      if (mobile && !editable(e.target)) e.preventDefault();
    }, options);
  }
  // Do not cancel touchend or stop propagation: rapid game taps, native fields,
  // sliders and the drawing game's PointerEvent pan/pinch gestures still work.
})();
