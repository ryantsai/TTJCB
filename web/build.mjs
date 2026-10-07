import { build } from 'esbuild';
import { mkdir, copyFile, readFile, writeFile, rm } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const web = path.dirname(fileURLToPath(import.meta.url));
const root = path.dirname(web);
const dist = path.join(web, 'dist');
const hostOnly = process.argv.includes('--host-only');
let signedPath;
if (!hostOnly) {
  // Produce a signed local artifact without publishing a public page. The CLI
  // can exit successfully without writing a file, so require its output path.
  const signed = spawnSync('rive', ['.', '--publish=local', '--quiet'], {
    cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'],
  });
  const output = signed.stdout?.trim();
  if (signed.status !== 0 || !output) {
    console.error(signed.status === 3
      ? 'Browser release needs a signed Rive file. Run rive login, then npm run build again.'
      : `Rive did not produce a signed game file.${signed.error ? ` ${signed.error.message}` : ''}`);
    process.exit(signed.status || 1);
  }
  signedPath = path.resolve(root, output);
}
await mkdir(dist, { recursive: true });
await build({ entryPoints: [path.join(web, 'game.mjs')], bundle: true, minify: true,
  format: 'esm', target: 'es2022', outfile: path.join(dist, 'game.js') });
const fontPath = path.join(root, 'assets/fonts/noto-sans-tc-700.woff2');
const jpFontPath = path.join(root, 'assets/fonts/noto-sans-jp-700.woff2');
// Inline the early gesture guard so every host (including the copied release)
// protects its loading screen without requiring another deployed asset.
const mobileJS = await readFile(path.join(web, 'mobile.js'), 'utf8');
const mobileCSS = await readFile(path.join(web, 'mobile.css'), 'utf8');
const releaseHash = createHash('sha256');
releaseHash.update(mobileJS);
releaseHash.update(mobileCSS);
releaseHash.update(await readFile(jpFontPath));
releaseHash.update(await readFile(path.join(dist, 'game.js')));
releaseHash.update(await readFile(fontPath));
if (signedPath) releaseHash.update(await readFile(signedPath));
const releaseVersion = releaseHash.digest('hex').slice(0, 12);
const index = (await readFile(path.join(web, 'index.html'), 'utf8'))
  .replace('<!-- MOBILE_GESTURES -->', `<style>${mobileCSS}</style>\n<script>${mobileJS}</script>`)
  .replace('./game.js', `./game.js?v=${releaseVersion}`)
  .replace('./noto-sans-jp.woff2', `./noto-sans-jp.woff2?v=${releaseVersion}`)
  .replace('./noto-sans-tc.woff2', `./noto-sans-tc.woff2?v=${releaseVersion}`);
await Promise.all([
  writeFile(path.join(dist, 'index.html'), index),
  copyFile(path.join(web, 'node_modules/@rive-app/webgl2/rive.wasm'), path.join(dist, 'rive.wasm')),
  copyFile(fontPath, path.join(dist, 'noto-sans-tc.woff2')),
  copyFile(jpFontPath, path.join(dist, 'noto-sans-jp.woff2')),
]);
if (hostOnly) {
  await rm(path.join(dist, 'game.riv'), { force: true });
  console.log('Browser host compiled. No playable .riv included; native Rive remains the preview.');
} else {
  await copyFile(signedPath, path.join(dist, 'game.riv'));
  console.log('Signed browser release ready in web/dist. Serve from a stable HTTPS origin to retain localStorage.');
}
