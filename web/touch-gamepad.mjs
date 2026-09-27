// A reserved controller ID keeps touch input independent of physical controllers.
export const TOUCH_PAD_ID = 31;
export function createTouchState() {
  const pointers = new Map();
  const pending = [];
  let x = 0, y = 0, mask = 0;
  function record() {
    const next = { x, y, mask };
    // Preserve button and directional edges, including quick taps and dashes.
    const direction = value => Math.abs(value) > .28 ? Math.sign(value) : 0;
    const last = pending.at(-1);
    if (last && last.mask === mask && direction(last.x) === direction(x) && direction(last.y) === direction(y)) pending[pending.length - 1] = next;
    else pending.push(next);
  }
  return {
    press(id, bit) { pointers.set(id, bit); mask = [...pointers.values()].reduce((m, b) => m | (1 << b), 0); record(); },
    release(id) { pointers.delete(id); mask = [...pointers.values()].reduce((m, b) => m | (1 << b), 0); record(); },
    move(dx, dy) { const length = Math.max(1, Math.hypot(dx, dy)); x = dx / length; y = dy / length; record(); },
    reset() { pointers.clear(); pending.length = 0; x = y = mask = 0; record(); },
    sample() { const s = pending.shift() ?? { x, y, mask }; return `${TOUCH_PAD_ID},${s.x.toFixed(3)},${s.y.toFixed(3)},${s.mask}`; },
  };
}

export function connectTouchGamepad(root, canvas) {
  const state = createTouchState();
  const stick = root.querySelector('.touch-stick');
  const knob = root.querySelector('.touch-knob');
  const buttons = [...root.querySelectorAll('[data-bit]')];
  const heldPointers = new Map(buttons.map(button => [button, new Set()]));
  let stickPointer = null;
  let active = false;
  let ready = false;
  const coarse = matchMedia('(any-pointer: coarse)');
  function visibility() { root.hidden = !ready || !(coarse.matches || navigator.maxTouchPoints > 0 || active); document.body.classList.toggle('touch-controls', !root.hidden); }
  function reset() {
    state.reset(); stickPointer = null;
    knob.style.transform = '';
    for (const button of buttons) { heldPointers.get(button).clear(); button.classList.remove('held'); button.setAttribute('aria-pressed', 'false'); }
  }
  function claim(event, element) {
    if (event.pointerType === 'mouse' && event.button !== 0) return false;
    event.preventDefault(); event.stopPropagation();
    active = true; element.setPointerCapture(event.pointerId); canvas.focus({ preventScroll: true });
    return true;
  }
  function move(event) {
    const bounds = stick.getBoundingClientRect();
    const radius = bounds.width * .36;
    let x = (event.clientX - bounds.left - bounds.width / 2) / radius;
    let y = (event.clientY - bounds.top - bounds.height / 2) / radius;
    const length = Math.max(1, Math.hypot(x, y)); x /= length; y /= length;
    state.move(x, y); knob.style.transform = `translate(${x * radius}px, ${y * radius}px)`;
  }
  stick.addEventListener('pointerdown', event => { if (stickPointer !== null || !claim(event, stick)) return; stickPointer = event.pointerId; move(event); });
  stick.addEventListener('pointermove', event => { if (event.pointerId === stickPointer) { event.preventDefault(); move(event); } });
  for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) {
    stick.addEventListener(type, event => { if (event.pointerId === stickPointer) { stickPointer = null; state.move(0, 0); knob.style.transform = ''; } });
  }
  for (const button of buttons) {
    const held = heldPointers.get(button);
    button.addEventListener('pointerdown', event => {
      if (!claim(event, button)) return;
      held.add(event.pointerId); state.press(event.pointerId, Number(button.dataset.bit));
      button.classList.add('held'); button.setAttribute('aria-pressed', 'true');
    });
    for (const type of ['pointerup', 'pointercancel', 'lostpointercapture']) button.addEventListener(type, event => {
      if (!held.delete(event.pointerId)) return;
      state.release(event.pointerId);
      button.classList.toggle('held', held.size > 0); button.setAttribute('aria-pressed', String(held.size > 0));
    });
  }
  root.addEventListener('contextmenu', event => event.preventDefault());
  window.addEventListener('blur', reset);
  window.addEventListener('pagehide', reset);
  window.addEventListener('resize', reset);
  document.addEventListener('visibilitychange', () => { if (document.hidden) reset(); });
  coarse.addEventListener('change', visibility);
  visibility();
  return { sample: () => active ? state.sample() : null, ready() { ready = true; visibility(); } };
}
