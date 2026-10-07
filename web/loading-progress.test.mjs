import test from 'node:test';
import assert from 'node:assert/strict';
import { loadGameBuffer } from './loading-progress.mjs';

const download = headers => new Response(new ReadableStream({
  start(controller) {
    controller.enqueue(new Uint8Array([1, 2]));
    controller.enqueue(new Uint8Array([3, 4, 5]));
    controller.close();
  },
}), { headers });

test('reports received bytes and preserves the complete game buffer', async () => {
  const progress = [];
  const buffer = await loadGameBuffer('game.riv', value => progress.push(value), async () => download({ 'content-length': '5' }));
  assert.deepEqual(progress, [0.4, 1]);
  assert.deepEqual([...new Uint8Array(buffer)], [1, 2, 3, 4, 5]);
});

for (const headers of [{}, { 'content-length': '2', 'content-encoding': 'gzip' }]) {
  test(`does not invent byte percentages for ${JSON.stringify(headers)}`, async () => {
    const buffer = await loadGameBuffer('game.riv', () => assert.fail('Unknown download length'), async () => download(headers));
    assert.equal(buffer.byteLength, 5);
  });
}

test('rejects a failed download instead of marking it complete', async () => {
  await assert.rejects(loadGameBuffer('game.riv', () => assert.fail('Failed download'), async () => new Response('', { status: 503 })), /503/);
});

test('propagates an interrupted stream', async () => {
  const response = new Response(new ReadableStream({ start(controller) { controller.error(new Error('Offline')); } }));
  await assert.rejects(loadGameBuffer('game.riv', () => {}, async () => response), /Offline/);
});
