import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createTouchState } from './touch-gamepad.mjs';

test('movement and attack/jump can be held with independent fingers', () => {
  const pad = createTouchState();
  pad.move(1, 0); assert.equal(pad.sample(), '31,1.000,0.000,0');
  pad.press(11, 2); pad.press(12, 0);
  assert.equal(pad.sample(), '31,1.000,0.000,4');
  assert.equal(pad.sample(), '31,1.000,0.000,5');
  pad.release(11); assert.equal(pad.sample(), '31,1.000,0.000,1');
  pad.move(0, 0); assert.equal(pad.sample(), '31,0.000,0.000,1');
  pad.release(12); assert.equal(pad.sample(), '31,0.000,0.000,0');
});
test('quick taps preserve press and release across render frames', () => {
  const pad = createTouchState();
  pad.press(1, 9); pad.release(1);
  assert.equal(pad.sample(), '31,0.000,0.000,512');
  assert.equal(pad.sample(), '31,0.000,0.000,0');
});
test('two fingers on one button keep it held until both release', () => {
  const pad = createTouchState();
  pad.press(1, 0); pad.press(2, 0); pad.release(1);
  assert.equal(pad.sample(), '31,0.000,0.000,1');
  pad.release(2); assert.equal(pad.sample(), '31,0.000,0.000,0');
});
test('stick is bounded and reset discards queued actions after cancellation', () => {
  const pad = createTouchState();
  pad.move(10, 10);
  assert.equal(pad.sample(), '31,0.707,0.707,0');
  pad.press(1, 7); pad.press(2, 1); pad.reset();
  assert.equal(pad.sample(), '31,0.000,0.000,0');
  pad.release(1); assert.equal(pad.sample(), '31,0.000,0.000,0');
});
test('quick directional double taps retain the neutral edge needed for dashing', () => {
  const pad = createTouchState();
  pad.move(1, 0); pad.move(0, 0); pad.move(1, 0);
  assert.equal(pad.sample(), '31,1.000,0.000,0');
  assert.equal(pad.sample(), '31,0.000,0.000,0');
  assert.equal(pad.sample(), '31,1.000,0.000,0');
});
