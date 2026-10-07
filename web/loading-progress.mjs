// Download progress comes from bytes read, when the server supplies a length.
// Without one, the caller keeps its current stage until the download completes.
export async function loadGameBuffer(url, onProgress, fetcher = globalThis.fetch) {
  const response = await fetcher(url);
  if (!response.ok) throw new Error(`Game download failed: ${response.status}`);
  const total = Number(response.headers.get('content-length'));
  const encoded = response.headers.get('content-encoding');
  const measurable = total > 0 && (!encoded || encoded === 'identity');
  if (!response.body) return response.arrayBuffer();
  const reader = response.body.getReader();
  const chunks = [];
  let received = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
      received += value.byteLength;
      if (measurable) onProgress(Math.min(1, received / total));
    }
  } finally {
    reader.releaseLock();
  }
  const result = new Uint8Array(received);
  let offset = 0;
  for (const chunk of chunks) { result.set(chunk, offset); offset += chunk.byteLength; }
  return result.buffer;
}
